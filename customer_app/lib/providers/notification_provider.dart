import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

// Notification Provider
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

// Notification State
class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? pagination;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.pagination,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? pagination,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pagination: pagination ?? this.pagination,
    );
  }
}

// Notification Notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState());

  final NotificationService _notificationService = NotificationService();

  // Get notifications
  Future<void> getNotifications({
    bool? isRead,
    int page = 1,
    int limit = 20,
    bool loadMore = false,
  }) async {
    try {
      if (!loadMore) {
        state = state.copyWith(isLoading: true, error: null);
      }

      final result = await _notificationService.getNotifications(
        isRead: isRead,
        page: page,
        limit: limit,
      );

      final List<AppNotification> notifications = result['notifications'];
      final int unreadCount = result['unreadCount'];
      final pagination = result['pagination'];

      state = state.copyWith(
        notifications: loadMore
            ? [...state.notifications, ...notifications]
            : notifications,
        unreadCount: unreadCount,
        isLoading: false,
        pagination: pagination,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Load more notifications
  Future<void> loadMoreNotifications() async {
    if (state.isLoading || state.pagination == null) return;

    final currentPage = state.pagination!['page'] ?? 1;
    final totalPages = state.pagination!['pages'] ?? 1;

    if (currentPage >= totalPages) return;

    await getNotifications(
      page: currentPage + 1,
      loadMore: true,
    );
  }

  // Get unread count
  Future<void> getUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      // Silently fail for unread count
      // Error logged silently
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();

      final newUnreadCount = state.unreadCount > 0 ? state.unreadCount - 1 : 0;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _notificationService.markAllAsRead();

      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      // Update local state
      final notification = state.notifications.firstWhere(
        (n) => n.id == notificationId,
      );

      final updatedNotifications =
          state.notifications.where((n) => n.id != notificationId).toList();

      final newUnreadCount = !notification.isRead && state.unreadCount > 0
          ? state.unreadCount - 1
          : state.unreadCount;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _notificationService.clearAllNotifications();

      state = state.copyWith(
        notifications: [],
        unreadCount: 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Add notification (for real-time updates)
  void addNotification(AppNotification notification) {
    state = state.copyWith(
      notifications: [notification, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    );
  }
}
