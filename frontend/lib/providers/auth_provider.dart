import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// 🔐 Authentication Provider
/// Manages global authentication state using Provider
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();

  // State
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isCustomer => _user?.role == UserRole.customer;
  bool get isSupplier => _user?.role == UserRole.supplier;
  bool get isAdmin => _user?.role == UserRole.admin;

  /// Initialize auth state on app start
  Future<void> init() async {
    _setLoading(true);

    try {
      final isLoggedIn = await _storage.isLoggedIn();

      if (isLoggedIn) {
        // Try to fetch current user
        final user = await _authService.getCurrentUser();

        if (user != null) {
          _user = user;
          _isAuthenticated = true;
        } else {
          // Token might be invalid, try refresh
          final refreshed = await _authService.refreshToken();

          if (refreshed) {
            final refreshedUser = await _authService.getCurrentUser();
            if (refreshedUser != null) {
              _user = refreshedUser;
              _isAuthenticated = true;
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

  /// Login with Google
  Future<bool> loginWithGoogle({required UserRole role}) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.loginWithGoogle(role: role);

      if (result.success && result.user != null) {
        _user = result.user;
        _isAuthenticated = true;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Google Sign-In failed');
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
      // TODO: Call update profile API
      // For now, just update local state
      _user = updatedUser;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile');
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
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.forgotPassword(email);

      if (result.success) {
        _setLoading(false);
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to send reset email');
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
    notifyListeners();
  }
}
