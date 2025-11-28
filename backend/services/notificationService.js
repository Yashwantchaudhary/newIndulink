const { getMessaging } = require('../config/firebase');
const Notification = require('../models/Notification');
const User = require('../models/User');

/**
 * Send push notification to a single user
 * @param {string} userId - User ID to send notification to
 * @param {Object} notificationData - Notification data
 * @param {string} notificationData.title - Notification title
 * @param {string} notificationData.body - Notification body
 * @param {Object} notificationData.data - Additional data to send
 * @returns {Promise<Object>} - Result of the operation
 */
const sendPushNotification = async (userId, notificationData) => {
    try {
        const messaging = getMessaging();
        if (!messaging) {
            console.warn('Firebase messaging not initialized, skipping push notification');
            return { success: false, message: 'Firebase messaging not initialized' };
        }

        // Get user's FCM tokens
        const user = await User.findById(userId).select('fcmTokens');
        if (!user || !user.fcmTokens || user.fcmTokens.length === 0) {
            return { success: false, message: 'User has no FCM tokens' };
        }

        // Prepare the message
        const message = {
            notification: {
                title: notificationData.title,
                body: notificationData.body,
            },
            data: {
                ...notificationData.data,
                userId: userId,
                timestamp: Date.now().toString(),
            },
            tokens: user.fcmTokens, // Send to all user's devices
        };

        // Send the message
        const response = await messaging.sendMulticast(message);

        console.log(`Push notification sent to user ${userId}:`, {
            successCount: response.successCount,
            failureCount: response.failureCount,
        });

        // Clean up invalid tokens
        if (response.failureCount > 0) {
            const validTokens = [];
            response.responses.forEach((resp, index) => {
                if (resp.success) {
                    validTokens.push(user.fcmTokens[index]);
                } else {
                    console.log(`Invalid token for user ${userId}:`, resp.error);
                }
            });

            // Update user's FCM tokens
            user.fcmTokens = validTokens;
            await user.save();
        }

        return {
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount,
        };
    } catch (error) {
        console.error('Error sending push notification:', error);
        return { success: false, error: error.message };
    }
};

/**
 * Send push notification to multiple users
 * @param {Array<string>} userIds - Array of user IDs
 * @param {Object} notificationData - Notification data
 * @returns {Promise<Object>} - Result of the operation
 */
const sendPushNotificationToUsers = async (userIds, notificationData) => {
    try {
        const messaging = getMessaging();
        if (!messaging) {
            console.warn('Firebase messaging not initialized, skipping push notifications');
            return { success: false, message: 'Firebase messaging not initialized' };
        }

        // Get FCM tokens for all users
        const users = await User.find({ _id: { $in: userIds } }).select('fcmTokens');
        const allTokens = [];

        users.forEach(user => {
            if (user.fcmTokens && user.fcmTokens.length > 0) {
                allTokens.push(...user.fcmTokens);
            }
        });

        if (allTokens.length === 0) {
            return { success: false, message: 'No FCM tokens found for users' };
        }

        // Prepare the message
        const message = {
            notification: {
                title: notificationData.title,
                body: notificationData.body,
            },
            data: {
                ...notificationData.data,
                timestamp: Date.now().toString(),
            },
            tokens: allTokens,
        };

        // Send the message
        const response = await messaging.sendMulticast(message);

        console.log(`Push notification sent to ${userIds.length} users:`, {
            successCount: response.successCount,
            failureCount: response.failureCount,
        });

        return {
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount,
        };
    } catch (error) {
        console.error('Error sending push notifications to users:', error);
        return { success: false, error: error.message };
    }
};

/**
 * Create and send notification (both database and push)
 * @param {Object} notificationData - Notification data
 * @param {string} notificationData.userId - User ID
 * @param {string} notificationData.type - Notification type
 * @param {string} notificationData.title - Notification title
 * @param {string} notificationData.message - Notification message
 * @param {Object} notificationData.data - Additional data
 * @param {boolean} sendPush - Whether to send push notification
 * @returns {Promise<Object>} - Created notification and push result
 */
const createAndSendNotification = async (notificationData, sendPush = true) => {
    try {
        // Create notification in database
        const notification = await Notification.create({
            userId: notificationData.userId,
            type: notificationData.type,
            title: notificationData.title,
            message: notificationData.message,
            data: notificationData.data,
        });

        let pushResult = null;

        // Send push notification if requested
        if (sendPush) {
            pushResult = await sendPushNotification(notificationData.userId, {
                title: notificationData.title,
                body: notificationData.message,
                data: {
                    notificationId: notification._id.toString(),
                    type: notificationData.type,
                    ...notificationData.data,
                },
            });
        }

        return {
            success: true,
            notification,
            pushResult,
        };
    } catch (error) {
        console.error('Error creating and sending notification:', error);
        return { success: false, error: error.message };
    }
};

/**
 * Send order status update notification
 * @param {string} userId - User ID
 * @param {string} orderId - Order ID
 * @param {string} status - New order status
 * @param {Object} additionalData - Additional data
 * @returns {Promise<Object>} - Result of the operation
 */
const sendOrderStatusNotification = async (userId, orderId, status, additionalData = {}) => {
    try {
        // Get user preferences
        const User = require('../models/User');
        const user = await User.findById(userId).select('notificationPreferences');

        // Check if user wants order notifications
        if (!user?.notificationPreferences?.orderUpdates) {
            return { success: true, message: 'User has disabled order notifications' };
        }

        const statusMessages = {
            pending_approval: 'Your order has been submitted and is awaiting supplier approval.',
            pending: 'Your order has been approved and is being processed.',
            approved: 'Your order has been approved by the supplier.',
            rejected: 'Your order has been rejected by the supplier.',
            confirmed: 'Your order has been confirmed and will be prepared soon.',
            preparing: 'Your order is being prepared.',
            ready: 'Your order is ready for pickup/delivery.',
            shipped: 'Your order has been shipped.',
            delivered: 'Your order has been delivered successfully.',
            cancelled: 'Your order has been cancelled.',
        };

        const title = `Order ${status.charAt(0).toUpperCase() + status.slice(1)}`;
        const message = statusMessages[status] || `Your order status has been updated to ${status}.`;

        return await createAndSendNotification({
            userId,
            type: 'order',
            title,
            message,
            data: {
                orderId,
                status,
                ...additionalData,
            },
        });
    } catch (error) {
        console.error('Error sending order status notification:', error);
        return { success: false, error: error.message };
    }
};

/**
 * Send supplier notification to customers
 * @param {string} supplierId - Supplier ID sending the notification
 * @param {string} audience - Audience type ('all', 'active', 'new', 'inactive')
 * @param {Object} notificationData - Notification data
 * @param {string} notificationData.type - Notification type
 * @param {string} notificationData.title - Notification title
 * @param {string} notificationData.message - Notification message
 * @param {Object} notificationData.data - Additional data
 * @returns {Promise<Object>} - Result of the operation
 */
const sendSupplierNotification = async (supplierId, audience, notificationData) => {
    try {
        const User = require('../models/User');

        // Build query based on audience
        let query = { role: 'customer' };
        if (audience === 'active') {
            // Active customers: have logged in within last 30 days
            const thirtyDaysAgo = new Date();
            thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
            query.lastLogin = { $gte: thirtyDaysAgo };
        } else if (audience === 'new') {
            // New customers: registered within last 7 days
            const sevenDaysAgo = new Date();
            sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
            query.createdAt = { $gte: sevenDaysAgo };
        } else if (audience === 'inactive') {
            // Inactive customers: haven't logged in for 90+ days
            const ninetyDaysAgo = new Date();
            ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);
            query.lastLogin = { $lt: ninetyDaysAgo };
        }
        // 'all' includes all customers

        // Get customer IDs
        const customers = await User.find(query).select('_id');
        const customerIds = customers.map(c => c._id);

        if (customerIds.length === 0) {
            return { success: true, message: 'No customers found for the specified audience' };
        }

        // Create notifications for each customer
        const notifications = customerIds.map(customerId => ({
            userId: customerId,
            type: notificationData.type,
            title: notificationData.title,
            message: notificationData.message,
            data: notificationData.data,
            sentBy: supplierId,
            audience: audience,
        }));

        const createdNotifications = await Notification.insertMany(notifications);

        // Send push notifications
        const pushResult = await sendPushNotificationToUsers(customerIds, {
            title: notificationData.title,
            body: notificationData.message,
            data: {
                type: notificationData.type,
                sentBy: supplierId,
                audience: audience,
                ...notificationData.data,
            },
        });

        console.log(`Supplier notification sent to ${customerIds.length} customers:`, {
            audience,
            notificationCount: createdNotifications.length,
            pushSuccessCount: pushResult.successCount,
            pushFailureCount: pushResult.failureCount,
        });

        return {
            success: true,
            audience,
            customerCount: customerIds.length,
            notificationCount: createdNotifications.length,
            pushResult,
        };
    } catch (error) {
        console.error('Error sending supplier notification:', error);
        return { success: false, error: error.message };
    }
};

/**
 * Send new product notification to all customers
 * @param {string} supplierId - Supplier ID
 * @param {string} productId - Product ID
 * @param {string} productName - Product name
 * @param {Object} additionalData - Additional data
 * @returns {Promise<Object>} - Result of the operation
 */
const sendNewProductNotification = async (supplierId, productId, productName, additionalData = {}) => {
    return await sendSupplierNotification(supplierId, 'all', {
        type: 'product',
        title: 'New Product Launch!',
        message: `Check out our new product: ${productName}`,
        data: {
            productId,
            productName,
            ...additionalData,
        },
    });
};

module.exports = {
    sendPushNotification,
    sendPushNotificationToUsers,
    createAndSendNotification,
    sendOrderStatusNotification,
    sendSupplierNotification,
    sendNewProductNotification,
};