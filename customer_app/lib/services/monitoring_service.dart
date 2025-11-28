import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart';

/// Monitoring service for error reporting and performance tracking
class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  bool _isInitialized = false;

  /// Initialize Sentry for error reporting and performance monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await SentryFlutter.init(
        (options) {
          options.dsn = const String.fromEnvironment(
            'SENTRY_DSN',
            defaultValue: '', // Set via --dart-define or environment
          );

          // Only enable Sentry if DSN is provided
          if (options.dsn?.isEmpty ?? true) {
            return; // Skip initialization if no DSN
          }

          options.tracesSampleRate =
              kReleaseMode ? 0.1 : 1.0; // 10% in production, 100% in debug
          options.profilesSampleRate = kReleaseMode ? 0.1 : 1.0;

          // Enable performance monitoring
          options.enableTracing = true;

          // Configure environment
          options.environment = kReleaseMode ? 'production' : 'development';

          // Performance monitoring options
          options.enableAppLifecycleBreadcrumbs = true;
          options.enableAutoSessionTracking = true;
          options.enableNativeCrashHandling = true;

          // User interaction tracking
          options.enableUserInteractionTracing = true;
          options.enableAutoPerformanceTracing = true;
        },
      );

      _isInitialized = true;

      if (_isInitialized) {
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Monitoring service initialized',
            category: 'monitoring',
            level: SentryLevel.info,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to initialize Sentry: $e');
    }
  }

  /// Track user interaction performance
  Future<void> trackUserInteraction(
      String interactionName, Duration duration) async {
    if (!_isInitialized) return;

    try {
      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'User interaction: $interactionName',
          category: 'user_interaction',
          level: SentryLevel.info,
          data: {'duration_ms': duration.inMilliseconds},
        ),
      );

      // Start a performance transaction for significant interactions
      if (duration.inMilliseconds > 100) {
        final transaction = Sentry.startTransaction(
          'user_interaction_$interactionName',
          'interaction',
        );

        transaction.setMeasurement(
          'interaction_duration',
          duration.inMilliseconds.toDouble(),
          unit: DurationSentryMeasurementUnit.milliSecond,
        );

        transaction.finish();
      }
    } catch (e) {
      debugPrint('Failed to track user interaction: $e');
    }
  }

  /// Track API call performance
  Future<void> trackApiCall(String endpoint, Duration duration, int statusCode,
      {String? error}) async {
    if (!_isInitialized) return;

    try {
      final isError = statusCode >= 400 || error != null;

      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'API call: $endpoint',
          category: 'api',
          level: isError ? SentryLevel.error : SentryLevel.info,
          data: {
            'duration_ms': duration.inMilliseconds,
            'status_code': statusCode,
            'error': error,
          },
        ),
      );

      // Start performance transaction for slow API calls
      if (duration.inMilliseconds > 1000 || isError) {
        final transaction = Sentry.startTransaction(
          'api_call_${endpoint.replaceAll('/', '_')}',
          'http',
        );

        transaction.setMeasurement(
          'api_duration',
          duration.inMilliseconds.toDouble(),
          unit: DurationSentryMeasurementUnit.milliSecond,
        );

        if (isError) {
          transaction.setTag('error', 'true');
          transaction.setTag('status_code', statusCode.toString());
        }

        transaction.finish();
      }
    } catch (e) {
      debugPrint('Failed to track API call: $e');
    }
  }

  /// Track navigation performance
  Future<void> trackNavigation(
      String fromRoute, String toRoute, Duration duration) async {
    if (!_isInitialized) return;

    try {
      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Navigation: $fromRoute -> $toRoute',
          category: 'navigation',
          level: SentryLevel.info,
          data: {'duration_ms': duration.inMilliseconds},
        ),
      );

      // Start performance transaction for slow navigations
      if (duration.inMilliseconds > 500) {
        final transaction = Sentry.startTransaction(
          'navigation_${fromRoute}_to_$toRoute',
          'navigation',
        );

        transaction.setMeasurement(
          'navigation_duration',
          duration.inMilliseconds.toDouble(),
          unit: DurationSentryMeasurementUnit.milliSecond,
        );

        transaction.finish();
      }
    } catch (e) {
      debugPrint('Failed to track navigation: $e');
    }
  }

  /// Track custom performance metric
  Future<void> trackPerformance(String name, Duration duration,
      {Map<String, String>? tags}) async {
    if (!_isInitialized) return;

    try {
      final transaction = Sentry.startTransaction(name, 'performance');

      transaction.setMeasurement(
        '${name}_duration',
        duration.inMilliseconds.toDouble(),
        unit: DurationSentryMeasurementUnit.milliSecond,
      );

      // Add custom tags
      tags?.forEach((key, value) {
        transaction.setTag(key, value);
      });

      transaction.finish();
    } catch (e) {
      debugPrint('Failed to track performance: $e');
    }
  }

  /// Report custom error with context
  Future<void> reportError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    if (!_isInitialized) return;

    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (context != null) {
            scope.setTag('context', context);
          }

          if (extra != null) {
            scope.setContexts('extra', extra);
          }

          scope.setTag('custom_error', 'true');
        },
      );
    } catch (e) {
      debugPrint('Failed to report error: $e');
    }
  }

  /// Track Core Web Vitals (for web platform)
  Future<void> trackCoreWebVitals({
    double? cls, // Cumulative Layout Shift
    double? fid, // First Input Delay
    double? lcp, // Largest Contentful Paint
  }) async {
    if (!_isInitialized) return;

    try {
      final transaction =
          Sentry.startTransaction('core_web_vitals', 'web_vitals');

      if (cls != null) {
        transaction.setMeasurement('cls', cls);
      }
      if (fid != null) {
        transaction.setMeasurement('fid', fid,
            unit: DurationSentryMeasurementUnit.milliSecond);
      }
      if (lcp != null) {
        transaction.setMeasurement('lcp', lcp,
            unit: DurationSentryMeasurementUnit.milliSecond);
      }

      transaction.finish();
    } catch (e) {
      debugPrint('Failed to track Core Web Vitals: $e');
    }
  }

  /// Set user context for better error tracking
  void setUserContext({String? id, String? email, String? username}) {
    if (!_isInitialized) return;

    try {
      Sentry.configureScope((scope) {
        scope.setUser(SentryUser(
          id: id,
          email: email,
          username: username,
        ));
      });
    } catch (e) {
      debugPrint('Failed to set user context: $e');
    }
  }

  /// Add custom breadcrumb
  void addBreadcrumb(String message,
      {String category = 'custom', SentryLevel level = SentryLevel.info}) {
    if (!_isInitialized) return;

    try {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          level: level,
        ),
      );
    } catch (e) {
      debugPrint('Failed to add breadcrumb: $e');
    }
  }
}
