import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Enhanced error handling system for the Flutter application
/// Provides comprehensive error management, retry mechanisms, and user-friendly messages

/// Error severity levels
enum ErrorSeverity {
  low,      // Minor issues that don't affect core functionality
  medium,   // Issues that affect some functionality but app can continue
  high,     // Critical issues that severely impact functionality
  critical, // App-breaking errors that require immediate attention
}

/// Error categories for better classification
enum ErrorCategory {
  network,      // Network connectivity issues
  api,          // API-related errors (4xx, 5xx)
  authentication, // Auth-related errors
  validation,   // Input validation errors
  permission,   // Permission-related errors
  storage,      // Local storage errors
  parsing,      // Data parsing/serialization errors
  unknown,      // Unclassified errors
}

/// Enhanced error model with detailed information
class AppError implements Exception {
  final String message;
  final String? userMessage;
  final ErrorCategory category;
  final ErrorSeverity severity;
  final int? statusCode;
  final String? endpoint;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final bool isRetryable;
  final Duration? retryAfter;

  AppError({
    required this.message,
    this.userMessage,
    required this.category,
    this.severity = ErrorSeverity.medium,
    this.statusCode,
    this.endpoint,
    this.originalError,
    this.stackTrace,
    this.metadata,
    this.isRetryable = false,
    this.retryAfter,
  }) : timestamp = DateTime.now();

  /// Create network error
  factory AppError.network({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      message: message,
      userMessage: 'Please check your internet connection and try again.',
      category: ErrorCategory.network,
      severity: ErrorSeverity.high,
      originalError: originalError,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }

  /// Create API error
  factory AppError.api({
    required int statusCode,
    required String message,
    String? endpoint,
    dynamic originalError,
    bool isRetryable = false,
  }) {
    String userMessage;
    ErrorSeverity severity;
    ErrorCategory category = ErrorCategory.api;

    switch (statusCode) {
      case 400:
        userMessage = 'Invalid request. Please check your input.';
        severity = ErrorSeverity.low;
        break;
      case 401:
        userMessage = 'Your session has expired. Please login again.';
        severity = ErrorSeverity.high;
        category = ErrorCategory.authentication;
        break;
      case 403:
        userMessage = 'You don\'t have permission to perform this action.';
        severity = ErrorSeverity.medium;
        category = ErrorCategory.permission;
        break;
      case 404:
        userMessage = 'The requested resource was not found.';
        severity = ErrorSeverity.low;
        break;
      case 409:
        userMessage = 'This action conflicts with existing data.';
        severity = ErrorSeverity.medium;
        break;
      case 422:
        userMessage = 'Please check your input and try again.';
        severity = ErrorSeverity.low;
        category = ErrorCategory.validation;
        break;
      case 429:
        userMessage = 'Too many requests. Please wait a moment.';
        severity = ErrorSeverity.medium;
        isRetryable = true;
        break;
      case 500:
      case 502:
      case 503:
      case 504:
        userMessage = 'Server is temporarily unavailable. Please try again later.';
        severity = ErrorSeverity.high;
        isRetryable = true;
        break;
      default:
        userMessage = 'An unexpected error occurred. Please try again.';
        severity = ErrorSeverity.medium;
        isRetryable = statusCode >= 500;
    }

    return AppError(
      message: message,
      userMessage: userMessage,
      category: category,
      severity: severity,
      statusCode: statusCode,
      endpoint: endpoint,
      originalError: originalError,
      isRetryable: isRetryable,
    );
  }

  /// Create authentication error
  factory AppError.auth({
    required String message,
    String? userMessage,
    dynamic originalError,
  }) {
    return AppError(
      message: message,
      userMessage: userMessage ?? 'Authentication failed. Please try logging in again.',
      category: ErrorCategory.authentication,
      severity: ErrorSeverity.high,
      originalError: originalError,
      isRetryable: false,
    );
  }

  /// Create validation error
  factory AppError.validation({
    required String message,
    String? userMessage,
    dynamic originalError,
  }) {
    return AppError(
      message: message,
      userMessage: userMessage ?? 'Please check your input and try again.',
      category: ErrorCategory.validation,
      severity: ErrorSeverity.low,
      originalError: originalError,
      isRetryable: false,
    );
  }

  /// Create generic error
  factory AppError.generic({
    required String message,
    String? userMessage,
    ErrorCategory category = ErrorCategory.unknown,
    ErrorSeverity severity = ErrorSeverity.medium,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      message: message,
      userMessage: userMessage ?? 'An unexpected error occurred.',
      category: category,
      severity: severity,
      originalError: originalError,
      stackTrace: stackTrace,
      isRetryable: false,
    );
  }

  @override
  String toString() {
    return 'AppError: $message (Category: $category, Severity: $severity, Status: $statusCode)';
  }

  /// Convert to JSON for logging
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'userMessage': userMessage,
      'category': category.toString(),
      'severity': severity.toString(),
      'statusCode': statusCode,
      'endpoint': endpoint,
      'timestamp': timestamp.toIso8601String(),
      'isRetryable': isRetryable,
      'retryAfter': retryAfter?.inSeconds,
      'metadata': metadata,
      'stackTrace': stackTrace?.toString(),
    };
  }
}

/// Result wrapper for operations that can fail
class Result<T> {
  final T? data;
  final AppError? error;
  final bool isSuccess;

  Result.success(T data)
      : data = data,
        error = null,
        isSuccess = true;

  Result.failure(AppError error)
      : data = null,
        error = error,
        isSuccess = false;

  static Result<T> fromError<T>(dynamic error, {StackTrace? stackTrace}) {
    final appError = ErrorHandler.convertToAppError(error, stackTrace: stackTrace);
    return Result.failure(appError);
  }
}

/// Enhanced error handler with comprehensive error management
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<AppError> _errorStream = StreamController<AppError>.broadcast();

  /// Stream of errors for global error handling
  Stream<AppError> get errorStream => _errorStream.stream;

  /// Convert various error types to AppError
  static AppError convertToAppError(dynamic error, {StackTrace? stackTrace, String? endpoint}) {
    if (error is AppError) {
      return error;
    }

    if (error is DioException) {
      return _handleDioError(error, endpoint: endpoint);
    }

    if (error is SocketException) {
      return AppError.network(
        message: 'Network connection failed',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException) {
      return AppError.generic(
        message: 'Data parsing error',
        userMessage: 'Received invalid data from server.',
        category: ErrorCategory.parsing,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is TimeoutException) {
      return AppError.network(
        message: 'Operation timed out',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Generic error
    return AppError.generic(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Handle Dio-specific errors
  static AppError _handleDioError(DioException error, {String? endpoint}) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError.network(
          message: 'Request timeout',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = error.response?.data?['message'] ??
                       error.response?.data?['error'] ??
                       error.message ??
                       'Unknown error';

        return AppError.api(
          statusCode: statusCode,
          message: message,
          endpoint: endpoint,
          originalError: error,
          isRetryable: statusCode >= 500 || statusCode == 429,
        );

      case DioExceptionType.cancel:
        return AppError.generic(
          message: 'Request was cancelled',
          userMessage: 'Operation was cancelled.',
          category: ErrorCategory.network,
          originalError: error,
        );

      case DioExceptionType.unknown:
        // Check if it's a network error
        if (error.error is SocketException ||
            error.message?.contains('Failed host lookup') == true ||
            error.message?.contains('Network is unreachable') == true) {
          return AppError.network(
            message: 'Network connection error',
            originalError: error,
          );
        }

        return AppError.generic(
          message: error.message ?? 'Unknown network error',
          category: ErrorCategory.network,
          originalError: error,
        );

      default:
        return AppError.generic(
          message: error.message ?? 'Unknown error',
          originalError: error,
        );
    }
  }

  /// Report error to global error stream
  void reportError(AppError error) {
    _errorStream.add(error);

    // Log error based on severity
    switch (error.severity) {
      case ErrorSeverity.critical:
        _logCritical(error);
        break;
      case ErrorSeverity.high:
        _logError(error);
        break;
      case ErrorSeverity.medium:
        _logWarning(error);
        break;
      case ErrorSeverity.low:
        _logInfo(error);
        break;
    }
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _errorStream.close();
  }

  // Logging methods (placeholders)
  void _logCritical(AppError error) {
    if (kDebugMode) {
      print('🔴 CRITICAL: ${error.message}');
    }
  }

  void _logError(AppError error) {
    if (kDebugMode) {
      print('❌ ERROR: ${error.message}');
    }
  }

  void _logWarning(AppError error) {
    if (kDebugMode) {
      print('⚠️ WARNING: ${error.message}');
    }
  }

  void _logInfo(AppError error) {
    if (kDebugMode) {
      print('ℹ️ INFO: ${error.message}');
    }
  }
}

/// Retry configuration
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(AppError) shouldRetry;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.shouldRetry = _defaultShouldRetry,
  });

  static bool _defaultShouldRetry(AppError error) {
    return error.isRetryable;
  }
}

/// Retry mechanism with exponential backoff
class RetryMechanism {
  static Future<T> execute<T>(
    Future<T> Function() operation,
    RetryConfig config,
  ) async {
    int attempts = 0;
    Duration delay = config.initialDelay;

    while (attempts < config.maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        attempts++;

        final appError = ErrorHandler.convertToAppError(error);

        // Don't retry if it's the last attempt or shouldn't retry
        if (attempts >= config.maxAttempts || !config.shouldRetry(appError)) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(delay);

        // Calculate next delay with exponential backoff
        delay = Duration(
          milliseconds: (delay.inMilliseconds * config.backoffMultiplier).round(),
        );

        // Cap the delay
        if (delay > config.maxDelay) {
          delay = config.maxDelay;
        }

        if (kDebugMode) {
          print('🔄 Retrying operation (attempt $attempts/${config.maxAttempts}) after ${delay.inSeconds}s');
        }
      }
    }

    throw Exception('Max retry attempts exceeded');
  }
}