import 'package:dio/dio.dart';
import 'dart:io';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  late final Dio _dio;
  static ApiService? _instance;

  factory ApiService() {
    print('ApiService: Factory called');
    _instance ??= ApiService._internal();
    return _instance!;
  }

  ApiService._internal() {
    print('ApiService: Initializing with baseUrl: ${AppConfig.apiBaseUrl}');
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Indulink-Mobile-App/1.0.0',
        },
      ),
    );

    // Configure HTTP client based on platform
    if (kIsWeb) {
      print('ApiService: Adding BrowserHttpClientAdapter for web');
      // For web, we would need browser adapter, but since we're building Android only, skip this
      // _dio.httpClientAdapter = BrowserHttpClientAdapter()..withCredentials = true;
    } else {
      // For mobile, use IO adapter with proper configuration for local network
      print('ApiService: Configuring IOHttpClientAdapter for mobile');
      final httpClient = HttpClient();
      // Allow self-signed certificates for development
      httpClient.badCertificateCallback = (cert, host, port) => true;
      // Increase timeout for local network requests
      httpClient.connectionTimeout = const Duration(seconds: 10);
      _dio.httpClientAdapter =
          IOHttpClientAdapter(createHttpClient: () => httpClient);
    }

    // Add interceptors (simplified for debugging)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print(
            'ApiService: Interceptor - Request: ${options.method} ${options.path}');
        print('ApiService: Interceptor - Headers: ${options.headers}');

        // Add authorization token
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Add default language header (will be overridden by specific requests if needed)
        options.headers['Accept-Language'] = 'en';

        return handler.next(options);
      },
      onError: (error, handler) async {
        print(
            'ApiService: Interceptor - Error: ${error.type} ${error.message}');
        // Handle 401 errors (token expired)
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the request
            return handler.resolve(await _retry(error.requestOptions));
          }
        }
        return handler.next(error);
      },
    ));
  }

  // Method to update language header dynamically
  void setLanguage(String languageCode) {
    _dio.options.headers['Accept-Language'] = languageCode;
    print('ApiService: Language updated to: $languageCode');
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.keyAccessToken);
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(AppConfig.keyRefreshToken);

      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['data']['accessToken'];
        await prefs.setString(AppConfig.keyAccessToken, accessToken);
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      print('ApiService: Making POST request to: $path');
      print('ApiService: Base URL: ${AppConfig.apiBaseUrl}');
      print('ApiService: Full URL: ${AppConfig.apiBaseUrl}$path');
      print('ApiService: Data: $data');
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      print('ApiService: POST response: ${response.statusCode}');
      print('ApiService: Response data: ${response.data}');
      return response;
    } catch (e) {
      print('ApiService: POST error: $e');
      print('ApiService: Error type: ${e.runtimeType}');
      if (e is DioException) {
        print('ApiService: Dio error type: ${e.type}');
        print('ApiService: Dio error message: ${e.message}');
        print('ApiService: Dio error response: ${e.response}');
        print('ApiService: Dio error stack: ${e.stackTrace}');
        if (e.response != null) {
          print('ApiService: Response status: ${e.response?.statusCode}');
          print('ApiService: Response data: ${e.response?.data}');
          print('ApiService: Response headers: ${e.response?.headers}');
        }
      }
      rethrow;
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      rethrow;
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // Upload file
  Future<Response> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        if (data != null) ...data,
      });

      return await _dio.post(path, data: formData);
    } catch (e) {
      rethrow;
    }
  }

  // Download file
  Future<String> downloadFile(
    String url,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.download(
        url,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
      );
      return savePath;
    } catch (e) {
      rethrow;
    }
  }
}
