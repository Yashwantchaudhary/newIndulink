import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/constants/app_config.dart';

/// 💾 Storage Service
/// Local data persistence using SharedPreferences
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure preferences are initialized
  Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // ==================== Token Management ====================

  /// Save access token
  Future<bool> saveAccessToken(String token) async {
    final prefs = await _preferences;
    return await prefs.setString(StorageKeys.accessToken, token);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.accessToken);
  }

  /// Save refresh token
  Future<bool> saveRefreshToken(String token) async {
    final prefs = await _preferences;
    return await prefs.setString(StorageKeys.refreshToken, token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.refreshToken);
  }

  /// Remove tokens (logout)
  Future<bool> removeTokens() async {
    final prefs = await _preferences;
    await prefs.remove(StorageKeys.accessToken);
    await prefs.remove(StorageKeys.refreshToken);
    return true;
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ==================== User Data ====================

  /// Save user ID
  Future<bool> saveUserId(String userId) async {
    final prefs = await _preferences;
    return await prefs.setString(StorageKeys.userId, userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.userId);
  }

  /// Save user role
  Future<bool> saveUserRole(String role) async {
    final prefs = await _preferences;
    return await prefs.setString(StorageKeys.userRole, role);
  }

  /// Get user role
  Future<String?> getUserRole() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.userRole);
  }

  /// Save user email
  Future<bool> saveUserEmail(String email) async {
    final prefs = await _preferences;
    return await prefs.setString(StorageKeys.userEmail, email);
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.userEmail);
  }

  /// Save user name
  Future<bool> saveUserName(String name) async {
    final prefs = await _preferences;
    return await prefs.setString(StorageKeys.userName, name);
  }

  /// Get user name
  Future<String?> getUserName() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.userName);
  }

  /// Clear all user data
  Future<void> clearUserData() async {
    final prefs = await _preferences;
    await prefs.remove(StorageKeys.userId);
    await prefs.remove(StorageKeys.userRole);
    await prefs.remove(StorageKeys.userEmail);
    await prefs.remove(StorageKeys.userName);
    await removeTokens();
  }

  // ==================== Cart Management ====================

  /// Save cart items (as JSON string)
  Future<bool> saveCartItems(List<Map<String, dynamic>> items) async {
    final prefs = await _preferences;
    final jsonString = jsonEncode(items);
    return await prefs.setString(StorageKeys.cartItems, jsonString);
  }

  /// Get cart items
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final prefs = await _preferences;
    final jsonString = prefs.getString(StorageKeys.cartItems);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Clear cart
  Future<bool> clearCart() async {
    final prefs = await _preferences;
    return await prefs.remove(StorageKeys.cartItems);
  }

  // ==================== Search History ====================

  /// Save search history
  Future<bool> saveSearchHistory(List<String> searches) async {
    final prefs = await _preferences;
    return await prefs.setStringList(StorageKeys.searchHistory, searches);
  }

  /// Get search history
  Future<List<String>> getSearchHistory() async {
    final prefs = await _preferences;
    return prefs.getStringList(StorageKeys.searchHistory) ?? [];
  }

  /// Add search query to history
  Future<bool> addSearchQuery(String query) async {
    final history = await getSearchHistory();

    // Remove if already exists (to move to top)
    history.remove(query);

    // Add to beginning
    history.insert(0, query);

    // Keep only last 10 searches
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }

    return await saveSearchHistory(history);
  }

  /// Clear search history
  Future<bool> clearSearchHistory() async {
    final prefs = await _preferences;
    return await prefs.remove(StorageKeys.searchHistory);
  }

  /// Save recent searches (alias for saveSearchHistory)
  Future<bool> saveRecentSearches(List<String> searches) async {
    return await saveSearchHistory(searches);
  }

  /// Get recent searches (alias for getSearchHistory)
  Future<List<String>> getRecentSearches() async {
    return await getSearchHistory();
  }

  /// Clear recent searches (alias for clearSearchHistory)
  Future<bool> clearRecentSearches() async {
    return await clearSearchHistory();
  }

  // ==================== Recently Viewed ====================

  /// Save recently viewed product IDs
  Future<bool> saveRecentlyViewed(List<String> productIds) async {
    final prefs = await _preferences;
    return await prefs.setStringList(StorageKeys.recentlyViewed, productIds);
  }

  /// Get recently viewed product IDs
  Future<List<String>> getRecentlyViewed() async {
    final prefs = await _preferences;
    return prefs.getStringList(StorageKeys.recentlyViewed) ?? [];
  }

  /// Add product to recently viewed
  Future<bool> addRecentlyViewed(String productId) async {
    final viewed = await getRecentlyViewed();

    // Remove if already exists
    viewed.remove(productId);

    // Add to beginning
    viewed.insert(0, productId);

    // Keep only last 20 products
    if (viewed.length > 20) {
      viewed.removeRange(20, viewed.length);
    }

    return await saveRecentlyViewed(viewed);
  }

  // ==================== App Settings ====================

  /// Save theme mode
  Future<bool> saveThemeMode(String mode) async {
    final prefs = await _preferences;
    return await prefs.setString(StorageKeys.themeMode, mode);
  }

  /// Get theme mode
  Future<String?> getThemeMode() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.themeMode);
  }

  /// Save language code
  Future<bool> saveLanguageCode(String code) async {
    final prefs = await _preferences;
    return await prefs.setString(StorageKeys.languageCode, code);
  }

  /// Get language code
  Future<String?> getLanguageCode() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.languageCode);
  }

  /// Mark onboarding as complete
  Future<bool> setOnboardingComplete(bool complete) async {
    final prefs = await _preferences;
    return await prefs.setBool(StorageKeys.onboardingComplete, complete);
  }

  /// Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    final prefs = await _preferences;
    return prefs.getBool(StorageKeys.onboardingComplete) ?? false;
  }

  // ==================== FCM Token ====================

  /// Save FCM token
  Future<bool> saveFcmToken(String token) async {
    final prefs = await _preferences;
    return await prefs.setString(StorageKeys.fcmToken, token);
  }

  /// Get FCM token
  Future<String?> getFcmToken() async {
    final prefs = await _preferences;
    return prefs.getString(StorageKeys.fcmToken);
  }

  // ==================== Generic Methods ====================

  /// Save string value
  Future<bool> saveString(String key, String value) async {
    final prefs = await _preferences;
    return await prefs.setString(key, value);
  }

  /// Get string value
  Future<String?> getString(String key) async {
    final prefs = await _preferences;
    return prefs.getString(key);
  }

  /// Save int value
  Future<bool> saveInt(String key, int value) async {
    final prefs = await _preferences;
    return await prefs.setInt(key, value);
  }

  /// Get int value
  Future<int?> getInt(String key) async {
    final prefs = await _preferences;
    return prefs.getInt(key);
  }

  /// Save bool value
  Future<bool> saveBool(String key, bool value) async {
    final prefs = await _preferences;
    return await prefs.setBool(key, value);
  }

  /// Get bool value
  Future<bool?> getBool(String key) async {
    final prefs = await _preferences;
    return prefs.getBool(key);
  }

  /// Remove value
  Future<bool> remove(String key) async {
    final prefs = await _preferences;
    return await prefs.remove(key);
  }

  /// Clear all data
  Future<bool> clearAll() async {
    final prefs = await _preferences;
    return await prefs.clear();
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    final prefs = await _preferences;
    return prefs.containsKey(key);
  }
}
