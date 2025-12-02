import 'package:flutter/material.dart';

/// 🎨 Theme Provider
/// Manages application theme mode (light/dark/system)
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Set theme mode
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

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
}
