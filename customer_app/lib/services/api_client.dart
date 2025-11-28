import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../utils/error_handler.dart';

class ApiClient {
  static String get baseUrl => AppConfig.apiBaseUrl;

  late final Dio _dio;

  String? _authToken;
  int _requestIdCounter = 0;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add retry interceptor for network failures
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) {
          // Add request ID for tracking
          _requestIdCounter++;
          options.headers['X-Request-ID'] = 'req_$_requestIdCounter';

          // Add auth token to requests
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }

          if (kDebugMode) {
            print(
                '🚀 REQUEST[${options.method}] #${options.headers['X-Request-ID']} => ${options.uri}');
            print('Headers: ${options.headers}');
            if (options.data != null) print('Data: ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            final requestId = response.requestOptions.headers['X-Request-ID'];
            print(
                '✅ RESPONSE[${response.statusCode}] #$requestId => ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          final requestId = error.requestOptions.headers['X-Request-ID'];

          if (kDebugMode) {
            print(
                '❌ ERROR[${error.response?.statusCode}] #$requestId => ${error.requestOptions.uri}');
            print('Message: ${error.message}');
            if (error.response != null) {
              print('Response: ${error.response?.data}');
            }
          }

          // Retry logic for specific error types
          if (_shouldRetry(error)) {
            final retryCount =
                (error.requestOptions.extra['retryCount'] ?? 0) as int;

            if (retryCount < 3) {
              if (kDebugMode) {
                print('🔄 RETRY #${retryCount + 1} for request #$requestId');
              }

              error.requestOptions.extra['retryCount'] = retryCount + 1;

              // Wait before retrying (exponential backoff)
              await Future.delayed(
                  Duration(milliseconds: 500 * (retryCount + 1)));

              try {
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                // If retry fails, continue to error handler
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // Determine if request should be retried
  bool _shouldRetry(DioException error) {
    // Retry on connection timeout, send timeout, or network errors
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        (error.type == DioExceptionType.unknown &&
            error.error?.toString().contains('SocketException') == true);
  }

  // Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Get authentication token
  Future<String?> getToken() async {
    // Return stored token if available, otherwise get from SharedPreferences
    if (_authToken != null) {
      return _authToken;
    }

    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.keyAccessToken);
  }

  // Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e, endpoint: path);
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e, endpoint: path);
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e, endpoint: path);
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e, endpoint: path);
    }
  }

  // Upload file
  Future<Response> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?additionalData,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e, endpoint: path);
    }
  }

  // Enhanced error handling with AppError
  AppError _handleError(DioException error, {String? endpoint}) {
    final appError = ErrorHandler.convertToAppError(error, endpoint: endpoint);

    // Report error to global error handler
    ErrorHandler().reportError(appError);

    return appError;
  }
}
