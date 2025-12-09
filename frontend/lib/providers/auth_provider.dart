import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';
import '../services/image_service.dart';
import '../core/constants/app_config.dart';

/// 🔐 Authentication Provider
/// Manages global authentication state using Provider
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();
  final SocketService _socketService = SocketService();

  // State
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isCustomer => _user?.role == UserRole.customer;
  bool get isSupplier => _user?.role == UserRole.supplier;
  bool get isAdmin => _user?.role == UserRole.admin;

  /// Get access token
  Future<String?> getToken() async {
    return await _storage.getAccessToken();
  }

  /// Initialize auth state on app start
  Future<void> init() async {
    if (_isInitialized) return;
    _setLoading(true);

    try {
      final isLoggedIn = await _storage.isLoggedIn();

      if (isLoggedIn) {
        // Try to fetch current user
        final user = await _authService.getCurrentUser();

        if (user != null) {
          _user = user;
          _isAuthenticated = true;
          // Connect socket
          final token = await getToken();
          if (token != null)
            _socketService.connect(token, _user!.id, _user!.role.value);
        } else {
          // Token might be invalid, try refresh
          final refreshed = await _authService.refreshToken();

          if (refreshed) {
            final refreshedUser = await _authService.getCurrentUser();
            if (refreshedUser != null) {
              _user = refreshedUser;
              _isAuthenticated = true;
              // Connect socket
              final token = await getToken();
              if (token != null)
                _socketService.connect(token, _user!.id, _user!.role.value);
            } else {
              await _clearAuthState();
            }
          } else {
            await _clearAuthState();
          }
        }
      }
    } catch (e) {
      await _clearAuthState();
    }

    _setLoading(false);
  }

  /// Refresh user profile data from server
  Future<void> refreshProfile() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _user = user;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to refresh profile: $e');
    }
  }

  /// Login with email and password
  Future<bool> loginWithEmail({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.loginWithEmail(
        email: email,
        password: password,
        role: role,
      );

      if (result.success && result.user != null) {
        _user = result.user;
        _isAuthenticated = true;
        // Connect socket
        final token = await getToken();
        if (token != null)
          _socketService.connect(token, _user!.id, _user!.role.value);

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? businessName,
    String? businessDescription,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
        role: role,
        businessName: businessName,
        businessDescription: businessDescription,
      );

      if (result.success && result.user != null) {
        _user = result.user;
        _isAuthenticated = true;
        // Connect socket
        final token = await getToken();
        if (token != null)
          _socketService.connect(token, _user!.id, _user!.role.value);

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Registration failed');
      _setLoading(false);
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();
      await _clearAuthState();
    } catch (e) {
      // Force logout even if API call fails
      await _clearAuthState();
    }

    _setLoading(false);
    _isInitialized = true;
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _user = user;
        notifyListeners();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Update user profile
  Future<bool> updateProfile(User updatedUser) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.updateProfile(updatedUser.toJson());

      if (result.success && result.user != null) {
        _user = result.user;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to update profile');
      _setLoading(false);
      return false;
    }
  }

  /// Upload and update profile image
  Future<bool> uploadProfileImage(XFile imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      final imageService = ImageService();
      final imageUrl = await imageService.uploadProfileImage(imageFile);

      if (imageUrl != null && _user != null) {
        // Update local user with new profile image
        // Use serverUrl (not baseUrl) because static files are served at root, not under /api
        _user =
            _user!.copyWith(profileImage: '${AppConfig.serverUrl}$imageUrl');
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('Failed to upload profile image');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error uploading profile image: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (result.success) {
        _setLoading(false);
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to change password');
      _setLoading(false);
      return false;
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(
    String email, {
    String? oldPassword,
    String? newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.forgotPassword(
        email,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      if (result.success) {
        _setLoading(false);
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to reset password');
      _setLoading(false);
      return false;
    }
  }

  /// Delete account
  Future<bool> deleteAccount({required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.deleteAccount(password: password);

      if (result.success) {
        await _clearAuthState();
        _setLoading(false);
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete account');
      _setLoading(false);
      return false;
    }
  }

  // ==================== Helper Methods ====================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _clearAuthState() async {
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    await _storage.clearUserData();
    _socketService.disconnect(); // Disconnect socket
    notifyListeners();
  }
}
