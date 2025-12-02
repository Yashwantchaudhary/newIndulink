const express = require('express');
const router = express.Router();
const {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  registerFCMToken,
  unregisterFCMToken,
  sendTestNotification,
  getNotificationStats,
} = require('../controllers/notificationController');
const { protect } = require('../middleware/authMiddleware');
const { requireRole } = require('../middleware/roleMiddleware');

// All notification routes require authentication
router.use(protect);

// User notification routes
router.get('/', getNotifications);
router.put('/:id/read', markAsRead);
router.put('/read-all', markAllAsRead);
router.delete('/:id', deleteNotification);

// FCM token management
router.post('/fcm-token', registerFCMToken);
router.delete('/fcm-token/:token', unregisterFCMToken);

// Admin routes
router.post('/test', requireRole(['admin']), sendTestNotification);
router.get('/stats', requireRole(['admin']), getNotificationStats);

module.exports = router;
