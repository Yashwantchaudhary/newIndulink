import 'package:flutter/material.dart';
import '../../utils/error_handler.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import 'premium_button.dart';

/// Enhanced error dialog system with user-friendly messages and recovery options
class ErrorDialogs {
  /// Show error dialog based on error type
  static Future<void> showErrorDialog(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    bool showDetails = false,
  }) async {
    final dialog = _buildErrorDialog(
      context: context,
      error: error,
      onRetry: onRetry,
      onDismiss: onDismiss,
      showDetails: showDetails,
    );

    return showDialog(
      context: context,
      builder: (context) => dialog,
      barrierDismissible: error.severity != ErrorSeverity.critical,
    );
  }

  /// Show network error dialog
  static Future<void> showNetworkErrorDialog(
    BuildContext context, {
    VoidCallback? onRetry,
    String? customMessage,
  }) async {
    final error = AppError.network(
      message: 'Network connection failed',
    );

    return showErrorDialog(
      context,
      error,
      onRetry: onRetry,
    );
  }

  /// Show authentication error dialog with recovery options
  static Future<void> showAuthErrorDialog(
    BuildContext context,
    AppError error, {
    VoidCallback? onLogin,
    VoidCallback? onRetry,
  }) async {
    final dialog = AlertDialog(
      title: const Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: AppColors.error,
            size: AppConstants.iconSizeLarge,
          ),
          SizedBox(width: AppConstants.spacing12),
          Text('Authentication Required'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error.userMessage ??
                'Your session has expired. Please login again.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppConstants.spacing16),
          Text(
            'What would you like to do?',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            child: const Text('Try Again'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        PremiumButton.primary(
          text: 'Login',
          onPressed: () {
            Navigator.of(context).pop();
            onLogin?.call();
          },
        ),
      ],
    );

    return showDialog(
      context: context,
      builder: (context) => dialog,
      barrierDismissible: false,
    );
  }

  /// Show server error dialog
  static Future<void> showServerErrorDialog(
    BuildContext context, {
    VoidCallback? onRetry,
    String? customMessage,
  }) async {
    final error = AppError.api(
      statusCode: 500,
      message: 'Server error',
    );

    return showErrorDialog(
      context,
      error,
      onRetry: onRetry,
    );
  }

  /// Show validation error dialog
  static Future<void> showValidationErrorDialog(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) async {
    final error = AppError.validation(
      message: message,
    );

    return showErrorDialog(
      context,
      error,
      onRetry: onRetry,
    );
  }

  /// Build error dialog based on error properties
  static Widget _buildErrorDialog({
    required BuildContext context,
    required AppError error,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    bool showDetails = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getErrorIcon(error.category),
            color: _getErrorColor(error.severity),
            size: AppConstants.iconSizeLarge,
          ),
          const SizedBox(width: AppConstants.spacing12),
          Expanded(
            child: Text(
              _getErrorTitle(error),
              style: theme.textTheme.headlineSmall,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.userMessage ?? error.message,
              style: theme.textTheme.bodyMedium,
            ),
            if (showDetails && error.stackTrace != null) ...[
              const SizedBox(height: AppConstants.spacing16),
              Container(
                padding: AppConstants.paddingAll12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: AppConstants.borderRadiusSmall,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Technical Details:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing8),
                    Text(
                      error.stackTrace.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            if (error.isRetryable && onRetry != null) ...[
              const SizedBox(height: AppConstants.spacing16),
              Container(
                padding: AppConstants.paddingAll12,
                decoration: BoxDecoration(
                  color: AppColors.infoLight.withValues(alpha: 0.1),
                  borderRadius: AppConstants.borderRadiusSmall,
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.refresh,
                      color: AppColors.info,
                      size: AppConstants.iconSizeMedium,
                    ),
                    const SizedBox(width: AppConstants.spacing8),
                    Expanded(
                      child: Text(
                        'This error can be retried automatically.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (onDismiss != null || error.severity != ErrorSeverity.critical)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: Text(
              error.severity == ErrorSeverity.critical ? 'Exit App' : 'Dismiss',
            ),
          ),
        if (onRetry != null && error.isRetryable)
          PremiumButton.secondary(
            text: 'Retry',
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
          ),
        PremiumButton.primary(
          text: 'OK',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Get appropriate icon for error category
  static IconData _getErrorIcon(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.network:
        return Icons.wifi_off_rounded;
      case ErrorCategory.api:
        return Icons.cloud_off_rounded;
      case ErrorCategory.authentication:
        return Icons.lock_outline_rounded;
      case ErrorCategory.validation:
        return Icons.error_outline_rounded;
      case ErrorCategory.permission:
        return Icons.block_rounded;
      case ErrorCategory.storage:
        return Icons.sd_card_alert_rounded;
      case ErrorCategory.parsing:
        return Icons.code_off_rounded;
      case ErrorCategory.unknown:
        return Icons.warning_amber_rounded;
    }
  }

  /// Get appropriate color for error severity
  static Color _getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return AppColors.neutral600;
      case ErrorSeverity.medium:
        return AppColors.warning;
      case ErrorSeverity.high:
        return AppColors.error;
      case ErrorSeverity.critical:
        return AppColors.error;
    }
  }

  /// Get user-friendly error title
  static String _getErrorTitle(AppError error) {
    switch (error.category) {
      case ErrorCategory.network:
        return 'Connection Problem';
      case ErrorCategory.api:
        return error.statusCode != null && error.statusCode! >= 500
            ? 'Server Error'
            : 'Request Failed';
      case ErrorCategory.authentication:
        return 'Authentication Required';
      case ErrorCategory.validation:
        return 'Invalid Input';
      case ErrorCategory.permission:
        return 'Access Denied';
      case ErrorCategory.storage:
        return 'Storage Error';
      case ErrorCategory.parsing:
        return 'Data Error';
      case ErrorCategory.unknown:
        return 'Something Went Wrong';
    }
  }
}

/// Enhanced snackbar system for errors
class ErrorSnackbars {
  /// Show error snackbar
  static void showErrorSnackbar(
    BuildContext context,
    AppError error, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              ErrorDialogs._getErrorIcon(error.category),
              color: Colors.white,
              size: AppConstants.iconSizeMedium,
            ),
            const SizedBox(width: AppConstants.spacing12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ErrorDialogs._getErrorTitle(error),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    error.userMessage ?? error.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: ErrorDialogs._getErrorColor(error.severity),
        duration: duration,
        action: (onRetry != null || onAction != null)
            ? SnackBarAction(
                label: actionLabel ?? (onRetry != null ? 'Retry' : 'Action'),
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  if (onRetry != null) {
                    onRetry();
                  } else if (onAction != null) {
                    onAction();
                  }
                },
              )
            : null,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusMedium,
        ),
        margin: AppConstants.paddingAll16,
      ),
    );
  }

  /// Show network error snackbar
  static void showNetworkErrorSnackbar(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    final error = AppError.network(message: 'Network connection failed');
    showErrorSnackbar(
      context,
      error,
      onRetry: onRetry,
    );
  }

  /// Show success snackbar for error recovery
  static void showRecoverySuccessSnackbar(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: AppConstants.iconSizeMedium,
            ),
            const SizedBox(width: AppConstants.spacing12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusMedium,
        ),
        margin: AppConstants.paddingAll16,
      ),
    );
  }
}
