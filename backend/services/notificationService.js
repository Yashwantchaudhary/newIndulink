/**
 * Simple Notification Service
 * Handles notifications without third party dependencies
 */

// Simple in-memory notification storage (for development)
const notifications = new Map();

class NotificationService {
    /**
     * Create and send notification (logs only, no external services)
     */
    async createAndSendNotification({ userId, type, title, message, data = {} }) {
        try {
            const notification = {
                id: Date.now().toString(),
                userId,
                type,
                title,
                message,
                data,
                createdAt: new Date().toISOString(),
                read: false
            };

            // Store in memory (in production, this would go to database)
            if (!notifications.has(userId)) {
                notifications.set(userId, []);
            }
            notifications.get(userId).push(notification);

            // Log notification (in production, this might send email, push notification, etc.)
            console.log(`📢 Notification for user ${userId}: ${title} - ${message}`);

            return notification;
        } catch (error) {
            console.error('Error creating notification:', error);
            throw error;
        }
    }

    /**
     * Send push notification (stub - no external service)
     */
    async sendPushNotification(userId, title, message, data = {}) {
        console.log(`📱 Push notification for user ${userId}: ${title} - ${message}`);
        return true;
    }

    /**
     * Send order status notification (stub)
     */
    async sendOrderStatusNotification(orderId, userId, status, orderData = {}) {
        console.log(`📦 Order ${orderId} status update for user ${userId}: ${status}`);
        return true;
    }

    /**
     * Send new product notification (stub)
     */
    async sendNewProductNotification(supplierId, productId, productTitle) {
        console.log(`🆕 New product notification: ${productTitle} by supplier ${supplierId}`);
        return true;
    }

    /**
     * Get user notifications (from memory)
     */
    getUserNotifications(userId) {
        return notifications.get(userId) || [];
    }

    /**
     * Mark notification as read
     */
    markAsRead(userId, notificationId) {
        const userNotifications = notifications.get(userId);
        if (userNotifications) {
            const notification = userNotifications.find(n => n.id === notificationId);
            if (notification) {
                notification.read = true;
                return true;
            }
        }
        return false;
    }
}

// Export singleton instance
const notificationService = new NotificationService();

module.exports = {
    createAndSendNotification: notificationService.createAndSendNotification.bind(notificationService),
    sendPushNotification: notificationService.sendPushNotification.bind(notificationService),
    sendOrderStatusNotification: notificationService.sendOrderStatusNotification.bind(notificationService),
    sendNewProductNotification: notificationService.sendNewProductNotification.bind(notificationService),
    getUserNotifications: notificationService.getUserNotifications.bind(notificationService),
    markAsRead: notificationService.markAsRead.bind(notificationService)
};