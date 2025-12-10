import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/config/firebase_config.dart';
import 'package:flutter/foundation.dart';

/// Google Authentication Service
/// Handles Google Sign-In flow and Firebase authentication
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? FirebaseConfig.webClientId : null,
    scopes: ['email', 'profile'],
  );

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Sign in with Google
  /// Returns Firebase ID token on success, null on failure/cancellation
  Future<String?> signInWithGoogle() async {
    try {
      debugPrint('🔐 Starting Google Sign-In flow...');

      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ Google Sign-In cancelled by user');
        return null;
      }

      debugPrint('✅ Google user: ${googleUser.email}');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        debugPrint('❌ No authentication tokens received');
        return null;
      }

      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      // Get Firebase ID token
      final String? firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        debugPrint('❌ Failed to get Firebase ID token');
        return null;
      }

      debugPrint('✅ Firebase ID token obtained');
      debugPrint('   Email: ${userCredential.user?.email}');
      debugPrint('   Email Verified: ${userCredential.user?.emailVerified}');

      return firebaseIdToken;
    } catch (e, stackTrace) {
      debugPrint('❌ Google Sign-In error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _firebaseAuth.signOut(),
      ]);
      debugPrint('✅ Signed out from Google and Firebase');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
    }
  }

  /// Get current Google user
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Check if user is signed in with Google
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Get current Firebase user
  User? get firebaseUser => _firebaseAuth.currentUser;
}
