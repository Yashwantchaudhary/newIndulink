import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  // API Configuration - Production URL
  static String get apiBaseUrl {
    // Production backend hosted on Render
    return 'https://indulink-1.onrender.com/api';
  }

  // API URL is now configured for production:
  // - All platforms: https://indulink-1.onrender.com/api
  // Backend is hosted on Render

  // Debug method to check current API URL
  static void printCurrentApiUrl() {
    // Only print in debug mode
    assert(() {
      print('🔗 Current API Base URL: $apiBaseUrl');
      print('🌐 Platform: ${kIsWeb ? 'Web' : Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Other'}');
      return true;
    }());
  }

  // Test connection to backend
  static Future<bool> testConnection() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      // Health endpoint is at root level, not under /api
      final baseUrl = apiBaseUrl.replaceAll('/api', '');
      final uri = Uri.parse('$baseUrl/health');
      assert(() {
        print('🔍 Testing connection to: $uri');
        return true;
      }());

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        assert(() {
          print('✅ Backend connection successful: ${response.statusCode}');
          return true;
        }());
        return true;
      } else {
        assert(() {
          print('❌ Backend responded with status: ${response.statusCode}');
          return true;
        }());
        return false;
      }
    } catch (e) {
      assert(() {
        print('❌ Connection failed: $e');
        print('💡 Troubleshooting steps:');
        print('   1. Check if production backend is running: https://indulink-1.onrender.com/health');
        print('   2. Verify internet connection');
        print('   3. Check if Render service is active');
        return true;
      }());
      return false;
    }
  }
  
  static const String apiVersion = 'v1';
  
  // App Configuration
  static const String appName = 'Indulink';
  static const int defaultPageSize = 20;
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUser = 'user';
  static const String keyOnboardingCompleted = 'onboarding_completed';
}
