import 'dart:developer' as developer;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'dart:convert';

class AuthService {
  final ApiService _apiService = ApiService();

  // Register
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    String role = 'customer',
  }) async {
    try {
      developer.log('Attempting user registration', name: 'AuthService');
      developer.log(
          'Registration data: firstName=$firstName, lastName=$lastName, email=$email, role=$role',
          name: 'AuthService');

      final response = await _apiService.post('/auth/register', data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      });

      developer.log('Registration response status: ${response.statusCode}',
          name: 'AuthService');
      developer.log('Registration response data: ${response.data}',
          name: 'AuthService');

      if (response.statusCode == 201 && response.data['success'] == true) {
        final userData = response.data['data']['user'];
        final accessToken = response.data['data']['accessToken'];
        final refreshToken = response.data['data']['refreshToken'];

        final user = User.fromJson(userData);
        await _saveTokens(accessToken, refreshToken);
        await _saveUser(user);

        developer.log('User registration successful', name: 'AuthService');
        developer.log('Registered user role: ${user.role}',
            name: 'AuthService');
        return {'success': true, 'user': user};
      } else {
        developer.log('Registration failed: ${response.data}',
            name: 'AuthService');
        return {
          'success': false,
          'message': response.data['message'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      developer.log('Registration network error: $e',
          name: 'AuthService', error: e);
      developer.log('Error type: ${e.runtimeType}', name: 'AuthService');
      if (e is DioException) {
        developer.log('Dio error type: ${e.type}', name: 'AuthService');
        developer.log('Dio error message: ${e.message}', name: 'AuthService');
        if (e.response != null) {
          developer.log('Dio response status: ${e.response?.statusCode}',
              name: 'AuthService');
          developer.log('Dio response data: ${e.response?.data}',
              name: 'AuthService');
        }
      }
      return {
        'success': false,
        'message': 'Network error. Please check your connection.'
      };
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? role,
  }) async {
    try {
      developer.log('Attempting user login', name: 'AuthService');
      developer.log('Making login request to /auth/login', name: 'AuthService');
      developer.log('Email: $email', name: 'AuthService');
      final response = await _apiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      developer.log('Login response received: ${response.statusCode}',
          name: 'AuthService');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data']['user'];
        final accessToken = response.data['data']['accessToken'];
        final refreshToken = response.data['data']['refreshToken'];

        final user = User.fromJson(userData);
        await _saveTokens(accessToken, refreshToken);
        await _saveUser(user);

        developer.log('User login successful', name: 'AuthService');
        developer.log('Logged in user role: ${user.role}', name: 'AuthService');
        return {'success': true, 'user': user};
      } else {
        developer.log('Login failed: ${response.data}', name: 'AuthService');
        return {
          'success': false,
          'message': response.data['message'] ?? 'Login failed'
        };
      }
    } catch (e) {
      developer.log('Login network error: $e', name: 'AuthService', error: e);
      return {
        'success': false,
        'message': 'Network error. Please check your connection.'
      };
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout');
    } catch (e) {
      // Continue with local logout even if API call fails
    }
    await _clearStorage();
  }

  // Refresh Token
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(AppConfig.keyRefreshToken);

      if (refreshToken == null) {
        return {'success': false, 'message': 'No refresh token available'};
      }

      developer.log('Refreshing access token', name: 'AuthService');
      final response = await _apiService.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final accessToken = response.data['data']['accessToken'];
        await _saveTokens(accessToken,
            accessToken); // Note: refresh endpoint only returns new access token

        developer.log('Token refresh successful', name: 'AuthService');
        return {'success': true, 'accessToken': accessToken};
      } else {
        developer.log('Token refresh failed: ${response.data}',
            name: 'AuthService');
        return {'success': false, 'message': 'Token refresh failed'};
      }
    } catch (e) {
      developer.log('Token refresh error: $e', name: 'AuthService', error: e);
      return {'success': false, 'message': 'Failed to refresh token'};
    }
  }

  // Forgot Password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      developer.log('Requesting password reset for: $email',
          name: 'AuthService');
      final response = await _apiService.post('/auth/forgot-password', data: {
        'email': email,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        developer.log('Password reset email sent', name: 'AuthService');
        return {'success': true, 'message': response.data['message']};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to send reset email'
        };
      }
    } catch (e) {
      developer.log('Forgot password error: $e', name: 'AuthService', error: e);
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Reset Password
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      developer.log('Resetting password with token', name: 'AuthService');
      final response = await _apiService.post('/auth/reset-password', data: {
        'token': token,
        'newPassword': newPassword,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        developer.log('Password reset successful', name: 'AuthService');
        return {'success': true, 'message': response.data['message']};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to reset password'
        };
      }
    } catch (e) {
      developer.log('Reset password error: $e', name: 'AuthService', error: e);
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Update Password (when user is logged in)
  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      developer.log('Updating password', name: 'AuthService');
      final response = await _apiService.put('/auth/update-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Update tokens if provided
        if (response.data['data']?.containsKey('accessToken') == true) {
          final accessToken = response.data['data']['accessToken'];
          final refreshToken = response.data['data']['refreshToken'];
          await _saveTokens(accessToken, refreshToken);
        }

        developer.log('Password update successful', name: 'AuthService');
        return {'success': true, 'message': response.data['message']};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to update password'
        };
      }
    } catch (e) {
      developer.log('Update password error: $e', name: 'AuthService', error: e);
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiService.get('/auth/me');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data'];
        final user = User.fromJson(userData);

        // Update stored user data
        await _saveUser(user);
        return user;
      }
    } catch (e) {
      // If API call fails, try to get from local storage
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConfig.keyUser);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(AppConfig.keyAccessToken);
  }

  // Get stored access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.keyAccessToken);
  }

  // Get stored refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.keyRefreshToken);
  }

  // Save tokens
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.keyAccessToken, accessToken);
    await prefs.setString(AppConfig.keyRefreshToken, refreshToken);
  }

  // Save user
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.keyUser, jsonEncode(user.toJson()));
  }

  // Upload Profile Image
  Future<Map<String, dynamic>> uploadProfileImage(dynamic imageFile) async {
    try {
      developer.log('Uploading profile image', name: 'AuthService');

      String filePath;
      if (imageFile is String) {
        filePath = imageFile;
      } else if (imageFile is File) {
        filePath = imageFile.path;
      } else {
        return {'success': false, 'message': 'Invalid image file type'};
      }

      // FIX: Use correct backend endpoint
      final response = await _apiService.uploadFile(
        '/users/profile/image', // Changed from /auth/upload-profile-image
        filePath,
        fieldName: 'profileImage',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Backend returns profileImage in data, not data.user
        final profileImageUrl = response.data['data']['profileImage'];

        // Get updated user data
        final currentUser = await getCurrentUser();

        if (currentUser != null) {
          developer.log('Profile image upload successful', name: 'AuthService');
          return {
            'success': true,
            'user': currentUser,
            'profileImage': profileImageUrl
          };
        } else {
          return {'success': true, 'profileImage': profileImageUrl};
        }
      } else {
        return {
          'success': false,
          'message':
              response.data['message'] ?? 'Failed to upload profile image'
        };
      }
    } catch (e) {
      developer.log('Profile image upload error: $e',
          name: 'AuthService', error: e);
      return {'success': false, 'message': 'Network error occurred: $e'};
    }
  }

  // Update Profile
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      developer.log('Updating user profile', name: 'AuthService');

      // Split name into first and last name
      final nameParts = name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final response = await _apiService.put('/users/profile', data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data']['user'];
        final user = User.fromJson(userData);
        await _saveUser(user);

        developer.log('Profile update successful', name: 'AuthService');
        return {'success': true, 'user': user};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to update profile'
        };
      }
    } catch (e) {
      developer.log('Profile update error: $e', name: 'AuthService', error: e);
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Clear storage
  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.keyAccessToken);
    await prefs.remove(AppConfig.keyRefreshToken);
    await prefs.remove(AppConfig.keyUser);
  }
}
