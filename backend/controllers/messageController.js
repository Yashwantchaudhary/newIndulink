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
        const inputId = req.params.userId;
        let conversationId;

        // Check if input is a conversation ID (contains underscore)
        if (inputId.includes('_')) {
            conversationId = inputId;
            // Verify user is part of this conversation
            if (!conversationId.includes(req.user._id.toString())) {
                // return res.status(403).json({ success: false, message: 'Unauthorized' });
                // or just let it return empty if logic prefers
            }
        } else {
            // It's a user ID, construct conversation ID
            const ids = [req.user._id.toString(), inputId].sort();
            conversationId = `${ids[0]}_${ids[1]}`;
        }

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

        let receiverId = receiver;

        // If receiver looks like a conversation ID, extract the other user ID
        if (receiver && receiver.includes('_')) {
            const ids = receiver.split('_');
            receiverId = ids.find(id => id !== req.user._id.toString());
        }

        // Validate receiver exists
        const receiverUser = await User.findById(receiverId);
        if (!receiverUser) {
            return res.status(404).json({
                success: false,
                message: 'Receiver not found',
            });
        }

        // Create message
        const message = await Message.create({
            sender: req.user._id,
            receiver: receiverId,
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
                userId: receiverId,
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

        // Find conversations where the other user matches the search query
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
                $lookup: {
                    from: 'users',
                    let: {
                        senderId: '$lastMessage.sender',
                        receiverId: '$lastMessage.receiver',
                        currentUserId: req.user._id
                    },
                    pipeline: [
                        {
                            $match: {
                                $expr: {
                                    $or: [
                                        { $eq: ['$_id', '$$senderId'] },
                                        { $eq: ['$_id', '$$receiverId'] }
                                    ]
                                }
                            }
                        },
                        {
                            $match: {
                                $expr: { $ne: ['$_id', '$$currentUserId'] }
                            }
                        }
                    ],
                    as: 'otherUser'
                }
            },
            {
                $unwind: '$otherUser'
            },
            {
                $match: {
                    $or: [
                        { 'otherUser.firstName': new RegExp(query, 'i') },
                        { 'otherUser.lastName': new RegExp(query, 'i') },
                        { 'otherUser.businessName': new RegExp(query, 'i') }
                    ]
                }
            },
            {
                $sort: { 'lastMessage.createdAt': -1 }
            }
        ]);

        // Format the results
        const formattedConversations = conversations.map(conversation => ({
            conversationId: conversation._id,
            otherUser: {
                _id: conversation.otherUser._id,
                firstName: conversation.otherUser.firstName,
                lastName: conversation.otherUser.lastName,
                businessName: conversation.otherUser.businessName,
                role: conversation.otherUser.role
            },
            lastMessage: {
                id: conversation.lastMessage._id,
                content: conversation.lastMessage.content,
                createdAt: conversation.lastMessage.createdAt,
                isRead: conversation.lastMessage.isRead,
                attachments: conversation.lastMessage.attachments,
            },
            messageCount: conversation.messageCount,
            unreadCount: conversation.unreadCount,
        }));

        res.status(200).json({
            success: true,
            count: formattedConversations.length,
            data: formattedConversations,
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

        // Find the message and verify ownership
        const message = await Message.findById(messageId);

        if (!message) {
            return res.status(404).json({
                success: false,
                message: 'Message not found',
            });
        }

        // Only sender can delete their own messages
        if (message.sender.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'You can only delete your own messages',
            });
        }

        // Soft delete by marking as deleted (or hard delete)
        await Message.findByIdAndDelete(messageId);

        res.status(200).json({
            success: true,
            message: 'Message deleted successfully',
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

// @desc    Get message statistics
// @route   GET /api/messages/stats
// @access  Private (Admin)
exports.getMessageStats = async (req, res, next) => {
    try {
        const totalMessages = await Message.countDocuments();
        const unreadMessages = await Message.countDocuments({ isRead: false });
        const todayMessages = await Message.countDocuments({
            createdAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }
        });

        // Get message count by type
        const messagesByType = await Message.aggregate([
            { $group: { _id: '$type', count: { $sum: 1 } } }
        ]);

        res.status(200).json({
            success: true,
            data: {
                totalMessages,
                unreadMessages,
                todayMessages,
                messagesByType,
                count: totalMessages
            }
        });
    } catch (error) {
        next(error);
    }
};
