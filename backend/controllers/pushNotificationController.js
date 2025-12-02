/// 🔔 Push Notification Controller
/// Handles push notification API endpoints

const pushNotificationService = require('../services/pushNotificationService');
const User = require('../models/User');
const Notification = require('../models/Notification');

// @desc    Register FCM token for user
// @route   POST /api/notifications/register-token
// @access  Private
exports.registerFCMToken = async (req, res, next) => {
    try {
        const { fcmToken, deviceInfo } = req.body;

        if (!fcmToken) {
            return res.status(400).json({
                success: false,
                message: 'FCM token is required'
            });
        }

        // Validate token format (basic validation)
        if (fcmToken.length < 100) {
            return res.status(400).json({
                success: false,
                message: 'Invalid FCM token format'
            });
        }

        // Update user's FCM token
        const user = await User.findByIdAndUpdate(
            req.user.id,
            {
                fcmToken: fcmToken,
                deviceInfo: deviceInfo || {},
                lastTokenUpdate: new Date()
            },
            { new: true }
        );

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'FCM token registered successfully',
            data: {
                tokenRegistered: true,
                lastUpdate: user.lastTokenUpdate
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Unregister FCM token for user
// @route   DELETE /api/notifications/unregister-token
// @access  Private
exports.unregisterFCMToken = async (req, res, next) => {
    try {
        await User.findByIdAndUpdate(req.user.id, {
            $unset: { fcmToken: 1, deviceInfo: 1, lastTokenUpdate: 1 }
        });

        res.status(200).json({
            success: true,
            message: 'FCM token unregistered successfully'
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Send push notification (Admin only)
// @route   POST /api/notifications/send
// @access  Private (Admin only)
exports.sendNotification = async (req, res, next) => {
    try {
        const {
            title,
            body,
            targetUsers,
            targetRole,
            data,
            scheduledTime,
            priority = 'high',
            sound = 'default',
            channelId = 'default_channel'
        } = req.body;

        if (!title || !body) {
            return res.status(400).json({
                success: false,
                message: 'Title and body are required'
            });
        }

        const payload = {
            title,
            body,
            data: data || {},
            priority,
            sound,
            channelId
        };

        let result;

        if (scheduledTime) {
            // Schedule notification for future
            const scheduled = await pushNotificationService.scheduleNotification(
                payload,
                scheduledTime,
                targetUsers,
                targetRole
            );

            result = {
                scheduled: true,
                notificationId: scheduled._id,
                scheduledTime: scheduled.scheduledTime
            };
        } else {
            // Send immediately
            if (targetUsers && targetUsers.length > 0) {
                result = await pushNotificationService.sendToUsers(targetUsers, payload);
            } else if (targetRole) {
                result = await pushNotificationService.sendToRole(targetRole, payload);
            } else {
                result = await pushNotificationService.sendToAll(payload);
            }

            // Store notification in database
            await Notification.create({
                title,
                body,
                data: payload.data,
                targetUsers,
                targetRole,
                sentBy: req.user.id,
                deliveryStats: result,
                status: 'sent',
                sentAt: new Date()
            });
        }

        res.status(200).json({
            success: true,
            message: scheduledTime ? 'Notification scheduled successfully' : 'Notification sent successfully',
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Send order status update notification
// @route   POST /api/notifications/order-status
// @access  Private (Admin and Supplier)
exports.sendOrderStatusNotification = async (req, res, next) => {
    try {
        const { orderId, userId, status, orderNumber } = req.body;

        if (!orderId || !userId || !status || !orderNumber) {
            return res.status(400).json({
                success: false,
                message: 'Order ID, user ID, status, and order number are required'
            });
        }

        const result = await pushNotificationService.sendOrderStatusUpdate(
            orderId,
            userId,
            status,
            orderNumber
        );

        res.status(200).json({
            success: true,
            message: 'Order status notification sent successfully',
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Send new message notification
// @route   POST /api/notifications/new-message
// @access  Private
exports.sendNewMessageNotification = async (req, res, next) => {
    try {
        const { conversationId, recipientId, senderName, message } = req.body;

        if (!conversationId || !recipientId || !senderName || !message) {
            return res.status(400).json({
                success: false,
                message: 'Conversation ID, recipient ID, sender name, and message are required'
            });
        }

        const result = await pushNotificationService.sendNewMessage(
            conversationId,
            recipientId,
            senderName,
            message
        );

        res.status(200).json({
            success: true,
            message: 'New message notification sent successfully',
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Send product back in stock notification
// @route   POST /api/notifications/product-available
// @access  Private (Admin and Supplier)
exports.sendProductAvailableNotification = async (req, res, next) => {
    try {
        const { productId, productName, userIds } = req.body;

        if (!productId || !productName || !userIds || !Array.isArray(userIds)) {
            return res.status(400).json({
                success: false,
                message: 'Product ID, product name, and user IDs array are required'
            });
        }

        const result = await pushNotificationService.sendProductBackInStock(
            productId,
            productName,
            userIds
        );

        res.status(200).json({
            success: true,
            message: 'Product availability notification sent successfully',
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Send RFQ response notification
// @route   POST /api/notifications/rfq-response
// @access  Private (Supplier)
exports.sendRFQResponseNotification = async (req, res, next) => {
    try {
        const { rfqId, customerId, supplierName } = req.body;

        if (!rfqId || !customerId || !supplierName) {
            return res.status(400).json({
                success: false,
                message: 'RFQ ID, customer ID, and supplier name are required'
            });
        }

        const result = await pushNotificationService.sendRFQResponse(
            rfqId,
            customerId,
            supplierName
        );

        res.status(200).json({
            success: true,
            message: 'RFQ response notification sent successfully',
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Send promotional notification
// @route   POST /api/notifications/promotion
// @access  Private (Admin only)
exports.sendPromotionNotification = async (req, res, next) => {
    try {
        const { title, body, targetUsers, targetRole } = req.body;

        if (!title || !body) {
            return res.status(400).json({
                success: false,
                message: 'Title and body are required'
            });
        }

        const result = await pushNotificationService.sendPromotion(
            title,
            body,
            targetUsers,
            targetRole
        );

        res.status(200).json({
            success: true,
            message: 'Promotional notification sent successfully',
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Send maintenance notification
// @route   POST /api/notifications/maintenance
// @access  Private (Admin only)
exports.sendMaintenanceNotification = async (req, res, next) => {
    try {
        const { startTime, endTime } = req.body;

        if (!startTime || !endTime) {
            return res.status(400).json({
                success: false,
                message: 'Start time and end time are required'
            });
        }

        const result = await pushNotificationService.sendMaintenanceNotification(
            startTime,
            endTime
        );

        res.status(200).json({
            success: true,
            message: 'Maintenance notification sent successfully',
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get notification history
// @route   GET /api/notifications/history
// @access  Private (Admin only)
exports.getNotificationHistory = async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const status = req.query.status;
        const startDate = req.query.startDate ? new Date(req.query.startDate) : null;
        const endDate = req.query.endDate ? new Date(req.query.endDate) : null;

        let query = {};

        if (status) {
            query.status = status;
        }

        if (startDate || endDate) {
            query.createdAt = {};
            if (startDate) query.createdAt.$gte = startDate;
            if (endDate) query.createdAt.$lte = endDate;
        }

        const notifications = await Notification.find(query)
            .populate('sentBy', 'name email')
            .sort({ createdAt: -1 })
            .limit(limit)
            .skip((page - 1) * limit);

        const total = await Notification.countDocuments(query);

        res.status(200).json({
            success: true,
            data: {
                notifications,
                pagination: {
                    page,
                    limit,
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get notification statistics
// @route   GET /api/notifications/stats
// @access  Private (Admin only)
exports.getNotificationStats = async (req, res, next) => {
    try {
        const timeframe = req.query.timeframe || '30d';
        const stats = await pushNotificationService.getNotificationStats(timeframe);

        res.status(200).json({
            success: true,
            data: stats
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Clean up invalid FCM tokens
// @route   POST /api/notifications/cleanup-tokens
// @access  Private (Admin only)
exports.cleanupInvalidTokens = async (req, res, next) => {
    try {
        const result = await pushNotificationService.cleanupInvalidTokens();

        res.status(200).json({
            success: true,
            message: `Cleaned up ${result.cleaned} invalid FCM tokens`,
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Test push notification
// @route   POST /api/notifications/test
// @access  Private
exports.testNotification = async (req, res, next) => {
    try {
        const payload = {
            title: 'Test Notification',
            body: 'This is a test push notification from INDULINK',
            data: {
                type: 'test',
                timestamp: new Date().toISOString()
            },
            sound: 'default',
            channelId: 'test'
        };

        const result = await pushNotificationService.sendToUsers([req.user.id], payload);

        res.status(200).json({
            success: true,
            message: 'Test notification sent successfully',
            data: result
        });
    } catch (error) {
        next(error);
    }
};