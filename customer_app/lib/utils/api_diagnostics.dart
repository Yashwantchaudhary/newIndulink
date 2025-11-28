import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import 'package:flutter/foundation.Dart' show kIsWeb;

/// Diagnostic tool to test API connectivity from Flutter web
class ApiConnectionDiagnostics {
  static Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{};
    const baseUrl = 'https://indulink-1.onrender.com';

    print('🔍 ========== API CONNECTION DIAGNOSTICS ==========');

    // Test 1: Basic Dio configuration
    print('\n📝 Test 1: Creating Dio instance...');
    try {
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));

      if (kIsWeb) {
        print('   Platform: Web detected');
        dio.httpClientAdapter = BrowserHttpClientAdapter()
          ..withCredentials = true;
        print('   ✅ BrowserHttpClientAdapter configured with credentials');
      }

      results['dio_created'] = true;
    } catch (e) {
      print('   ❌ Failed to create Dio: $e');
      results['dio_created'] = false;
      results['dio_error'] = e.toString();
      return results;
    }

    // Test 2: Health check endpoint
    print('\n📝 Test 2: Testing health endpoint...');
    try {
      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      if (kIsWeb) {
        dio.httpClientAdapter = BrowserHttpClientAdapter()
          ..withCredentials = true;
      }

      final response = await dio.get('/health');
      print('   Status Code: ${response.statusCode}');
      print('   Response: ${response.data}');
      results['health_check'] = true;
      results['health_response'] = response.data;
    } catch (e) {
      print('   ❌ Health check failed: $e');
      results['health_check'] = false;
      results['health_error'] = e.toString();

      if (e is DioException) {
        print('   Error Type: ${e.type}');
        print('   Error Message: ${e.message}');
        if (e.response != null) {
          print('   Response Status: ${e.response?.statusCode}');
          print('   Response Data: ${e.response?.data}');
        }
      }
    }

    // Test 3: CORS preflight (OPTIONS request)
    print('\n📝 Test 3: Testing CORS preflight...');
    try {
      final dio = Dio(BaseOptions(
        baseUrl: '$baseUrl/api',
        headers: {
          'Origin': 'http://localhost:${Uri.base.port}',
          'Access-Control-Request-Method': 'POST',
          'Access-Control-Request-Headers': 'content-type,authorization',
        },
      ));

      if (kIsWeb) {
        dio.httpClientAdapter = BrowserHttpClientAdapter()
          ..withCredentials = true;
      }

      final response =
          await dio.request('/auth/login', options: Options(method: 'OPTIONS'));
      print('   Status Code: ${response.statusCode}');
      print('   Headers: ${response.headers}');
      results['cors_preflight'] = true;
    } catch (e) {
      print('   ❌ CORS preflight failed: $e');
      results['cors_preflight'] = false;
      results['cors_error'] = e.toString();
    }

    // Test 4: Actual POST request to login
    print('\n📝 Test 4: Testing login endpoint...');
    try {
      final dio = Dio(BaseOptions(
        baseUrl: '$baseUrl/api',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));

      if (kIsWeb) {
        dio.httpClientAdapter = BrowserHttpClientAdapter()
          ..withCredentials = true;
      }

      // Add logging interceptor
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          print('   >>> Request to: ${options.uri}');
          print('   >>> Headers: ${options.headers}');
          print('   >>> Data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('   <<< Response Status: ${response.statusCode}');
          print('   <<< Response Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('   <<< Error Type: ${error.type}');
          print('   <<< Error Message: ${error.message}');
          if (error.response != null) {
            print('   <<< Response Status: ${error.response?.statusCode}');
            print('   <<< Response Data: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ));

      final response = await dio.post('/auth/login', data: {
        'email': 'test@test.com',
        'password': 'test123',
      });

      print('   Status Code: ${response.statusCode}');
      results['login_test'] = true;
      results['login_response'] = response.data;
    } catch (e) {
      print('   ❌ Login test failed: $e');
      results['login_test'] = false;
      results['login_error'] = e.toString();

      if (e is DioException) {
        print('   Error Type: ${e.type}');
        print('   Error Message: ${e.message}');
        results['error_type'] = e.type.toString();

        if (e.response != null) {
          print('   Response Status: ${e.response?.statusCode}');
          print('   Response Data: ${e.response?.data}');
        }
      }
    }

    // Summary
    print('\n📊 ========== DIAGNOSTICS SUMMARY ==========');
    print('Dio Created: ${results['dio_created']}');
    print('Health Check: ${results['health_check']}');
    print('CORS Preflight: ${results['cors_preflight']}');
    print('Login Test: ${results['login_test']}');
    print('==========================================\n');

    return results;
  }
}
