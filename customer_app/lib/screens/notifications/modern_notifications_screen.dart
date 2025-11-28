import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/premium_widgets.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification.dart';

/// Ultra-Modern Notifications Screen - Integrated with Real Data
class ModernNotificationsScreen extends ConsumerStatefulWidget {
  const ModernNotificationsScreen({super.key});

  @override
  ConsumerState<ModernNotificationsScreen> createState() =>
      _ModernNotificationsScreenState();
}

class _ModernNotificationsScreenState
    extends ConsumerState<ModernNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load notifications on init
    Future.microtask(() {
      ref.read(notificationProvider.notifier).getNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (notificationState.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notificationState.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: notificationState.unreadCount > 0
                ? () => _markAllAsRead()
                : null,
            tooltip: 'Mark all as read',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Order'),
            Tab(text: 'RFQ'),
          ],
        ),
      ),
      body:
          notificationState.isLoading && notificationState.notifications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotificationsList(null),
                    _buildNotificationsList('order'),
                    _buildNotificationsList('rfq'),
                  ],
                ),
    );
  }

  Widget _buildNotificationsList(String? type) {
    final notificationState = ref.watch(notificationProvider);

    final filteredNotifications = type == null
        ? notificationState.notifications
        : notificationState.notifications.where((n) => n.type == type).toList();

    if (filteredNotifications.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.notifications_none,
        title: 'No Notifications',
        message: 'You\'re all caught up!',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(notificationProvider.notifier).getNotifications();
      },
      child: ListView.builder(
        padding: AppConstants.paddingAll16,
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(filteredNotifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timeAgo = _getTimeAgo(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: const BoxDecoration(
          color: AppColors.error,
          borderRadius: AppConstants.borderRadiusMedium,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        try {
          await ref
              .read(notificationProvider.notifier)
              .deleteNotification(notification.id);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification deleted'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting notification: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: notification.isRead
              ? null
              : LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.05),
                    AppColors.secondaryPurple.withValues(alpha: 0.05),
                  ],
                ),
          color: notification.isRead
              ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
              : null,
          borderRadius: AppConstants.borderRadiusMedium,
          border: Border.all(
            color: notification.isRead
                ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                : AppColors.primaryBlue.withValues(alpha: 0.3),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleNotificationTap(notification),
            borderRadius: AppConstants.borderRadiusMedium,
            child: Padding(
              padding: AppConstants.paddingAll16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _getNotificationGradient(notification.type),
                      borderRadius: AppConstants.borderRadiusSmall,
                      boxShadow: [
                        BoxShadow(
                          color: _getNotificationColor(notification.type)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.lightTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag;
      case 'rfq':
      case 'quote':
      case 'quote_accepted':
        return Icons.request_quote;
      case 'promotion':
        return Icons.local_offer;
      case 'message':
        return Icons.message;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return AppColors.primaryBlue;
      case 'rfq':
      case 'quote':
      case 'quote_accepted':
        return AppColors.success;
      case 'promotion':
        return AppColors.accentOrange;
      case 'message':
        return AppColors.secondaryPurple;
      case 'system':
        return AppColors.lightTextSecondary;
      default:
        return AppColors.primaryBlue;
    }
  }

  LinearGradient _getNotificationGradient(String type) {
    switch (type) {
      case 'order':
        return AppColors.primaryGradient;
      case 'rfq':
      case 'quote':
      case 'quote_accepted':
        return LinearGradient(
          colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
        );
      case 'promotion':
        return AppColors.accentGradient;
      case 'message':
        return AppColors.secondaryGradient;
      case 'system':
        return LinearGradient(
          colors: [
            AppColors.lightTextSecondary,
            AppColors.lightTextSecondary.withValues(alpha: 0.7)
          ],
        );
      default:
        return AppColors.primaryGradient;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }

  void _handleNotificationTap(AppNotification notification) async {
    // Mark as read
    if (!notification.isRead) {
      try {
        await ref
            .read(notificationProvider.notifier)
            .markAsRead(notification.id);
      } catch (e) {
        // Silently fail - user can still see the notification
      }
    }

    // Handle navigation based on notification type and data
    if (notification.data != null) {
      final data = notification.data!;

      if (data.containsKey('orderId')) {
        // Navigate to order details
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening order ${data['orderId']}')),
          );
        }
      } else if (data.containsKey('rfqId')) {
        // Navigate to RFQ details
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening RFQ ${data['rfqId']}')),
          );
        }
      } else if (data.containsKey('productId')) {
        // Navigate to product details
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening product ${data['productId']}')),
          );
        }
      }
    }
  }

  void _markAllAsRead() async {
    try {
      await ref.read(notificationProvider.notifier).markAllAsRead();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
