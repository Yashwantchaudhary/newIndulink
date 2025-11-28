import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/firebase_messaging_service.dart';
import '../services/fcm_service.dart';

class FirebaseConfig {
  // Common Firebase configuration for Indulink
  static const String apiKey = 'AIzaSyAbK-jEAup1qKGQgltq0d-EDqVwSElKEKc';
  static const String projectId = 'indulink-b0306';
  static const String messagingSenderId = '244885905510';

  // Platform-specific configurations
  static const String androidAppId =
      '1:244885905510:android:ce7afa402f2705154a0da7';
  static const String iosAppId =
      '1:244885905510:ios:your-ios-app-id'; // Update with actual iOS app ID
  static const String webAppId =
      androidAppId; // Using Android app ID for web (same project)

  // Web-specific parameters
  static const String authDomain = 'indulink-b0306.firebaseapp.com';
  static const String storageBucket = 'indulink-b0306.firebasestorage.app';

  static FirebaseMessagingService? _messagingService;
  static FCMService? _fcmService;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: _getFirebaseOptions(),
    );

    // Initialize messaging service
    _messagingService = FirebaseMessagingService();
    await _messagingService!.initialize();

    // Initialize FCM service
    _fcmService = FCMService();
    await _fcmService!.initialize();
  }

  static FirebaseOptions _getFirebaseOptions() {
    if (kIsWeb) {
      // Web platform configuration
      return const FirebaseOptions(
        apiKey: apiKey,
        appId: webAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain,
        storageBucket: storageBucket,
      );
    } else if (Platform.isAndroid) {
      // Android platform configuration
      return const FirebaseOptions(
        apiKey: apiKey,
        appId: androidAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
      );
    } else if (Platform.isIOS) {
      // iOS platform configuration
      return const FirebaseOptions(
        apiKey: apiKey,
        appId: iosAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
      );
    } else {
      // Fallback for other platforms
      return const FirebaseOptions(
        apiKey: apiKey,
        appId: androidAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
      );
    }
  }

  static FirebaseMessagingService get messagingService {
    if (_messagingService == null) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _messagingService!;
  }

  static FCMService get fcmService {
    if (_fcmService == null) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _fcmService!;
  }
}
