import 'package:flutter/foundation.dart';
import '../core/constants/app_config.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';

/// 🔔 Notification Provider
/// Manages notifications list and read/unread states
class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  final SocketService _socketService = SocketService();

  // State
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasNotifications => _notifications.isNotEmpty;

  /// Initialize notifications
  Future<void> init() async {
    _initSocketListeners();
    await fetchNotifications();
  }

  void _initSocketListeners() {
    _socketService.orderStream.listen((event) {
      if (event['type'] == 'new') {
        _handleNewOrder(event['data']);
      } else if (event['type'] == 'updated') {
        _handleOrderUpdate(event['data']);
      }
    });

    _socketService.productStream.listen((data) {
      _handleProductUpdate(data);
    });
  }

  void _handleProductUpdate(dynamic data) {
    if (data == null) return;

    final productName = data['productName'] ?? 'Product';
    final operation = data['operation'] ?? 'updated';
    final message = operation == 'created'
        ? 'New product available: $productName'
        : 'Product updated: $productName';

    _notificationService.showInAppNotification(
      title: 'Product Update',
      body: message,
      type: 'product',
    );
  }

  void _handleNewOrder(dynamic data) {
    if (data == null) return;

    // Refresh notifications list to get the new notification from backend if it was saved
    fetchNotifications();

    // Show in-app notification
    final message = data['message'] ?? 'New order received';
    final orderNumber = data['orderNumber'] ?? '';

    _notificationService.showInAppNotification(
      title: 'New Order $orderNumber',
      body: message,
      type: 'order',
    );
  }

  void _handleOrderUpdate(dynamic data) {
    if (data == null) return;

    // Refresh notifications list
    fetchNotifications();

    // Show in-app notification
    final message = data['message'] ?? 'Order status updated';
    final orderNumber = data['orderNumber'] ?? '';
    final status = data['status'] ?? '';

    _notificationService.showInAppNotification(
      title: 'Order Update $orderNumber',
      body: '$message $status',
      type: 'order',
    );
  }

  Future<void> loadSavedNotifications() async {
    // Load notifications from local storage if needed
  }

  /// Request push notification permissions
  Future<bool> requestPermissions() async {
    return await _notificationService.requestPermissions();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.areNotificationsEnabled();
  }

  /// Send test notification (for development)
  Future<void> sendTestNotification({
    required String title,
    required String body,
    String? type,
    String? id,
  }) async {
    await _notificationService.sendTestNotification(
      title: title,
      body: body,
      type: type,
      id: id,
    );
  }

  /// Fetch all notifications
  Future<void> fetchNotifications() async {
    debugPrint('🔔 fetchNotifications() called');
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🔔 Calling API: ${AppConfig.notificationsEndpoint}');
      final response = await _apiService.get(AppConfig.notificationsEndpoint);

      debugPrint('🔔 API Response: success=${response.success}');
      debugPrint('🔔 Full response.data: ${response.data}');

      if (response.success) {
        // Handle nested data: check if data.data exists (API wrapper) or use data directly
        final responseData = response.data;
        final data = (responseData is Map && responseData.containsKey('data'))
            ? responseData['data']
            : responseData;

        debugPrint(
            '🔔 Using data from: ${data is Map ? data.keys.toList() : "not a map"}');

        final List<dynamic> items = data['notifications'] ?? [];
        debugPrint('🔔 Received ${items.length} notifications');
        _notifications =
            items.map((item) => AppNotification.fromJson(item)).toList();
        _unreadCount = data['unreadCount'] ?? 0;
      } else {
        _setError(response.message ?? 'Failed to load notifications');
        debugPrint('🔔 API Error: ${response.message}');
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('🔔 Fetch notifications error: $e');
    }

    _setLoading(false);
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    _clearError();

    try {
      final endpoint = AppConfig.replaceParams(
        AppConfig.markNotificationReadEndpoint,
        {'id': notificationId},
      );
      final response = await _apiService.put(endpoint);

      if (response.success) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          if (_unreadCount > 0) _unreadCount--;
          notifyListeners();
        }
        return true;
      } else {
        _setError(response.message ?? 'Failed to mark as read');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Mark as read error: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    _clearError();

    try {
      final response =
          await _apiService.put(AppConfig.markAllNotificationsReadEndpoint);

      if (response.success) {
        // Update all notifications to read
        _notifications =
            _notifications.map((n) => n.copyWith(isRead: true)).toList();
        _unreadCount = 0;
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to mark all as read');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Mark all as read error: $e');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    _clearError();

    try {
      final endpoint = AppConfig.replaceParams(
        '/notifications/:id',
        {'id': notificationId},
      );
      final response = await _apiService.delete(endpoint);

      if (response.success) {
        _notifications.removeWhere((n) => n.id == notificationId);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to delete notification');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Delete notification error: $e');
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}

/// Notification model
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // order, message, system, etc.
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      data: json['data'],
    );
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}
