import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// 🎨 Theme Provider
/// Manages app theme mode (light/dark/system)
class ThemeProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();

  // State
  ThemeMode _themeMode = ThemeMode.system;

  // Getter
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Initialize theme from storage
  Future<void> init() async {
    await loadTheme();
  }

  /// Load saved theme preference
  Future<void> loadTheme() async {
    try {
      final savedTheme = await _storageService.getThemeMode();
      _themeMode = _parseThemeMode(savedTheme);
      notifyListeners();
    } catch (e) {
      // Default to system theme on error
      _themeMode = ThemeMode.system;
    }
  }

  /// Set theme mode
  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    await _storageService.saveThemeMode(_themeToString(mode));
    notifyListeners();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setTheme(ThemeMode.dark);
    } else {
      await setTheme(ThemeMode.light);
    }
  }

  /// Set light theme
  Future<void> setLightTheme() async {
    await setTheme(ThemeMode.light);
  }

  /// Set dark theme
  Future<void> setDarkTheme() async {
    await setTheme(ThemeMode.dark);
  }

  /// Set system theme
  Future<void> setSystemTheme() async {
    await setTheme(ThemeMode.system);
  }

  // Helper methods
  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  String _themeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
