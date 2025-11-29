import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../services/api_service.dart';

/// 🔔 Customer Notifications Screen
class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState
    extends State<CustomerNotificationsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/api/notifications');
      if (response.isSuccess && response.data != null) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(
              response.data['notifications'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    await _apiService.put('/api/notifications/$id/read', body: {});
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await _apiService.put('/api/notifications/read-all', body: {});
              _loadNotifications();
            },
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off,
                          size: 64, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      Text('No notifications', style: AppTypography.h5),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final isUnread = !(notif['isRead'] ?? false);

                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getNotifColor(notif['type'])
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getNotifIcon(notif['type']),
                              color: _getNotifColor(notif['type'])),
                        ),
                        title: Text(
                          notif['title'] ?? 'Notification',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight:
                                isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notif['message'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(notif['createdAt']),
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        trailing: isUnread
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                        onTap: () => _markAsRead(notif['_id']),
                        tileColor: isUnread
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : null,
                      );
                    },
                  ),
                ),
    );
  }

  IconData _getNotifIcon(String? type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag;
      case 'payment':
        return Icons.payment;
      case 'shipping':
        return Icons.local_shipping;
      case 'promo':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotifColor(String? type) {
    switch (type) {
      case 'order':
        return AppColors.primary;
      case 'payment':
        return AppColors.success;
      case 'shipping':
        return AppColors.info;
      case 'promo':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final time = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(time);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${time.day}/${time.month}/${time.year}';
    } catch (e) {
      return '';
    }
  }
}
