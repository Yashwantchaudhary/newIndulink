import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// 🔔 Notification Provider
/// Manages notifications list and read/unread states
class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

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
    await fetchNotifications();
  }

  /// Fetch all notifications
  Future<void> fetchNotifications() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get('/notifications');

      if (response.success) {
        final List<dynamic> items = response.data['notifications'] ?? [];
        _notifications =
            items.map((item) => AppNotification.fromJson(item)).toList();
        _unreadCount = response.data['unreadCount'] ?? 0;
      } else {
        _setError(response.message ?? 'Failed to load notifications');
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Fetch notifications error: $e');
    }

    _setLoading(false);
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    _clearError();

    try {
      final response = await _apiService.put(
        '/notifications/$notificationId/read',
      );

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
      final response = await _apiService.put('/notifications/read-all');

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
      final response = await _apiService.delete(
        '/notifications/$notificationId',
      );

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
