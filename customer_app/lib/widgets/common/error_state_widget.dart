import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import 'premium_button.dart';

/// Friendly error state widget with icon, message, and action button
class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final bool showDetails;
  final String? details;

  const ErrorStateWidget({
    super.key,
    this.title,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.showDetails = false,
    this.details,
  });

  /// Network error
  factory ErrorStateWidget.network({
    VoidCallback? onRetry,
  }) {
    return ErrorStateWidget(
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      icon: Icons.wifi_off_rounded,
      iconColor: AppColors.warning,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }

  /// Server error
  factory ErrorStateWidget.server({
    VoidCallback? onRetry,
  }) {
    return ErrorStateWidget(
      title: 'Something Went Wrong',
      message:
          'We\'re having trouble connecting to our servers. Please try again in a moment.',
      icon: Icons.cloud_off_rounded,
      iconColor: AppColors.error,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }

  /// Not found error
  factory ErrorStateWidget.notFound({
    String? message,
    VoidCallback? onAction,
  }) {
    return ErrorStateWidget(
      title: 'Not Found',
      message: message ?? 'The item you\'re looking for doesn\'t exist.',
      icon: Icons.search_off_rounded,
      iconColor: AppColors.neutral600,
      actionLabel: 'Go Back',
      onAction: onAction,
    );
  }

  /// Permission denied
  factory ErrorStateWidget.permissionDenied({
    String? message,
  }) {
    return ErrorStateWidget(
      title: 'Access Denied',
      message: message ?? 'You don\'t have permission to view this content.',
      icon: Icons.lock_rounded,
      iconColor: AppColors.error,
    );
  }

  /// Generic error
  factory ErrorStateWidget.generic({
    String? title,
    String? message,
    VoidCallback? onRetry,
  }) {
    return ErrorStateWidget(
      title: title ?? 'Oops!',
      message: message ?? 'An unexpected error occurred. Please try again.',
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.error,
      actionLabel: 'Try Again',
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: AppConstants.paddingAll24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.error).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: 40,
                color: iconColor ?? AppColors.error,
              ),
            ),
            const SizedBox(height: AppConstants.spacing24),

            // Title
            if (title != null)
              Text(
                title!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            if (title != null) const SizedBox(height: AppConstants.spacing12),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Details (expandable)
            if (showDetails && details != null) ...[
              const SizedBox(height: AppConstants.spacing16),
              ExpansionTile(
                title: Text(
                  'Technical  Details',
                  style: theme.textTheme.bodySmall,
                ),
                children: [
                  Padding(
                    padding: AppConstants.paddingAll16,
                    child: Text(
                      details!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppConstants.spacing24),
              PremiumButton.primary(
                text: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline error banner for forms and sections
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData? icon;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        color: AppColors.errorLight.withValues(alpha: 0.2),
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.error_outline,
            color: AppColors.error,
            size: AppConstants.iconSizeMedium,
          ),
          const SizedBox(width: AppConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppConstants.spacing8),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      actionLabel!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: AppConstants.spacing8),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              color: AppColors.error,
              iconSize: AppConstants.iconSizeSmall,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
}
