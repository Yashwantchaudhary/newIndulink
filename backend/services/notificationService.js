const admin = require('firebase-admin');
const User = require('../models/User');
const Notification = require('../models/Notification');

// Initialize Firebase Admin SDK (should be done in main app file)
// Make sure to initialize Firebase Admin before using this service

/// 📲 Push Notification Service
/// Handles sending push notifications via Firebase Cloud Messaging

// Send push notification to a single user
const sendPushNotification = async ({
  token,
  title,
  body,
  data = {},
  imageUrl,
  sound = 'default',
}) => {
  try {
    if (!token) {
      console.warn('No FCM token provided for push notification');
      return false;
    }

    const message = {
      token,
      notification: {
        title,
        body,
      },
      data: {
        // Convert all data values to strings as required by FCM
        ...Object.fromEntries(
          Object.entries(data).map(([key, value]) => [key, String(value)])
        ),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          sound,
          defaultSound: true,
          defaultVibrateTimings: true,
          channelId: getChannelIdFromData(data),
        },
      },
      apns: {
        payload: {
          aps: {
            sound,
            badge: 1,
          },
        },
      },
    };

    // Add image if provided
    if (imageUrl) {
      message.notification.imageUrl = imageUrl;
      message.android.notification.imageUrl = imageUrl;
    }

    const response = await admin.messaging().send(message);

    console.log('Push notification sent successfully:', response);
    return true;
  } catch (error) {
    console.error('Error sending push notification:', error);

    // Handle specific FCM errors
    if (error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered') {
      // Token is invalid, should be removed from database
      console.log('Invalid FCM token, should be cleaned up');
    }

    return false;
  }
};

// Send notification to multiple users
const sendPushNotificationToUsers = async (userIds, notificationData) => {
  try {
    // Get FCM tokens for users
    const users = await User.find({
      _id: { $in: userIds },
      fcmToken: { $exists: true, $ne: null }
    }).select('fcmToken');

    const tokens = users
      .map(user => user.fcmToken)
      .filter(token => token && token.trim().length > 0);

    if (tokens.length === 0) {
      console.log('No valid FCM tokens found for users');
      return { success: 0, failure: 0 };
    }

    // Send multicast message
    const message = {
      tokens,
      notification: {
        title: notificationData.title,
        body: notificationData.body,
      },
      data: Object.fromEntries(
        Object.entries(notificationData.data || {}).map(([key, value]) => [key, String(value)])
      ),
      android: {
        priority: 'high',
        notification: {
          channelId: getChannelIdFromData(notificationData.data || {}),
        },
      },
    };

    const response = await admin.messaging().sendMulticast(message);

    console.log(`Push notifications sent: ${response.successCount} success, ${response.failureCount} failure`);

    // Handle failed tokens (could be invalid)
    if (response.failureCount > 0) {
      response.responses.forEach((resp, index) => {
        if (!resp.success) {
          console.error(`Failed to send to token ${tokens[index]}:`, resp.error);
        }
      });
    }

    return {
      success: response.successCount,
      failure: response.failureCount,
    };
  } catch (error) {
    console.error('Error sending multicast push notification:', error);
    return { success: 0, failure: userIds.length };
  }
};

// Create and send notification (combines database + push)
const createAndSendNotification = async ({
  userId,
  title,
  message,
  type = 'system',
  data = {},
  sendPush = true,
}) => {
  try {
    // Create notification in database
    const notification = new Notification({
      userId,
      title,
      message,
      type,
      data,
    });

    await notification.save();

    // Send push notification if requested
    if (sendPush) {
      const user = await User.findById(userId).select('fcmToken');
      if (user && user.fcmToken) {
        await sendPushNotification({
          token: user.fcmToken,
          title,
          body: message,
          data: {
            type,
            id: notification._id.toString(),
            ...data,
          },
        });

        // Mark as sent
        notification.sentPush = true;
        notification.pushSentAt = new Date();
        await notification.save();
      }
    }

    return notification;
  } catch (error) {
    console.error('Error creating and sending notification:', error);
    throw error;
  }
};

// Send order status notification
const sendOrderStatusNotification = async (userId, orderId, status, orderData = {}) => {
  try {
    const statusMessages = {
      pending: 'Your order has been placed successfully',
      confirmed: 'Your order has been confirmed',
      processing: 'Your order is being processed',
      shipped: 'Your order has been shipped',
      delivered: 'Your order has been delivered',
      cancelled: 'Your order has been cancelled',
    };

    const title = 'Order Status Update';
    const message = statusMessages[status] || `Your order status has been updated to ${status}`;

    return await createAndSendNotification({
      userId,
      title,
      message,
      type: 'order_status',
      data: {
        orderId: orderId.toString(),
        status,
        ...orderData,
      },
      sendPush: true,
    });
  } catch (error) {
    console.error('Error sending order status notification:', error);
    throw error;
  }
};

// Send promotional notification to multiple users
const sendPromotionalNotification = async (userIds, title, message, promoData = {}) => {
  try {
    // Create notifications in database
    const notifications = userIds.map(userId => ({
      userId,
      title,
      message,
      type: 'promotion',
      data: promoData,
    }));

    const createdNotifications = await Notification.insertMany(notifications);

    // Send push notifications
    const result = await sendPushNotificationToUsers(userIds, {
      title,
      body: message,
      data: promoData,
    });

    // Mark sent notifications
    const sentIds = createdNotifications.slice(0, result.success).map(n => n._id);
    await Notification.updateMany(
      { _id: { $in: sentIds } },
      {
        sentPush: true,
        pushSentAt: new Date(),
      }
    );

    return {
      notifications: createdNotifications,
      pushResult: result,
    };
  } catch (error) {
    console.error('Error sending promotional notification:', error);
    throw error;
  }
};

// Get appropriate channel ID based on notification data
const getChannelIdFromData = (data) => {
  const type = data.type;

  switch (type) {
    case 'order':
    case 'order_status':
      return 'orders';
    case 'promotion':
    case 'offer':
      return 'promotions';
    default:
      return 'general';
  }
};

// Clean up invalid FCM tokens
const cleanupInvalidTokens = async () => {
  try {
    const User = require('../models/User');

    // Get all users with FCM tokens
    const usersWithTokens = await User.find({
      fcmTokens: { $exists: true, $ne: [] }
    }).select('_id fcmTokens');

    console.log(`Found ${usersWithTokens.length} users with FCM tokens`);

    let totalCleaned = 0;

    for (const user of usersWithTokens) {
      const validTokens = [];

      // Test each token by sending a test message
      for (const token of user.fcmTokens) {
        try {
          // Send a minimal test message to check if token is valid
          await admin.messaging().send({
            token,
            data: { test: 'token_validation' },
            android: { priority: 'normal' },
            apns: { headers: { 'apns-priority': '5' } }
          }, true); // dryRun = true to avoid actually sending

          validTokens.push(token);
        } catch (error) {
          // Token is invalid, don't add to valid tokens
          if (error.code === 'messaging/invalid-registration-token' ||
              error.code === 'messaging/registration-token-not-registered') {
            console.log(`Removing invalid FCM token for user ${user._id}`);
            totalCleaned++;
          } else {
            // For other errors, keep the token (might be temporary issues)
            validTokens.push(token);
          }
        }
      }

      // Update user's FCM tokens
      if (validTokens.length !== user.fcmTokens.length) {
        await User.findByIdAndUpdate(user._id, {
          fcmTokens: validTokens,
          lastTokenCleanup: new Date()
        });
      }
    }

    console.log(`FCM token cleanup completed. Removed ${totalCleaned} invalid tokens.`);
    return { cleaned: totalCleaned };

  } catch (error) {
    console.error('Error cleaning up FCM tokens:', error);
    throw error;
  }
};

module.exports = {
  sendPushNotification,
  sendPushNotificationToUsers,
  createAndSendNotification,
  sendOrderStatusNotification,
  sendPromotionalNotification,
  cleanupInvalidTokens,
};