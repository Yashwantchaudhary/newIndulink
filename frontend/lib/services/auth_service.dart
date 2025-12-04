import '../core/constants/app_config.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// 🔐 Authentication Service
/// Handles user authentication, registration, and session management
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  // ==================== Login Methods ====================

  /// Login with email and password
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final response = await _api.post(
        AppConfig.loginEndpoint,
        body: {
          'email': email,
          'password': password,
        },
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        return await _handleAuthSuccess(response.data);
      } else {
        return AuthResult(
          success: false,
          message: response.message ?? 'Login failed',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An error occurred during login',
      );
    }
  }


  // ==================== Registration ====================

  /// Register new user
  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? businessName,
    String? businessDescription,
  }) async {
    try {
      final body = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role.value,
      };

      // Add supplier-specific fields
      if (role == UserRole.supplier) {
        if (businessName != null) body['businessName'] = businessName;
        if (businessDescription != null) {
          body['businessDescription'] = businessDescription;
        }
      }

      final response = await _api.post(
        AppConfig.registerEndpoint,
        body: body,
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        return await _handleAuthSuccess(response.data);
      } else {
        return AuthResult(
          success: false,
          message: response.message ?? 'Registration failed',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An error occurred during registration',
      );
    }
  }

  // ==================== Token Management ====================

  /// Refresh access token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();

      if (refreshToken == null) {
        return false;
      }

      final response = await _api.post(
        AppConfig.refreshTokenEndpoint,
        body: {'refreshToken': refreshToken},
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        final responseData = data['data'] ?? data;
        final newAccessToken = responseData['accessToken'] ?? responseData['token'];
        final newRefreshToken = responseData['refreshToken'];

        if (newAccessToken != null) {
          await _storage.saveAccessToken(newAccessToken);
          if (newRefreshToken != null) {
            await _storage.saveRefreshToken(newRefreshToken);
          }
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Get current user from storage
  Future<User?> getCurrentUser() async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null) return null;

      // Fetch user from backend
      final response = await _api.get(AppConfig.userProfileEndpoint);

      if (response.isSuccess && response.data != null) {
        return User.fromJson(response.data);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== Logout ====================

  /// Logout user
  Future<void> logout() async {
    try {
      // Call logout endpoint (optional)
      await _api.post(AppConfig.logoutEndpoint);
    } catch (e) {
      // Continue with logout even if API call fails
    }


    // Clear local storage
    await _storage.clearUserData();
  }

  // ==================== Password Management ====================

  /// Request password reset
  Future<AuthResult> forgotPassword(String email) async {
    try {
      final response = await _api.post(
        AppConfig.forgotPasswordEndpoint,
        body: {'email': email},
        requiresAuth: false,
      );

      return AuthResult(
        success: response.isSuccess,
        message: response.message ??
            (response.isSuccess
                ? 'Password reset email sent'
                : 'Failed to send reset email'),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  /// Reset password with token
  Future<AuthResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _api.post(
        AppConfig.resetPasswordEndpoint,
        body: {
          'token': token,
          'newPassword': newPassword,
        },
        requiresAuth: false,
      );

      return AuthResult(
        success: response.isSuccess,
        message: response.message ??
            (response.isSuccess
                ? 'Password reset successful'
                : 'Failed to reset password'),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  /// Change password (authenticated)
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _api.post(
        AppConfig.changePasswordEndpoint,
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      return AuthResult(
        success: response.isSuccess,
        message: response.message ??
            (response.isSuccess
                ? 'Password changed successfully'
                : 'Failed to change password'),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  /// Delete user account
  Future<AuthResult> deleteAccount({required String password}) async {
    try {
      final response = await _api.post(
        AppConfig.deleteAccountEndpoint,
        body: {'password': password},
      );

      if (response.isSuccess) {
        // Clear local storage after successful deletion
        await _storage.clearUserData();
      }

      return AuthResult(
        success: response.isSuccess,
        message: response.message ??
            (response.isSuccess
                ? 'Account deleted successfully'
                : 'Failed to delete account'),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An error occurred',
      );
    }
  }

  // ==================== Helper Methods ====================

  /// Handle successful authentication response
  Future<AuthResult> _handleAuthSuccess(dynamic data) async {
    try {
      // Extract tokens - handle nested data structure from backend
      final responseData = data['data'] ?? data;
      final accessToken = responseData['accessToken'] ?? responseData['token'];
      final refreshToken = responseData['refreshToken'];
      final userData = responseData['user'];

      if (accessToken == null || userData == null) {
        return AuthResult(
          success: false,
          message: 'Invalid response from server',
        );
      }

      // Save tokens
      await _storage.saveAccessToken(accessToken);
      if (refreshToken != null) {
        await _storage.saveRefreshToken(refreshToken);
      }

      // Parse and save user data
      final user = User.fromJson(userData);
      await _storage.saveUserId(user.id);
      await _storage.saveUserRole(user.role.value);
      await _storage.saveUserEmail(user.email);
      await _storage.saveUserName(user.fullName);

      return AuthResult(
        success: true,
        message: 'Authentication successful',
        user: user,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to process authentication response: $e',
      );
    }
  }
}

/// 📋 Authentication Result Model
class AuthResult {
  final bool success;
  final String message;
  final User? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}
