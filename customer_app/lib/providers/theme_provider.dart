import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode state management
class ThemeState {
  final ThemeMode themeMode;
  final bool isLoading;

  ThemeState({
    required this.themeMode,
    this.isLoading = false,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isLoading,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Theme provider using StateNotifier
class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeKey = 'theme_mode';

  ThemeNotifier() : super(ThemeState(themeMode: ThemeMode.system)) {
    _loadTheme();
  }

  /// Load saved theme from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeKey);

      if (themeModeString != null) {
        final themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
        state = state.copyWith(themeMode: themeMode);
      }
    } catch (e) {
      // If error, keep system default
      state = state.copyWith(themeMode: ThemeMode.system);
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.toString());
      state = state.copyWith(themeMode: mode, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Toggle between light and dark
  Future<void> toggleTheme() async {
    final newMode =
        state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Get current theme mode
  ThemeMode get currentThemeMode => state.themeMode;

  /// Check if dark mode is enabled
  bool get isDarkMode => state.themeMode == ThemeMode.dark;

  /// Check if light mode is enabled
  bool get isLightMode => state.themeMode == ThemeMode.light;

  /// Check if system mode is enabled
  bool get isSystemMode => state.themeMode == ThemeMode.system;
}

/// Provider for theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Convenient provider for just the ThemeMode
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider).themeMode;
});
