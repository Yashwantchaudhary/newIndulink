import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_config.dart';
import 'api_service.dart';

/// 📱 Notification Service
/// Handles in-app notifications and local notifications without third-party services
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  final StreamController<Map<String, dynamic>> _notificationController = StreamController.broadcast();

  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load saved preferences
      await _loadPreferences();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('✅ Notification service initialized');
    } catch (error) {
      debugPrint('❌ Notification service initialization error: $error');
      rethrow;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
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
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onLocalNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
      'default_channel',
      'Default',
      description: 'Default notification channel',
      importance: Importance.high,
      playSound: true,
    );

    const AndroidNotificationChannel ordersChannel = AndroidNotificationChannel(
      'orders',
      'Orders',
      description: 'Order status updates',
      importance: Importance.high,
      playSound: true,
    );

    const AndroidNotificationChannel messagesChannel = AndroidNotificationChannel(
      'messages',
      'Messages',
      description: 'New messages',
      importance: Importance.high,
      playSound: true,
    );

    const AndroidNotificationChannel promotionsChannel = AndroidNotificationChannel(
      'promotions',
      'Promotions',
      description: 'Special offers and promotions',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    final List<AndroidNotificationChannel> channels = [
      defaultChannel,
      ordersChannel,
      messagesChannel,
      promotionsChannel,
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Load saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
  }

  /// Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel',
    int? id,
  }) async {
    if (!_notificationsEnabled) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show in-app notification
  void showInAppNotification({
    required String title,
    required String body,
    String? type,
    String? id,
    Duration autoHideDuration = const Duration(seconds: 4),
  }) {
    final notification = {
      'title': title,
      'body': body,
      'type': type,
      'id': id,
      'timestamp': DateTime.now().toIso8601String(),
      'autoHideDuration': autoHideDuration.inMilliseconds,
    };

    _notificationController.add(notification);
  }

  /// Handle local notification tap
  void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationNavigation(data);
      } catch (error) {
        debugPrint('❌ Failed to parse notification payload: $error');
      }
    }
  }

  /// Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'order_status':
          // Navigate to order details
          if (data.containsKey('id')) {
            // NavigationService.navigateTo('/order/${data['id']}');
          }
          break;

        case 'new_message':
          // Navigate to chat
          if (data.containsKey('id')) {
            // NavigationService.navigateTo('/chat/${data['id']}');
          }
          break;

        case 'product_available':
          // Navigate to product details
          if (data.containsKey('id')) {
            // NavigationService.navigateTo('/product/${data['id']}');
          }
          break;

        case 'rfq_response':
          // Navigate to RFQ details
          if (data.containsKey('id')) {
            // NavigationService.navigateTo('/rfq/${data['id']}');
          }
          break;

        default:
          // Navigate to home or notifications screen
          break;
      }
    }
  }

  /// Send notification (combines in-app and local)
  Future<void> showNotification({
    required String title,
    required String body,
    required String type,
    String? id,
    bool showLocal = true,
    bool showInApp = true,
  }) async {
    // Show in-app notification
    if (showInApp) {
      showInAppNotification(
        title: title,
        body: body,
        type: type,
        id: id,
      );
    }

    // Show local notification
    if (showLocal) {
      await showLocalNotification(
        title: title,
        body: body,
        payload: jsonEncode({
          'type': type,
          'id': id,
        }),
      );
    }
  }

  /// Update notification preferences
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get notification settings
  Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'enabled': _notificationsEnabled,
      'platform': 'flutter_local_notifications',
    };
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      await _requestPermissions();
      return true;
    } catch (error) {
      debugPrint('❌ Failed to request permissions: $error');
      return false;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return _notificationsEnabled;
  }

  /// Send test notification
  Future<void> sendTestNotification({
    required String title,
    required String body,
    String? type,
    String? id,
  }) async {
    await showNotification(
      title: title,
      body: body,
      type: type ?? 'test',
      id: id,
    );
  }

  /// Dispose resources
  void dispose() {
    _notificationController.close();
  }
}