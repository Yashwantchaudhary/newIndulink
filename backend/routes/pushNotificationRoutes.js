/// 🔔 Push Notification Routes
/// API endpoints for push notification management

const express = require('express');
const {
    registerFCMToken,
    unregisterFCMToken,
    sendNotification,
    sendOrderStatusNotification,
    sendNewMessageNotification,
    sendProductAvailableNotification,
    sendRFQResponseNotification,
    sendPromotionNotification,
    sendMaintenanceNotification,
    getNotificationHistory,
    getNotificationStats,
    cleanupInvalidTokens,
    testNotification
} = require('../controllers/pushNotificationController');

const { protect, authorize } = require('../middleware/authMiddleware');

const router = express.Router();

// All routes require authentication
router.use(protect);

// FCM Token Management
router.post('/register-token', registerFCMToken);
router.delete('/unregister-token', unregisterFCMToken);

// Test notification (any authenticated user)
router.post('/test', testNotification);

// Send notifications (Admin only for general notifications)
router.post('/send', authorize('admin'), sendNotification);

// Specific notification types
router.post('/order-status', authorize('admin', 'supplier'), sendOrderStatusNotification);
router.post('/new-message', sendNewMessageNotification);
router.post('/product-available', authorize('admin', 'supplier'), sendProductAvailableNotification);
router.post('/rfq-response', authorize('supplier'), sendRFQResponseNotification);
router.post('/promotion', authorize('admin'), sendPromotionNotification);
router.post('/maintenance', authorize('admin'), sendMaintenanceNotification);

// Analytics and Management (Admin only)
router.get('/history', authorize('admin'), getNotificationHistory);
router.get('/stats', authorize('admin'), getNotificationStats);
router.post('/cleanup-tokens', authorize('admin'), cleanupInvalidTokens);

module.exports = router;