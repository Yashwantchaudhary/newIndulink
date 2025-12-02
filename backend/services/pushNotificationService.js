/// 🔔 Push Notification Service
/// Advanced push notification system for INDULINK platform

const admin = require('firebase-admin');
const User = require('../models/User');
const Notification = require('../models/Notification');

class PushNotificationService {
    constructor() {
        this.initialized = false;
        this.initFirebase();
    }

    // Initialize Firebase Admin SDK
    initFirebase() {
        try {
            // Check if Firebase is already initialized
            if (!admin.apps.length) {
                // Initialize with service account credentials
                // In production, use environment variables or service account file
                const serviceAccount = {
                    type: "service_account",
                    project_id: process.env.FIREBASE_PROJECT_ID || "indulink-app",
                    private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
                    private_key: (process.env.FIREBASE_PRIVATE_KEY || "").replace(/\\n/g, '\n'),
                    client_email: process.env.FIREBASE_CLIENT_EMAIL,
                    client_id: process.env.FIREBASE_CLIENT_ID,
                    auth_uri: "https://accounts.google.com/o/oauth2/auth",
                    token_uri: "https://oauth2.googleapis.com/token",
                    auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
                    client_x509_cert_url: process.env.FIREBASE_CLIENT_CERT_URL
                };

                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount),
                    projectId: process.env.FIREBASE_PROJECT_ID || "indulink-app"
                });
            }

            this.initialized = true;
            console.log('✅ Firebase Admin SDK initialized successfully');
        } catch (error) {
            console.error('❌ Failed to initialize Firebase Admin SDK:', error);
            this.initialized = false;
        }
    }

    // Send push notification to a single device
    async sendToDevice(token, payload) {
        if (!this.initialized) {
            throw new Error('Firebase not initialized');
        }

        try {
            const message = {
                token: token,
                notification: {
                    title: payload.title,
                    body: payload.body,
                },
                data: payload.data || {},
                android: {
                    priority: payload.priority || 'high',
                    notification: {
                        sound: payload.sound || 'default',
                        clickAction: payload.clickAction || 'FLUTTER_NOTIFICATION_CLICK',
                        channelId: payload.channelId || 'default_channel',
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: payload.sound || 'default',
                            badge: payload.badge || 1,
                        },
                    },
                },
            };

            const response = await admin.messaging().send(message);
            console.log('✅ Push notification sent successfully:', response);
            return response;
        } catch (error) {
            console.error('❌ Failed to send push notification:', error);
            throw error;
        }
    }

    // Send push notification to multiple devices
    async sendToMultipleDevices(tokens, payload) {
        if (!this.initialized) {
            throw new Error('Firebase not initialized');
        }

        try {
            const message = {
                tokens: tokens,
                notification: {
                    title: payload.title,
                    body: payload.body,
                },
                data: payload.data || {},
                android: {
                    priority: payload.priority || 'high',
                    notification: {
                        sound: payload.sound || 'default',
                        clickAction: payload.clickAction || 'FLUTTER_NOTIFICATION_CLICK',
                        channelId: payload.channelId || 'default_channel',
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: payload.sound || 'default',
                            badge: payload.badge || 1,
                        },
                    },
                },
            };

            const response = await admin.messaging().sendMulticast(message);
            console.log(`✅ Push notification sent to ${response.successCount} devices successfully`);

            // Handle failures
            if (response.failureCount > 0) {
                console.warn(`⚠️ ${response.failureCount} push notifications failed`);
                response.responses.forEach((resp, index) => {
                    if (!resp.success) {
                        console.error(`Failed to send to token ${tokens[index]}:`, resp.error);
                    }
                });
            }

            return response;
        } catch (error) {
            console.error('❌ Failed to send multicast push notification:', error);
            throw error;
        }
    }

    // Send notification to all users with a specific role
    async sendToRole(role, payload) {
        try {
            const users = await User.find({
                role: role,
                fcmToken: { $exists: true, $ne: null }
            }).select('fcmToken');

            const tokens = users.map(user => user.fcmToken).filter(token => token);

            if (tokens.length === 0) {
                console.log(`ℹ️ No FCM tokens found for role: ${role}`);
                return { successCount: 0, failureCount: 0 };
            }

            console.log(`📤 Sending notification to ${tokens.length} ${role}s`);
            return await this.sendToMultipleDevices(tokens, payload);
        } catch (error) {
            console.error(`❌ Failed to send notification to role ${role}:`, error);
            throw error;
        }
    }

    // Send notification to specific users
    async sendToUsers(userIds, payload) {
        try {
            const users = await User.find({
                _id: { $in: userIds },
                fcmToken: { $exists: true, $ne: null }
            }).select('fcmToken');

            const tokens = users.map(user => user.fcmToken).filter(token => token);

            if (tokens.length === 0) {
                console.log(`ℹ️ No FCM tokens found for specified users`);
                return { successCount: 0, failureCount: 0 };
            }

            console.log(`📤 Sending notification to ${tokens.length} specific users`);
            return await this.sendToMultipleDevices(tokens, payload);
        } catch (error) {
            console.error('❌ Failed to send notification to specific users:', error);
            throw error;
        }
    }

    // Send notification to all users
    async sendToAll(payload) {
        try {
            const users = await User.find({
                fcmToken: { $exists: true, $ne: null }
            }).select('fcmToken');

            const tokens = users.map(user => user.fcmToken).filter(token => token);

            if (tokens.length === 0) {
                console.log('ℹ️ No FCM tokens found for any users');
                return { successCount: 0, failureCount: 0 };
            }

            console.log(`📤 Sending notification to all ${tokens.length} users`);
            return await this.sendToMultipleDevices(tokens, payload);
        } catch (error) {
            console.error('❌ Failed to send notification to all users:', error);
            throw error;
        }
    }

    // ==================== NOTIFICATION TEMPLATES ====================

    // Order status update notification
    async sendOrderStatusUpdate(orderId, userId, status, orderNumber) {
        const payload = {
            title: 'Order Status Updated',
            body: `Your order #${orderNumber} status has been updated to ${status}`,
            data: {
                type: 'order_status',
                orderId: orderId.toString(),
                status: status,
                orderNumber: orderNumber.toString(),
            },
            sound: 'default',
            channelId: 'orders',
        };

        return await this.sendToUsers([userId], payload);
    }

    // New message notification
    async sendNewMessage(conversationId, recipientId, senderName, message) {
        const payload = {
            title: 'New Message',
            body: `${senderName}: ${message.length > 50 ? message.substring(0, 50) + '...' : message}`,
            data: {
                type: 'new_message',
                conversationId: conversationId.toString(),
                senderName: senderName,
            },
            sound: 'message',
            channelId: 'messages',
        };

        return await this.sendToUsers([recipientId], payload);
    }

    // Product back in stock notification
    async sendProductBackInStock(productId, productName, userIds) {
        const payload = {
            title: 'Product Back in Stock!',
            body: `${productName} is now available for purchase`,
            data: {
                type: 'product_available',
                productId: productId.toString(),
                productName: productName,
            },
            sound: 'default',
            channelId: 'products',
        };

        return await this.sendToUsers(userIds, payload);
    }

    // RFQ response notification
    async sendRFQResponse(rfqId, customerId, supplierName) {
        const payload = {
            title: 'RFQ Response Received',
            body: `${supplierName} has responded to your quote request`,
            data: {
                type: 'rfq_response',
                rfqId: rfqId.toString(),
                supplierName: supplierName,
            },
            sound: 'default',
            channelId: 'rfq',
        };

        return await this.sendToUsers([customerId], payload);
    }

    // Promotion/special offer notification
    async sendPromotion(title, body, targetUsers = null, targetRole = null) {
        const payload = {
            title: title,
            body: body,
            data: {
                type: 'promotion',
                promotionId: Date.now().toString(), // Generate unique ID
            },
            sound: 'promotion',
            channelId: 'promotions',
        };

        if (targetUsers) {
            return await this.sendToUsers(targetUsers, payload);
        } else if (targetRole) {
            return await this.sendToRole(targetRole, payload);
        } else {
            return await this.sendToAll(payload);
        }
    }

    // System maintenance notification
    async sendMaintenanceNotification(startTime, endTime) {
        const payload = {
            title: 'Scheduled Maintenance',
            body: `System maintenance from ${startTime} to ${endTime}. Some features may be unavailable.`,
            data: {
                type: 'maintenance',
                startTime: startTime,
                endTime: endTime,
            },
            sound: 'default',
            channelId: 'system',
        };

        return await this.sendToAll(payload);
    }

    // ==================== SCHEDULED NOTIFICATIONS ====================

    // Schedule a notification for future delivery
    async scheduleNotification(payload, scheduledTime, targetUsers = null, targetRole = null) {
        try {
            const scheduledNotification = {
                title: payload.title,
                body: payload.body,
                data: payload.data || {},
                scheduledTime: new Date(scheduledTime),
                targetUsers: targetUsers,
                targetRole: targetRole,
                status: 'scheduled',
                createdAt: new Date(),
            };

            // Store in database for processing by a scheduler
            // In a real implementation, you'd use a job queue like Bull or Agenda
            const notification = new Notification(scheduledNotification);
            await notification.save();

            console.log(`📅 Notification scheduled for ${scheduledTime}`);
            return notification;
        } catch (error) {
            console.error('❌ Failed to schedule notification:', error);
            throw error;
        }
    }

    // Process scheduled notifications (to be called by a cron job)
    async processScheduledNotifications() {
        try {
            const now = new Date();
            const scheduledNotifications = await Notification.find({
                status: 'scheduled',
                scheduledTime: { $lte: now }
            });

            for (const notification of scheduledNotifications) {
                try {
                    const payload = {
                        title: notification.title,
                        body: notification.body,
                        data: notification.data,
                        sound: notification.data.sound || 'default',
                        channelId: notification.data.channelId || 'default_channel',
                    };

                    let result;
                    if (notification.targetUsers && notification.targetUsers.length > 0) {
                        result = await this.sendToUsers(notification.targetUsers, payload);
                    } else if (notification.targetRole) {
                        result = await this.sendToRole(notification.targetRole, payload);
                    } else {
                        result = await this.sendToAll(payload);
                    }

                    // Update notification status
                    await Notification.findByIdAndUpdate(notification._id, {
                        status: 'sent',
                        sentAt: new Date(),
                        deliveryStats: result
                    });

                    console.log(`✅ Scheduled notification sent: ${notification.title}`);
                } catch (error) {
                    console.error(`❌ Failed to send scheduled notification ${notification._id}:`, error);

                    // Update notification status to failed
                    await Notification.findByIdAndUpdate(notification._id, {
                        status: 'failed',
                        error: error.message
                    });
                }
            }

            return { processed: scheduledNotifications.length };
        } catch (error) {
            console.error('❌ Failed to process scheduled notifications:', error);
            throw error;
        }
    }

    // ==================== UTILITY METHODS ====================

    // Validate FCM token
    async validateToken(token) {
        if (!this.initialized) return false;

        try {
            // Send a test message with dry run
            await admin.messaging().send({
                token: token,
                notification: {
                    title: 'Test',
                    body: 'Test'
                }
            }, true); // dryRun = true

            return true;
        } catch (error) {
            console.warn('Invalid FCM token:', error.message);
            return false;
        }
    }

    // Clean up invalid tokens
    async cleanupInvalidTokens() {
        try {
            const users = await User.find({
                fcmToken: { $exists: true, $ne: null }
            }).select('_id fcmToken');

            let cleanedCount = 0;

            for (const user of users) {
                const isValid = await this.validateToken(user.fcmToken);
                if (!isValid) {
                    await User.findByIdAndUpdate(user._id, {
                        $unset: { fcmToken: 1 }
                    });
                    cleanedCount++;
                }
            }

            console.log(`🧹 Cleaned up ${cleanedCount} invalid FCM tokens`);
            return { cleaned: cleanedCount };
        } catch (error) {
            console.error('❌ Failed to cleanup invalid tokens:', error);
            throw error;
        }
    }

    // Get notification statistics
    async getNotificationStats(timeframe = '30d') {
        const startDate = this.getStartDate(timeframe);

        try {
            const stats = await Notification.aggregate([
                { $match: { createdAt: { $gte: startDate } } },
                {
                    $group: {
                        _id: '$status',
                        count: { $sum: 1 }
                    }
                }
            ]);

            const result = {
                total: 0,
                sent: 0,
                scheduled: 0,
                failed: 0,
                timeframe
            };

            stats.forEach(stat => {
                result[stat._id] = stat.count;
                result.total += stat.count;
            });

            return result;
        } catch (error) {
            console.error('❌ Failed to get notification stats:', error);
            throw error;
        }
    }

    // Helper method to get start date
    getStartDate(timeframe) {
        const now = new Date();
        const units = {
            '1h': 1 * 60 * 60 * 1000,
            '24h': 24 * 60 * 60 * 1000,
            '7d': 7 * 24 * 60 * 60 * 1000,
            '30d': 30 * 24 * 60 * 60 * 1000,
            '90d': 90 * 24 * 60 * 60 * 1000,
            '1y': 365 * 24 * 60 * 60 * 1000
        };

        return new Date(now.getTime() - (units[timeframe] || units['30d']));
    }
}

module.exports = new PushNotificationService();
