const Notification = require('../models/Notification');
const User = require('../models/User');
const { sendPushNotification } = require('../services/notificationService');

/// 🔔 Notification Controller
/// Handles notification management and push notifications

// Get user notifications
const getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // Query notifications where:
    // 1. targetRole matches user's role (role-based notifications)
    // 2. targetUsers array contains user's ID (user-specific targeted)
    // 3. userId matches (legacy/backward compatibility)
    const query = {
      $or: [
        { targetRole: userRole },
        { targetUsers: userId },
        { userId: userId }
      ]
    };

    console.log('📥 GET /notifications - User:', userId, 'Role:', userRole);
    console.log('🔍 Query:', JSON.stringify(query));

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    console.log('✅ Found', notifications.length, 'notifications');
    if (notifications.length > 0) {
      console.log('Sample notification:', JSON.stringify(notifications[0]));
    }

    const total = await Notification.countDocuments(query);
    const unreadCount = await Notification.countDocuments({
      ...query,
      isRead: false
    });

    res.status(200).json({
      success: true,
      message: 'Notifications retrieved successfully',
      data: {
        notifications,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit),
        },
        unreadCount,
      },
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve notifications',
    });
  }
};

// Mark notification as read
const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const notification = await Notification.findOneAndUpdate(
      { _id: id, userId },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Notification marked as read',
      data: notification,
    });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark notification as read',
    });
  }
};

// Mark all notifications as read
const markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.id;

    await Notification.updateMany(
      { userId, isRead: false },
      { isRead: true }
    );

    res.status(200).json({
      success: true,
      message: 'All notifications marked as read',
    });
  } catch (error) {
    console.error('Mark all as read error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark all notifications as read',
    });
  }
};

// Delete notification
const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const notification = await Notification.findOneAndDelete({
      _id: id,
      userId,
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Notification deleted successfully',
    });
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete notification',
    });
  }
};

// Register FCM token
const registerFCMToken = async (req, res) => {
  try {
    const { fcmToken, platform } = req.body;
    const userId = req.user.id;

    // Update user's FCM token
    await User.findByIdAndUpdate(userId, {
      fcmToken,
      platform: platform || 'unknown',
      lastTokenUpdate: new Date(),
    });

    res.status(200).json({
      success: true,
      message: 'FCM token registered successfully',
    });
  } catch (error) {
    console.error('Register FCM token error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to register FCM token',
    });
  }
};

// Unregister FCM token
const unregisterFCMToken = async (req, res) => {
  try {
    const { token } = req.params;
    const userId = req.user.id;

    // Remove FCM token from user
    await User.findByIdAndUpdate(userId, {
      $unset: { fcmToken: 1, platform: 1, lastTokenUpdate: 1 },
    });

    res.status(200).json({
      success: true,
      message: 'FCM token unregistered successfully',
    });
  } catch (error) {
    console.error('Unregister FCM token error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to unregister FCM token',
    });
  }
};

// Send test notification (admin only)
const sendTestNotification = async (req, res) => {
  try {
    const { userId, title, message, type, data } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Create notification in database
    const notification = new Notification({
      userId,
      title: title || 'Test Notification',
      message: message || 'This is a test notification',
      type: type || 'system',
      data: data || {},
    });

    await notification.save();

    // Send push notification if user has FCM token
    if (user.fcmToken) {
      await sendPushNotification({
        token: user.fcmToken,
        title: notification.title,
        body: notification.message,
        data: {
          type: notification.type,
          id: notification._id.toString(),
          ...notification.data,
        },
      });
    }

    res.status(200).json({
      success: true,
      message: 'Test notification sent successfully',
      data: notification,
    });
  } catch (error) {
    console.error('Send test notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send test notification',
    });
  }
};

// Get notification statistics (admin only)
const getNotificationStats = async (req, res) => {
  try {
    const totalNotifications = await Notification.countDocuments();
    const unreadNotifications = await Notification.countDocuments({ isRead: false });
    const todayNotifications = await Notification.countDocuments({
      createdAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) },
    });

    res.status(200).json({
      success: true,
      message: 'Notification statistics retrieved successfully',
      data: {
        total: totalNotifications,
        unread: unreadNotifications,
        today: todayNotifications,
      },
    });
  } catch (error) {
    console.error('Get notification stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve notification statistics',
    });
  }
};

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  registerFCMToken,
  unregisterFCMToken,
  sendTestNotification,
  getNotificationStats,
};
