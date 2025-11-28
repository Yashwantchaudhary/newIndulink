const { getDatabase } = require('../config/firebase');
const User = require('../models/User');
const PushNotificationService = require('./pushNotificationService');

class FirebaseMessageService {
    constructor() {
        this.db = getDatabase();
        this.pushService = new PushNotificationService();
        if (!this.db) {
            throw new Error('Firebase database not initialized');
        }
    }

    // Generate conversation ID (same as before for consistency)
    generateConversationId(userId1, userId2) {
        const ids = [userId1, userId2].sort();
        return `${ids[0]}_${ids[1]}`;
    }

    // Send message to Firebase Realtime Database
    async sendMessage(senderId, receiverId, content, attachments = []) {
        try {
            const conversationId = this.generateConversationId(senderId, receiverId);

            const messageData = {
                senderId,
                receiverId,
                content,
                attachments,
                isRead: false,
                createdAt: new Date().toISOString(),
                conversationId,
            };

            // Create message reference
            const messageRef = this.db.ref(`messages/${conversationId}`).push();
            await messageRef.set(messageData);

            // Update conversation metadata
            await this.updateConversationMetadata(conversationId, senderId, receiverId, messageData);

            const messageResult = {
                id: messageRef.key,
                ...messageData,
            };

            // Send push notification to receiver (if they're offline)
            try {
                await this.pushService.sendMessageNotification(
                    senderId,
                    receiverId,
                    messageResult,
                    conversationId
                );
            } catch (notificationError) {
                console.error('Failed to send push notification:', notificationError);
                // Don't fail the message sending if notification fails
            }

            return messageResult;
        } catch (error) {
            console.error('Error sending message to Firebase:', error);
            throw error;
        }
    }

    // Update conversation metadata
    async updateConversationMetadata(conversationId, senderId, receiverId, lastMessage) {
        try {
            const conversationRef = this.db.ref(`conversations/${conversationId}`);

            // Get current conversation data
            const snapshot = await conversationRef.once('value');
            const existingData = snapshot.val() || {};

            const updateData = {
                participants: [senderId, receiverId],
                lastMessage: {
                    text: lastMessage.content,
                    senderId: lastMessage.senderId,
                    timestamp: lastMessage.createdAt,
                },
                updatedAt: lastMessage.createdAt,
                createdAt: existingData.createdAt || lastMessage.createdAt,
            };

            await conversationRef.set(updateData);
        } catch (error) {
            console.error('Error updating conversation metadata:', error);
            throw error;
        }
    }

    // Get conversations for user
    async getConversations(userId) {
        try {
            const conversationsRef = this.db.ref('conversations');
            const snapshot = await conversationsRef.once('value');
            const conversations = snapshot.val() || {};

            const userConversations = [];

            for (const [conversationId, conversationData] of Object.entries(conversations)) {
                if (conversationData.participants && conversationData.participants.includes(userId)) {
                    // Get unread count for this user
                    const unreadCount = await this.getUnreadCount(conversationId, userId);

                    userConversations.push({
                        _id: conversationId,
                        participants: conversationData.participants,
                        lastMessage: conversationData.lastMessage,
                        unreadCount: { count: unreadCount },
                        createdAt: conversationData.createdAt,
                        updatedAt: conversationData.updatedAt,
                    });
                }
            }

            // Sort by last message timestamp
            userConversations.sort((a, b) => {
                const aTime = a.lastMessage ? new Date(a.lastMessage.timestamp) : new Date(a.createdAt);
                const bTime = b.lastMessage ? new Date(b.lastMessage.timestamp) : new Date(b.createdAt);
                return bTime - aTime;
            });

            return userConversations;
        } catch (error) {
            console.error('Error getting conversations from Firebase:', error);
            throw error;
        }
    }

    // Get messages in conversation
    async getMessages(conversationId, page = 1, limit = 50) {
        try {
            const messagesRef = this.db.ref(`messages/${conversationId}`);
            const snapshot = await messagesRef.once('value');
            const messages = snapshot.val() || {};

            // Convert to array and sort by createdAt
            const messagesArray = Object.entries(messages).map(([id, data]) => ({
                _id: id,
                ...data,
            }));

            messagesArray.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));

            // Pagination
            const total = messagesArray.length;
            const startIndex = (page - 1) * limit;
            const endIndex = startIndex + limit;
            const paginatedMessages = messagesArray.slice(startIndex, endIndex);

            return {
                messages: paginatedMessages,
                pagination: {
                    page,
                    limit,
                    total,
                    pages: Math.ceil(total / limit),
                },
            };
        } catch (error) {
            console.error('Error getting messages from Firebase:', error);
            throw error;
        }
    }

    // Mark messages as read
    async markAsRead(conversationId, userId) {
        try {
            const messagesRef = this.db.ref(`messages/${conversationId}`);
            const snapshot = await messagesRef.once('value');
            const messages = snapshot.val() || {};

            const updates = {};

            for (const [messageId, messageData] of Object.entries(messages)) {
                if (messageData.receiverId === userId && !messageData.isRead) {
                    updates[`messages/${conversationId}/${messageId}/isRead`] = true;
                    updates[`messages/${conversationId}/${messageId}/readAt`] = new Date().toISOString();
                }
            }

            if (Object.keys(updates).length > 0) {
                await this.db.ref().update(updates);
            }
        } catch (error) {
            console.error('Error marking messages as read:', error);
            throw error;
        }
    }

    // Get unread count for conversation
    async getUnreadCount(conversationId, userId) {
        try {
            const messagesRef = this.db.ref(`messages/${conversationId}`);
            const snapshot = await messagesRef.once('value');
            const messages = snapshot.val() || {};

            let count = 0;
            for (const messageData of Object.values(messages)) {
                if (messageData.receiverId === userId && !messageData.isRead) {
                    count++;
                }
            }

            return count;
        } catch (error) {
            console.error('Error getting unread count:', error);
            return 0;
        }
    }

    // Validate message recipients (ensure they exist and have correct roles)
    async validateMessage(senderId, receiverId) {
        try {
            const [sender, receiver] = await Promise.all([
                User.findById(senderId),
                User.findById(receiverId),
            ]);

            if (!sender || !receiver) {
                throw new Error('Sender or receiver not found');
            }

            // Check roles - customers can only message suppliers and vice versa
            if (
                (sender.role === 'customer' && receiver.role !== 'supplier') ||
                (sender.role === 'supplier' && receiver.role !== 'customer')
            ) {
                throw new Error('Invalid recipient');
            }

            return { sender, receiver };
        } catch (error) {
            console.error('Error validating message:', error);
            throw error;
        }
    }

    // Delete message
    async deleteMessage(conversationId, messageId) {
        try {
            await this.db.ref(`messages/${conversationId}/${messageId}`).remove();
        } catch (error) {
            console.error('Error deleting message:', error);
            throw error;
        }
    }

    // Typing indicators
    async setTypingStatus(conversationId, userId, isTyping) {
        try {
            const typingRef = this.db.ref(`typing/${conversationId}/${userId}`);
            if (isTyping) {
                await typingRef.set({
                    userId: userId,
                    timestamp: new Date().toISOString(),
                });
                // Auto-clear typing status after 3 seconds
                setTimeout(() => {
                    this.clearTypingStatus(conversationId, userId);
                }, 3000);
            } else {
                await this.clearTypingStatus(conversationId, userId);
            }
        } catch (error) {
            console.error('Error setting typing status:', error);
            throw error;
        }
    }

    async clearTypingStatus(conversationId, userId) {
        try {
            await this.db.ref(`typing/${conversationId}/${userId}`).remove();
        } catch (error) {
            console.error('Error clearing typing status:', error);
        }
    }

    // Listen to typing indicators
    listenToTypingStatus(conversationId) {
        const typingRef = this.db.ref(`typing/${conversationId}`);
        return typingRef.onValue.map((event) => {
            if (!event.snapshot.exists) return [];

            const typingData = event.snapshot.val() || {};
            const typingUsers = [];

            for (const [userId, typingInfo] of Object.entries(typingData)) {
                typingUsers.push({
                    userId: userId,
                    timestamp: typingInfo.timestamp,
                });
            }

            return typingUsers;
        });
    }

    // Message reactions
    async addReaction(conversationId, messageId, userId, emoji) {
        try {
            const reactionRef = this.db.ref(`reactions/${conversationId}/${messageId}/${userId}`);
            await reactionRef.set({
                emoji: emoji,
                userId: userId,
                timestamp: new Date().toISOString(),
            });
        } catch (error) {
            console.error('Error adding reaction:', error);
            throw error;
        }
    }

    async removeReaction(conversationId, messageId, userId) {
        try {
            const reactionRef = this.db.ref(`reactions/${conversationId}/${messageId}/${userId}`);
            await reactionRef.remove();
        } catch (error) {
            console.error('Error removing reaction:', error);
            throw error;
        }
    }

    // Get reactions for a message
    async getMessageReactions(conversationId, messageId) {
        try {
            const reactionsRef = this.db.ref(`reactions/${conversationId}/${messageId}`);
            const snapshot = await reactionsRef.once('value');
            const reactions = snapshot.val() || {};

            const reactionCounts = {};
            const userReactions = {};

            for (const [userId, reactionData] of Object.entries(reactions)) {
                const emoji = reactionData.emoji;
                if (!reactionCounts[emoji]) {
                    reactionCounts[emoji] = 0;
                }
                reactionCounts[emoji]++;
                userReactions[userId] = emoji;
            }

            return {
                counts: reactionCounts,
                userReactions: userReactions,
            };
        } catch (error) {
            console.error('Error getting message reactions:', error);
            return { counts: {}, userReactions: {} };
        }
    }

    // Listen to reactions for a conversation
    listenToReactions(conversationId) {
        const reactionsRef = this.db.ref(`reactions/${conversationId}`);
        return reactionsRef.onValue.map((event) => {
            if (!event.snapshot.exists) return {};

            const reactionsData = event.snapshot.val() || {};
            const messageReactions = {};

            for (const [messageId, messageReactionsData] of Object.entries(reactionsData)) {
                const reactionCounts = {};
                const userReactions = {};

                for (const [userId, reactionData] of Object.entries(messageReactionsData)) {
                    const emoji = reactionData.emoji;
                    if (!reactionCounts[emoji]) {
                        reactionCounts[emoji] = 0;
                    }
                    reactionCounts[emoji]++;
                    userReactions[userId] = emoji;
                }

                messageReactions[messageId] = {
                    counts: reactionCounts,
                    userReactions: userReactions,
                };
            }

            return messageReactions;
        });
    }
}

module.exports = FirebaseMessageService;