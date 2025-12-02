const User = require('../models/User');
const Message = require('../models/Message');
const { createAndSendNotification } = require('../services/notificationService');

// @desc    Get conversations
// @route   GET /api/messages/conversations
// @access  Private
exports.getConversations = async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        // Get all conversations for the user
        const conversations = await Message.aggregate([
            {
                $match: {
                    $or: [
                        { sender: req.user._id },
                        { receiver: req.user._id }
                    ]
                }
            },
            {
                $sort: { createdAt: -1 }
            },
            {
                $group: {
                    _id: '$conversationId',
                    lastMessage: { $first: '$$ROOT' },
                    messageCount: { $sum: 1 },
                    unreadCount: {
                        $sum: {
                            $cond: [
                                {
                                    $and: [
                                        { $eq: ['$receiver', req.user._id] },
                                        { $eq: ['$isRead', false] }
                                    ]
                                },
                                1,
                                0
                            ]
                        }
                    }
                }
            },
            {
                $sort: { 'lastMessage.createdAt': -1 }
            },
            {
                $skip: skip
            },
            {
                $limit: limit
            }
        ]);

        // Populate user details for each conversation
        const populatedConversations = await Promise.all(
            conversations.map(async (conversation) => {
                const otherUserId = conversation.lastMessage.sender.toString() === req.user._id.toString()
                    ? conversation.lastMessage.receiver
                    : conversation.lastMessage.sender;

                const otherUser = await User.findById(otherUserId)
                    .select('firstName lastName profileImage businessName role')
                    .lean();

                return {
                    conversationId: conversation._id,
                    otherUser,
                    lastMessage: {
                        id: conversation.lastMessage._id,
                        content: conversation.lastMessage.content,
                        createdAt: conversation.lastMessage.createdAt,
                        isRead: conversation.lastMessage.isRead,
                        attachments: conversation.lastMessage.attachments,
                    },
                    messageCount: conversation.messageCount,
                    unreadCount: conversation.unreadCount,
                };
            })
        );

        res.status(200).json({
            success: true,
            count: populatedConversations.length,
            page,
            pages: Math.ceil(conversations.length / limit), // This is approximate
            data: populatedConversations,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get messages in conversation
// @route   GET /api/messages/conversation/:userId
// @access  Private
exports.getMessages = async (req, res, next) => {
    try {
        const otherUserId = req.params.userId;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 50;
        const skip = (page - 1) * limit;

        // Generate conversation ID
        const ids = [req.user._id.toString(), otherUserId].sort();
        const conversationId = `${ids[0]}_${ids[1]}`;

        // Get messages for this conversation
        const messages = await Message.find({ conversationId })
            .populate('sender', 'firstName lastName profileImage businessName role')
            .populate('receiver', 'firstName lastName profileImage businessName role')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit)
            .lean();

        const total = await Message.countDocuments({ conversationId });

        // Mark messages as read (only messages received by current user)
        await Message.updateMany(
            {
                conversationId,
                receiver: req.user._id,
                isRead: false
            },
            {
                isRead: true,
                readAt: new Date()
            }
        );

        // Reverse to show chronological order (oldest first)
        const reversedMessages = messages.reverse();

        res.status(200).json({
            success: true,
            count: reversedMessages.length,
            total,
            page,
            pages: Math.ceil(total / limit),
            data: reversedMessages,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Send message
// @route   POST /api/messages
// @access  Private
exports.sendMessage = async (req, res, next) => {
    try {
        const { receiver, content, attachments } = req.body;

        // Validate required fields
        if (!receiver || (!content && (!attachments || attachments.length === 0))) {
            return res.status(400).json({
                success: false,
                message: 'Message must have content or attachments',
            });
        }

        // Validate receiver exists
        const receiverUser = await User.findById(receiver);
        if (!receiverUser) {
            return res.status(404).json({
                success: false,
                message: 'Receiver not found',
            });
        }

        // Create message
        const message = await Message.create({
            sender: req.user._id,
            receiver: receiver,
            content: content || '',
            attachments: attachments || [],
        });

        // Populate user details
        const populatedMessage = await Message.findById(message._id)
            .populate('sender', 'firstName lastName profileImage businessName role')
            .populate('receiver', 'firstName lastName profileImage businessName role');

        // Send push notification to receiver
        try {
            const notificationMessage = content
                ? (content.length > 50 ? content.substring(0, 50) + '...' : content)
                : '📎 New attachment';

            await createAndSendNotification({
                userId: receiver,
                title: `${req.user.firstName} ${req.user.lastName}`,
                message: notificationMessage,
                type: 'message',
                data: {
                    senderId: req.user._id.toString(),
                    conversationId: message.conversationId,
                    messageId: message._id.toString(),
                },
                sendPush: true,
            });
        } catch (notificationError) {
            console.error('Failed to send message notification:', notificationError);
            // Don't fail the message send if notification fails
        }

        res.status(201).json({
            success: true,
            message: 'Message sent successfully',
            data: populatedMessage,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Mark messages as read
// @route   PUT /api/messages/read/:conversationId
// @access  Private
exports.markAsRead = async (req, res, next) => {
    try {
        const { conversationId } = req.params;

        // Mark all unread messages in this conversation as read for current user
        const result = await Message.updateMany(
            {
                conversationId,
                receiver: req.user._id,
                isRead: false
            },
            {
                isRead: true,
                readAt: new Date()
            }
        );

        res.status(200).json({
            success: true,
            message: `${result.modifiedCount} messages marked as read`,
            data: { modifiedCount: result.modifiedCount },
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Search conversations
// @route   GET /api/messages/conversations/search
// @access  Private
exports.searchConversations = async (req, res, next) => {
    try {
        const { query } = req.query;
        if (!query) {
            return res.status(400).json({
                success: false,
                message: 'Search query is required',
            });
        }

        const firebaseService = new FirebaseMessageService();
        const conversations = await firebaseService.getConversations(req.user.id);

        // Filter conversations based on search query
        // For now, we'll search in user names from MongoDB
        const filteredConversations = await Promise.all(
            conversations.map(async (conversation) => {
                // Get other participant
                const otherParticipantId = conversation.participants.find(p => p !== req.user.id);
                if (!otherParticipantId) return null;

                const otherUser = await User.findById(otherParticipantId)
                    .select('firstName lastName businessName')
                    .lean();

                if (!otherUser) return null;

                const searchString = `${otherUser.firstName} ${otherUser.lastName} ${otherUser.businessName || ''}`.toLowerCase();
                if (searchString.includes(query.toLowerCase())) {
                    return {
                        ...conversation,
                        otherUser,
                    };
                }
                return null;
            })
        );

        const validConversations = filteredConversations.filter(conv => conv !== null);

        res.status(200).json({
            success: true,
            count: validConversations.length,
            data: validConversations,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Delete message
// @route   DELETE /api/messages/:messageId
// @access  Private
exports.deleteMessage = async (req, res, next) => {
    try {
        const { messageId } = req.params;
        const firebaseService = new FirebaseMessageService();

        // For now, we'll need to find the conversation ID from the message
        // This is a limitation of Firebase Realtime Database - we might need to store message metadata
        // For simplicity, we'll implement a basic delete that requires conversationId in query
        const conversationId = req.query.conversationId;

        if (!conversationId) {
            return res.status(400).json({
                success: false,
                message: 'Conversation ID required for message deletion',
            });
        }

        await firebaseService.deleteMessage(conversationId, messageId);

        res.status(200).json({
            success: true,
            message: 'Message deleted',
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get unread message count
// @route   GET /api/messages/unread/count
// @access  Private
exports.getUnreadCount = async (req, res, next) => {
    try {
        const unreadCount = await Message.countDocuments({
            receiver: req.user._id,
            isRead: false
        });

        res.status(200).json({
            success: true,
            data: { unreadCount },
        });
    } catch (error) {
        next(error);
    }
};
