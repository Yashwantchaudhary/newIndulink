import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_config.dart';
import 'storage_service.dart';

/// 🌐 API Service
/// Base HTTP client with authentication, error handling, and retry logic
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  final StorageService _storage = StorageService();

  // ==================== HTTP Methods ====================

  /// GET request
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? params,
    bool requiresAuth = true,
    int retries = 0,
  }) async {
    try {
      final uri = _buildUri(endpoint, params);
      final headers = await _getHeaders(requiresAuth);

      final response = await _client
          .get(uri, headers: headers)
          .timeout(AppConfig.connectTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST request
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    int retries = 0,
  }) async {
    try {
      final uri = _buildUri(endpoint, null);
      final headers = await _getHeaders(requiresAuth);

      // Debug logging
      debugPrint('🌐 POST $uri');
      if (body != null) {
        debugPrint('📤 Body: ${jsonEncode(body)}');
      }

      final response = await _client
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
            encoding: Encoding.getByName('utf-8'),
          )
          .timeout(AppConfig.connectTimeout);

      debugPrint('📥 Response: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ POST Error: $e');
      return _handleError(e);
    }
  }

  /// PUT request
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    int retries = 0,
  }) async {
    try {
      final uri = _buildUri(endpoint, null);
      final headers = await _getHeaders(requiresAuth);

      final response = await _client
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConfig.connectTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE request
  Future<ApiResponse> delete(
    String endpoint, {
    bool requiresAuth = true,
    int retries = 0,
  }) async {
    try {
      final uri = _buildUri(endpoint, null);
      final headers = await _getHeaders(requiresAuth);

      final response = await _client
          .delete(uri, headers: headers)
          .timeout(AppConfig.connectTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// PATCH request
  Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    int retries = 0,
  }) async {
    try {
      final uri = _buildUri(endpoint, null);
      final headers = await _getHeaders(requiresAuth);

      final response = await _client
          .patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConfig.connectTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== Helper Methods ====================

  /// Build URI with query parameters
  Uri _buildUri(String endpoint, Map<String, String>? params) {
    final url = '${AppConfig.baseUrl}$endpoint';
    final uri = Uri.parse(url);

    if (params != null && params.isNotEmpty) {
      return uri.replace(queryParameters: params);
    }

    return uri;
  }

  /// Get headers with optional authentication
  Future<Map<String, String>> _getHeaders(bool requiresAuth) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _storage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Handle HTTP response
  ApiResponse _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    // Success responses (200-299)
    if (statusCode >= 200 && statusCode < 300) {
      dynamic data;
      try {
        data = body.isNotEmpty ? jsonDecode(body) : null;
      } catch (e) {
        data = body;
      }

      return ApiResponse(
        success: true,
        statusCode: statusCode,
        data: data,
      );
    }

    // Error responses
    String message = 'An error occurred';
    dynamic errorData;

    try {
      errorData = jsonDecode(body);
      message = errorData['message'] ?? errorData['error'] ?? message;
    } catch (e) {
      message = body.isNotEmpty ? body : message;
    }

    return ApiResponse(
      success: false,
      statusCode: statusCode,
      message: message,
      data: errorData,
    );
  }

  /// Handle errors (network, timeout, etc.)
  ApiResponse _handleError(dynamic error) {
    String message = 'An unexpected error occurred';

    if (error is SocketException) {
      message = 'No internet connection';
    } else if (error is HttpException) {
      message = 'Server error occurred';
    } else if (error is FormatException) {
      message = 'Invalid response format';
    } else if (error.toString().contains('TimeoutException')) {
      message = 'Request timeout';
    }

    return ApiResponse(
      success: false,
      message: message,
      statusCode: 0,
    );
  }

  /// Upload multiple files (for product images, documents)
  Future<ApiResponse> uploadFiles(
    String endpoint,
    List<File> files, {
    Map<String, String>? fields,
    String fileField = 'files',
    String method = 'POST',
  }) async {
    try {
      final uri = _buildUri(endpoint, null);
      final token = await _storage.getAccessToken();

      final request = http.MultipartRequest(method, uri);

      // Add authorization header
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add files
      for (var file in files) {
        final fileStream = http.ByteStream(file.openRead());
        final fileLength = await file.length();
        final multipartFile = http.MultipartFile(
          fileField,
          fileStream,
          fileLength,
          filename: file.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Upload file (for images, documents)
  Future<ApiResponse> uploadFile(
    String endpoint,
    File file, {
    Map<String, String>? fields,
    String fileField = 'file',
  }) async {
    try {
      final uri = _buildUri(endpoint, null);
      final token = await _storage.getAccessToken();

      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        fileField,
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}

/// 📋 API Response Model
class ApiResponse {
  final bool success;
  final int statusCode;
  final String? message;
  final dynamic data;

  ApiResponse({
    required this.success,
    required this.statusCode,
    this.message,
    this.data,
  });

  /// Check if response is successful
  bool get isSuccess => success && statusCode >= 200 && statusCode < 300;

  /// Check if unauthorized (401)
  bool get isUnauthorized => statusCode == 401;

  /// Check if forbidden (403)
  bool get isForbidden => statusCode == 403;

  /// Check if not found (404)
  bool get isNotFound => statusCode == 404;

  /// Check if server error (500+)
  bool get isServerError => statusCode >= 500;

  /// Check if client error (400-499)
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  @override
  String toString() {
    return 'ApiResponse(success: $success, statusCode: $statusCode, message: $message)';
  }
}

/// 🚨 API Exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}
