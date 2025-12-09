import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// 🔔 Global Notification Listener
/// Listens to notification streams and shows in-app alerts (SnackBar)
class GlobalNotificationListener extends StatefulWidget {
  final Widget child;

  const GlobalNotificationListener({
    super.key,
    required this.child,
  });

  @override
  State<GlobalNotificationListener> createState() =>
      _GlobalNotificationListenerState();
}

class _GlobalNotificationListenerState
    extends State<GlobalNotificationListener> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    _notificationService.notificationStream.listen((notification) {
      if (!mounted) return;

      final title = notification['title'] ?? 'Notification';
      final body = notification['body'] ?? '';
      final type = notification['type'] ?? 'info';

      // Show SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (body.isNotEmpty)
                Text(
                  body,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          backgroundColor: _getNotificationColor(type),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              // Handle navigation based on type
              // For now just dismiss
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return AppColors.success;
      case 'error':
        return AppColors.error;
      case 'warning':
        return AppColors.warning;
      case 'info':
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
