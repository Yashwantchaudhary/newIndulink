import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbK-jEAup1qKGQgltq0d-EDqVwSElKEKc',
    appId: '1:244885905510:android:ce7afa402f2705154a0da7',
    messagingSenderId: '244885905510',
    projectId: 'indulink-b0306',
    storageBucket: 'indulink-b0306.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAUOsqAjjeK_9TrO2HGdLq5xUdEzVirKm4',
    appId: '1:584595950464:ios:5e76bf06b1210ce781cf65',
    messagingSenderId: '584595950464',
    projectId: 'hostel-finder-3580f',
    storageBucket: 'hostel-finder-3580f.firebasestorage.app',
    iosBundleId: 'com.hostelfinder.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAUOsqAjjeK_9TrO2HGdLq5xUdEzVirKm4',
    appId: '1:584595950464:web:5e76bf06b1210ce781cf65',
    messagingSenderId: '584595950464',
    projectId: 'hostel-finder-3580f',
    storageBucket: 'hostel-finder-3580f.firebasestorage.app',
    authDomain: 'hostel-finder-3580f.firebaseapp.com',
  );
}