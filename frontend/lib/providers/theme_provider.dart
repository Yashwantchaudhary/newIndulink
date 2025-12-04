import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// 🎨 Theme Provider
/// Manages application theme mode (light/dark/system)
class ThemeProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Initialize theme provider and load saved preferences
  Future<void> init() async {
    await _loadThemePreference();
  }

  /// Set theme mode
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveThemePreference();
      notifyListeners();
    }
  }

  /// Alias for setThemeMode
  void setTheme(ThemeMode mode) => setThemeMode(mode);

  /// Toggle between light and dark mode
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      // If system, switch to light
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  /// Set to light mode
  void setLightMode() => setThemeMode(ThemeMode.light);

  /// Set to dark mode
  void setDarkMode() => setThemeMode(ThemeMode.dark);

  /// Set to system mode
  void setSystemMode() => setThemeMode(ThemeMode.system);

  /// Load theme preference from storage
  Future<void> _loadThemePreference() async {
    try {
      final savedTheme = await _storage.getThemeMode();
      if (savedTheme != null) {
        if (savedTheme == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (savedTheme == 'light') {
          _themeMode = ThemeMode.light;
        } else if (savedTheme == 'system') {
          _themeMode = ThemeMode.system;
        }
      }
    } catch (e) {
      // If loading fails, keep default theme
      _themeMode = ThemeMode.system;
    }
  }

  /// Save theme preference to storage
  Future<void> _saveThemePreference() async {
    try {
      String themeString;
      if (_themeMode == ThemeMode.dark) {
        themeString = 'dark';
      } else if (_themeMode == ThemeMode.light) {
        themeString = 'light';
      } else {
        themeString = 'system';
      }
      await _storage.saveThemeMode(themeString);
    } catch (e) {
      // Silently fail if saving fails
    }
  }
}
