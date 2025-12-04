const express = require('express');
const router = express.Router();
const {
  createNotification,
  sendNotification,
  getNotifications,
  getNotification,
  updateNotification,
  deleteNotification,
  getNotificationStatus,
  getNotificationStats,
  processScheduledNotifications,
  createTemplate,
  getTemplates,
  getTemplate,
  updateTemplate,
  deleteTemplate,
  testTemplate,
  sendEmailNotification,
  sendSmsNotification,
  sendPushNotification,
  sendInAppNotification
} = require('../controllers/enhancedNotificationController');
const { protect } = require('../middleware/authMiddleware');
const { requireRole } = require('../middleware/roleMiddleware');

// All routes require authentication
router.use(protect);

// Notification Management Routes
router.post('/', requireRole(['admin']), createNotification);
router.post('/:id/send', requireRole(['admin']), sendNotification);
router.get('/', getNotifications);
router.get('/:id', getNotification);
router.put('/:id', requireRole(['admin']), updateNotification);
router.delete('/:id', requireRole(['admin']), deleteNotification);
router.get('/:id/status', getNotificationStatus);
router.get('/stats', requireRole(['admin']), getNotificationStats);
router.get('/analytics', requireRole(['admin']), getDetailedAnalytics);
router.get('/trends', requireRole(['admin']), getPerformanceTrends);
router.get('/effectiveness', requireRole(['admin']), getNotificationEffectiveness);
router.post('/process-scheduled', requireRole(['admin']), processScheduledNotifications);

// Template Management Routes
router.post('/templates', requireRole(['admin']), createTemplate);
router.get('/templates', getTemplates);
router.get('/templates/:id', getTemplate);
router.put('/templates/:id', requireRole(['admin']), updateTemplate);
router.delete('/templates/:id', requireRole(['admin']), deleteTemplate);
router.post('/templates/:id/test', testTemplate);

// Channel-specific Routes
router.post('/email', requireRole(['admin']), sendEmailNotification);
router.post('/sms', requireRole(['admin']), sendSmsNotification);
router.post('/push', requireRole(['admin']), sendPushNotification);
router.post('/in-app', requireRole(['admin']), sendInAppNotification);

module.exports = router;