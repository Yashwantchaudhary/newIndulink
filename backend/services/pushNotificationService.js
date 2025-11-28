const { getFCMToken } = require('../config/firebase');
const User = require('../models/User');

class PushNotificationService {
    constructor() {
        this.messaging = getFCMToken();
        if (!this.messaging) {
            console.warn('FCM messaging not initialized');
        }
    }

    // Send push notification for new message
    async sendMessageNotification(senderId, receiverId, messageData, conversationId) {
        try {
            // Get receiver's FCM tokens
            const receiver = await User.findById(receiverId).select('fcmTokens firstName lastName');
            if (!receiver || !receiver.fcmTokens || receiver.fcmTokens.length === 0) {
                console.log(`No FCM tokens found for user ${receiverId}`);
                return;
            }

            // Get sender info
            const sender = await User.findById(senderId).select('firstName lastName businessName role');
            if (!sender) {
                console.log(`Sender not found: ${senderId}`);
                return;
            }

            const senderName = sender.role === 'supplier' && sender.businessName
                ? sender.businessName
                : `${sender.firstName} ${sender.lastName}`;

            // Create notification payload
            const notification = {
                title: senderName,
                body: messageData.content.length > 100
                    ? `${messageData.content.substring(0, 100)}...`
                    : messageData.content,
            };

            const data = {
                type: 'message',
                conversationId: conversationId,
                senderId: senderId.toString(),
                senderName: senderName,
                messageId: messageData._id || messageData.id,
                timestamp: messageData.createdAt,
            };

            // Use the most recent FCM token
            const fcmToken = receiver.fcmTokens[receiver.fcmTokens.length - 1];

            const message = {
                token: fcmToken,
                notification: notification,
                data: data,
                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'messages',
                        priority: 'high',
                        defaultSound: true,
                        defaultVibrateTimings: true,
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            alert: notification,
                            badge: 1,
                            sound: 'default',
                            category: 'MESSAGE',
                        },
                    },
                },
            };

            // Send the notification
            const response = await this.messaging.send(message);
            console.log('Push notification sent successfully:', response);

            return response;
        } catch (error) {
            console.error('Error sending push notification:', error);
            throw error;
        }
    }

    // Send notification for conversation update
    async sendConversationNotification(userId, conversationData) {
        try {
            const user = await User.findById(userId).select('fcmTokens firstName lastName');
            if (!user || !user.fcmTokens || user.fcmTokens.length === 0) {
                return;
            }

            const fcmToken = user.fcmTokens[user.fcmTokens.length - 1];

            const notification = {
                title: 'New Conversation',
                body: 'You have a new conversation',
            };

            const data = {
                type: 'conversation',
                conversationId: conversationData.id,
                action: 'new_conversation',
            };

            const message = {
                token: fcmToken,
                notification: notification,
                data: data,
            };

            const response = await this.messaging.send(message);
            console.log('Conversation notification sent:', response);

            return response;
        } catch (error) {
            console.error('Error sending conversation notification:', error);
            throw error;
        }
    }

    // Update user's FCM token
    async updateUserFCMToken(userId, fcmToken) {
        try {
            // Add token to array if not already present
            await User.findByIdAndUpdate(
                userId,
                {
                    $addToSet: { fcmTokens: fcmToken },
                    updatedAt: new Date(),
                }
            );
            console.log(`FCM token added for user ${userId}`);
        } catch (error) {
            console.error('Error updating FCM token:', error);
            throw error;
        }
    }

    // Remove FCM token (logout)
    async removeUserFCMToken(userId, fcmToken = null) {
        try {
            if (fcmToken) {
                // Remove specific token
                await User.findByIdAndUpdate(userId, {
                    $pull: { fcmTokens: fcmToken },
                    updatedAt: new Date(),
                });
            } else {
                // Remove all tokens
                await User.findByIdAndUpdate(userId, {
                    fcmTokens: [],
                    updatedAt: new Date(),
                });
            }
            console.log(`FCM token(s) removed for user ${userId}`);
        } catch (error) {
            console.error('Error removing FCM token:', error);
            throw error;
        }
    }

    // Send broadcast notification to multiple users
    async sendBroadcastNotification(userIds, title, body, data = {}) {
        try {
            const users = await User.find({
                _id: { $in: userIds },
                fcmTokens: { $exists: true, $ne: [] }
            }).select('fcmTokens');

            if (users.length === 0) {
                console.log('No users with FCM tokens found');
                return;
            }

            const tokens = users.flatMap(user => user.fcmTokens).filter(token => token);

            if (tokens.length === 0) {
                console.log('No valid FCM tokens found');
                return;
            }

            const message = {
                tokens: tokens,
                notification: {
                    title: title,
                    body: body,
                },
                data: data,
            };

            const response = await this.messaging.sendMulticast(message);
            console.log('Broadcast notification sent:', response);

            return response;
        } catch (error) {
            console.error('Error sending broadcast notification:', error);
            throw error;
        }
    }

    // Check if user is online (has active FCM token)
    async isUserOnline(userId) {
        try {
            const user = await User.findById(userId).select('fcmTokens lastSeen');
            return !!(user && user.fcmTokens && user.fcmTokens.length > 0);
        } catch (error) {
            console.error('Error checking user online status:', error);
            return false;
        }
    }
}

module.exports = PushNotificationService;