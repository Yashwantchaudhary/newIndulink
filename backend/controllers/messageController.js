const User = require('../models/User');
const FirebaseMessageService = require('../services/firebaseMessageService');

// @desc    Get conversations
// @route   GET /api/messages/conversations
// @access  Private
exports.getConversations = async (req, res, next) => {
    try {
        const firebaseService = new FirebaseMessageService();
        const conversations = await firebaseService.getConversations(req.user.id);

        // Populate user details for each conversation
        const populatedConversations = await Promise.all(
            conversations.map(async (conversation) => {
                if (conversation.lastMessage) {
                    const [sender, receiver] = await Promise.all([
                        User.findById(conversation.lastMessage.senderId).select('firstName lastName profileImage businessName role'),
                        User.findById(conversation.participants.find(p => p !== conversation.lastMessage.senderId)).select('firstName lastName profileImage businessName role'),
                    ]);

                    return {
                        ...conversation,
                        lastMessage: {
                            ...conversation.lastMessage,
                            sender,
                            receiver,
                        },
                    };
                }
                return conversation;
            })
        );

        res.status(200).json({
            success: true,
            count: populatedConversations.length,
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

        // Generate conversation ID
        const firebaseService = new FirebaseMessageService();
        const ids = [req.user.id, otherUserId].sort();
        const conversationId = `${ids[0]}_${ids[1]}`;

        const result = await firebaseService.getMessages(conversationId, page, limit);

        // Populate user details
        const populatedMessages = await Promise.all(
            result.messages.map(async (message) => {
                const [sender, receiver] = await Promise.all([
                    User.findById(message.senderId).select('firstName lastName profileImage businessName role'),
                    User.findById(message.receiverId).select('firstName lastName profileImage businessName role'),
                ]);

                return {
                    ...message,
                    sender,
                    receiver,
                };
            })
        );

        // Mark messages as read
        await firebaseService.markAsRead(conversationId, req.user.id);

        res.status(200).json({
            success: true,
            count: populatedMessages.length,
            total: result.pagination.total,
            page: result.pagination.page,
            pages: result.pagination.pages,
            data: populatedMessages,
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
        const { receiver, content } = req.body;
        const firebaseService = new FirebaseMessageService();

        // Validate message recipients
        await firebaseService.validateMessage(req.user.id, receiver);

        const message = await firebaseService.sendMessage(req.user.id, receiver, content);

        // Populate user details
        const [sender, receiverUser] = await Promise.all([
            User.findById(message.senderId).select('firstName lastName profileImage businessName role'),
            User.findById(message.receiverId).select('firstName lastName profileImage businessName role'),
        ]);

        const populatedMessage = {
            ...message,
            sender,
            receiver: receiverUser,
        };

        res.status(201).json({
            success: true,
            message: 'Message sent',
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
        const firebaseService = new FirebaseMessageService();
        await firebaseService.markAsRead(req.params.conversationId, req.user.id);

        res.status(200).json({
            success: true,
            message: 'Messages marked as read',
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
        const firebaseService = new FirebaseMessageService();
        const conversations = await firebaseService.getConversations(req.user.id);

        const totalUnread = conversations.reduce((sum, conv) => {
            return sum + (conv.unreadCount?.count ?? 0);
        }, 0);

        res.status(200).json({
            success: true,
            data: { unreadCount: totalUnread },
        });
    } catch (error) {
        next(error);
    }
};
