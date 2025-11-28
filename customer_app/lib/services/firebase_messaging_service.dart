import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');

    // Show local notification
    _showLocalNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.notification?.title}');
    // Handle navigation based on message data
    _handleNotificationNavigation(message.data);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'INDULINK',
      message.notification?.body ?? 'You have a new notification',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    if (response.payload != null) {
      // Parse payload and navigate
      _handleNotificationNavigation(_parsePayload(response.payload!));
    }
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
      case 'message':
        // Navigate to messages
        print('Navigate to messages');
        break;
      case 'product':
        // Navigate to product details
        print('Navigate to product: $id');
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  Map<String, dynamic> _parsePayload(String payload) {
    try {
      // Simple parsing - in production, use proper JSON parsing
      final Map<String, dynamic> data = {};
      final pairs = payload.replaceAll('{', '').replaceAll('}', '').split(', ');
      for (final pair in pairs) {
        final keyValue = pair.split(': ');
        if (keyValue.length == 2) {
          data[keyValue[0]] = keyValue[1];
        }
      }
      return data;
    } catch (e) {
      print('Error parsing payload: $e');
      return {};
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Subscribe user to their role-based topic
  Future<void> subscribeToUserTopics(String userId, String role) async {
    // Subscribe to general notifications
    await subscribeToTopic('all_users');

    // Subscribe to role-specific notifications
    await subscribeToTopic(role);

    // Subscribe to user-specific notifications
    await subscribeToTopic('user_$userId');
  }

  // Unsubscribe from all topics
  Future<void> unsubscribeFromAllTopics() async {
    // Note: Firebase doesn't provide a way to unsubscribe from all topics at once
    // In production, you'd track subscribed topics and unsubscribe individually
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Handle background messages here
  // Note: This function cannot access Flutter widgets or plugins
}
