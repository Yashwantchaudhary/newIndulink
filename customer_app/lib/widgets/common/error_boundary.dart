import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../utils/error_handler.dart';
import 'error_state_widget.dart';

/// Global error boundary widget that catches unhandled exceptions
/// and provides a fallback UI with recovery options
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(
      BuildContext context, AppError error, VoidCallback onRetry)? errorBuilder;
  final VoidCallback? onError;
  final bool showErrorDetails;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
    this.showErrorDetails = kDebugMode,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  AppError? _error;
  StackTrace? _stackTrace;
  final StreamSubscription<AppError>? _errorSubscription;

  _ErrorBoundaryState()
      : _errorSubscription = ErrorHandler().errorStream.listen(
          (error) {
            // Handle global errors if needed
            if (error.severity == ErrorSeverity.critical) {
              // Could show a global error dialog here
            }
          },
        );

  @override
  void initState() {
    super.initState();
    // Set up global error handling for Flutter framework errors
    FlutterError.onError = _handleFlutterError;
    // Set up platform error handling
    PlatformDispatcher.instance.onError = _handlePlatformError;
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    super.dispose();
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    final error = AppError.generic(
      message: details.exception.toString(),
      userMessage: 'An unexpected error occurred in the app.',
      category: ErrorCategory.unknown,
      severity: ErrorSeverity.high,
      originalError: details.exception,
      stackTrace: details.stack,
    );

    ErrorHandler().reportError(error);

    if (mounted) {
      setState(() {
        _error = error;
        _stackTrace = details.stack;
      });
    }

    widget.onError?.call();
  }

  bool _handlePlatformError(Object error, StackTrace stackTrace) {
    final appError = AppError.generic(
      message: error.toString(),
      userMessage: 'A system error occurred.',
      category: ErrorCategory.unknown,
      severity: ErrorSeverity.critical,
      originalError: error,
      stackTrace: stackTrace,
    );

    ErrorHandler().reportError(appError);

    if (mounted) {
      setState(() {
        _error = appError;
        _stackTrace = stackTrace;
      });
    }

    widget.onError?.call();
    return true; // Prevent the error from propagating
  }

  void _resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Use custom error builder if provided
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error!, _resetError);
      }

      // Default error UI
      return Scaffold(
        body: ErrorStateWidget.generic(
          title: 'Oops! Something went wrong',
          message: _error!.userMessage ??
              'An unexpected error occurred. Please try restarting the app.',
          onRetry: _resetError,
        ),
      );
    }

    // Wrap child in error boundary
    return Builder(
      builder: (context) {
        try {
          return widget.child;
        } catch (error, stackTrace) {
          final appError = AppError.generic(
            message: error.toString(),
            userMessage: 'An error occurred while rendering this screen.',
            category: ErrorCategory.unknown,
            severity: ErrorSeverity.high,
            originalError: error,
            stackTrace: stackTrace,
          );

          ErrorHandler().reportError(appError);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _error = appError;
                _stackTrace = stackTrace;
              });
            }
          });

          // Return error UI immediately
          return ErrorStateWidget.generic(
            title: 'Render Error',
            message: 'Failed to display this content. Please try again.',
            onRetry: _resetError,
          );
        }
      },
    );
  }
}

/// Error boundary for specific sections of the app
class SectionErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget Function(BuildContext context, AppError error)? errorBuilder;
  final String sectionName;

  const SectionErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.sectionName = 'section',
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorBuilder: (context, error, onRetry) {
        if (errorBuilder != null) {
          return errorBuilder!(context, error);
        }

        return ErrorStateWidget.generic(
          title: 'Section Error',
          message:
              'Something went wrong in the $sectionName. You can continue using other parts of the app.',
          onRetry: onRetry,
        );
      },
      child: child,
    );
  }
}

/// Error recovery dialog
class ErrorRecoveryDialog extends StatelessWidget {
  final AppError error;
  final VoidCallback onRetry;
  final VoidCallback? onDismiss;
  final bool showDetails;

  const ErrorRecoveryDialog({
    super.key,
    required this.error,
    required this.onRetry,
    this.onDismiss,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        _getErrorTitle(error),
        style: theme.textTheme.headlineSmall,
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
              const SizedBox(height: 16),
              Text(
                'Technical Details:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  error.stackTrace.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (onDismiss != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss!();
            },
            child: const Text('Dismiss'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRetry();
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }

  String _getErrorTitle(AppError error) {
    switch (error.category) {
      case ErrorCategory.network:
        return 'Connection Error';
      case ErrorCategory.api:
        return 'Server Error';
      case ErrorCategory.authentication:
        return 'Authentication Error';
      case ErrorCategory.validation:
        return 'Input Error';
      case ErrorCategory.permission:
        return 'Permission Error';
      default:
        return 'Error';
    }
  }
}

/// Utility function to show error recovery dialog
Future<void> showErrorRecoveryDialog(
  BuildContext context,
  AppError error, {
  VoidCallback? onRetry,
  VoidCallback? onDismiss,
  bool showDetails = false,
}) {
  return showDialog(
    context: context,
    builder: (context) => ErrorRecoveryDialog(
      error: error,
      onRetry: onRetry ?? () {},
      onDismiss: onDismiss,
      showDetails: showDetails,
    ),
  );
}
