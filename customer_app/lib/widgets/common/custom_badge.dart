import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Custom badge component for status indicators
class CustomBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool small;

  const CustomBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.small = false,
  });

  /// Factory constructor for order status badges
  factory CustomBadge.status(String status, {bool small = false}) {
    final color = AppColors.getStatusColor(status);
    return CustomBadge(
      label: _formatStatus(status),
      backgroundColor: color,
      textColor: Colors.white,
      small: small,
    );
  }

  /// Format status text
  static String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant);
    final txtColor = textColor ?? AppColors.lightTextPrimary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? AppConstants.spacing8 : AppConstants.spacing12,
        vertical: small ? AppConstants.spacing4 : AppConstants.spacing8,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: small
                  ? AppConstants.iconSizeSmall
                  : AppConstants.iconSizeMedium,
              color: txtColor,
            ),
            SizedBox(width: small ? 4 : 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: txtColor,
              fontSize: small ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
