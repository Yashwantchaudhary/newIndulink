import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import '../models/notification.dart';
import 'api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission for notifications
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure FCM
    await _configureFCM();

    // Get FCM token and register with backend
    await _registerFCMToken();
  }

  Future<void> _registerFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');

        // Register token with backend
        await _apiClient.post('/users/fcm-token', data: {
          'token': token,
          'deviceId': 'flutter_app_${DateTime.now().millisecondsSinceEpoch}',
        });

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          print('FCM Token refreshed: $newToken');
          try {
            await _apiClient.post('/users/fcm-token', data: {
              'token': newToken,
              'deviceId':
                  'flutter_app_${DateTime.now().millisecondsSinceEpoch}',
            });
          } catch (e) {
            print('Failed to register refreshed FCM token: $e');
          }
        });
      }
    } catch (e) {
      print('Failed to register FCM token: $e');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  Future<void> _configureFCM() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle messages when app is opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.notification?.title}');

    // Show local notification
    await _showLocalNotification(message);

    // Update notification provider for real-time UI updates
    _updateNotificationProvider(message);
  }

  void _updateNotificationProvider(RemoteMessage message) {
    try {
      final notificationData = message.data;
      if (notificationData.containsKey('notificationId')) {
        // This is a notification from our backend
        // The notification provider will be updated when the app fetches notifications
        // For now, we can trigger a refresh or add the notification locally
        print(
            'Real-time notification received: ${notificationData['notificationId']}');
      }
    } catch (e) {
      print('Error updating notification provider: $e');
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('App opened from notification: ${message.notification?.title}');

    // Handle navigation based on message data
    _handleNotificationNavigation(message.data);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification?.title ?? 'Notification',
      notification?.body ?? '',
      details,
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Handle navigation based on notification type
    final type = data['type'];
    final id = data['id'];

    switch (type) {
      case 'order':
        // Navigate to order details
        print('Navigate to order: $id');
        break;
      case 'product':
        // Navigate to product details
        print('Navigate to product: $id');
        break;
      case 'message':
        // Navigate to messages
        print('Navigate to messages');
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _handleNotificationNavigation(data);
    }
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // API-based notification management methods
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getNotifications({
    bool? isRead,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/notifications',
        queryParameters: {
          if (isRead != null) 'isRead': isRead.toString(),
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final notifications = (response.data['notifications'] as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();

      return {
        'notifications': notifications,
        'unreadCount': response.data['unreadCount'] ?? 0,
        'pagination': response.data['pagination'],
      };
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('/notifications/unread-count');
      return response.data['count'] ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.put('/notifications/$notificationId/read');
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.put('/notifications/mark-all-read');
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiClient.delete('/notifications/$notificationId');
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await _apiClient.delete('/notifications/clear-all');
    } catch (e) {
      throw Exception('Failed to clear all notifications: $e');
    }
  }
}

// Background message handler (must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.notification?.title}');
  // You can perform background tasks here
}
