import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String role,
  }) async {
    try {
      final firebase_auth.UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      final user = User(
        id: userCredential.user!.uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        role: role,
        profileImage: null,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _createUserProfile(user);

      return {
        'success': true,
        'user': user,
        'firebaseUser': userCredential.user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': _getFirebaseErrorMessage(e),
      };
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmail(
      String email, String password) async {
    try {
      final firebase_auth.UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user profile from Firestore
      final user = await _getUserProfile(userCredential.user!.uid);

      if (user == null) {
        return {
          'success': false,
          'message': 'User profile not found. Please contact support.',
        };
      }

      return {
        'success': true,
        'user': user,
        'firebaseUser': userCredential.user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': _getFirebaseErrorMessage(e),
      };
    }
  }

  // Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle({String? role}) async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Google sign in was cancelled by user',
          'errorCode': 'cancelled',
        };
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Validate that we have the required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return {
          'success': false,
          'message': 'Failed to obtain authentication tokens from Google',
          'errorCode': 'missing_tokens',
        };
      }

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final firebase_auth.UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Check if user profile exists
      User? user = await _getUserProfile(userCredential.user!.uid);

      if (user == null) {
        // Create new user profile for Google sign in
        final displayName = userCredential.user!.displayName ?? '';
        final nameParts = displayName.split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
        final lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        user = User(
          id: userCredential.user!.uid,
          firstName: firstName,
          lastName: lastName,
          email: userCredential.user!.email ?? '',
          phone: userCredential.user!.phoneNumber ?? '',
          role: role ?? 'customer', // Use provided role or default to customer
          profileImage: userCredential.user!.photoURL,
          createdAt: DateTime.now(),
          isActive: true,
        );

        await _createUserProfile(user);
      }

      return {
        'success': true,
        'user': user,
        'firebaseUser': userCredential.user,
      };
    } catch (e) {
      // Handle specific Firebase Auth exceptions
      if (e is firebase_auth.FirebaseAuthException) {
        String errorMessage;
        String errorCode = e.code;

        switch (e.code) {
          case 'account-exists-with-different-credential':
            errorMessage =
                'An account already exists with the same email address but different sign-in credentials. Try signing in with a different method.';
            break;
          case 'invalid-credential':
            errorMessage =
                'The authentication credential is invalid or has expired.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Google sign-in is not enabled for this project.';
            break;
          case 'user-disabled':
            errorMessage = 'This user account has been disabled.';
            break;
          case 'user-not-found':
            errorMessage = 'No user found with this Google account.';
            break;
          case 'wrong-password':
            errorMessage = 'Invalid credentials provided.';
            break;
          case 'network-request-failed':
            errorMessage =
                'Network error occurred. Please check your internet connection.';
            break;
          case 'popup-closed-by-user':
            errorMessage =
                'Google sign-in popup was closed before completing authentication.';
            break;
          case 'popup-blocked':
            errorMessage =
                'Google sign-in popup was blocked by your browser. Please allow popups for this site.';
            break;
          default:
            errorMessage =
                'Google sign-in failed: ${e.message ?? 'Unknown error'}';
        }

        return {
          'success': false,
          'message': errorMessage,
          'errorCode': errorCode,
        };
      }

      // Handle other exceptions
      return {
        'success': false,
        'message':
            'An unexpected error occurred during Google sign-in: ${e.toString()}',
        'errorCode': 'unknown_error',
      };
    }
  }

  // Get user profile from Firestore
  Future<User?> _getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return User.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Get user by ID
  Future<User?> getUserById(String uid) async {
    return _getUserProfile(uid);
  }

  // Stream of user profile changes
  Stream<User?> getUserProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return User.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    });
  }

  // Helper method to get readable error messages
  String _getFirebaseErrorMessage(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        default:
          return 'Authentication error: ${error.message}';
      }
    }
    return 'An unexpected error occurred.';
  }
}
