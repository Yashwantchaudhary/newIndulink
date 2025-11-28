import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

part 'language_provider.g.dart';

class LanguageState {
  final Locale locale;

  LanguageState({required this.locale});

  LanguageState copyWith({Locale? locale}) {
    return LanguageState(locale: locale ?? this.locale);
  }
}

@riverpod
class LanguageNotifier extends _$LanguageNotifier {
  static const String _languageKey = 'selected_language';

  Locale _detectSystemLanguage() {
    // Get system locales
    final systemLocales = ui.window.locales;

    // Try to find a supported locale that matches system preferences
    for (final systemLocale in systemLocales) {
      // Check exact match first
      if (AppLocalizations.supportedLocales.contains(systemLocale)) {
        return systemLocale;
      }

      // Check language code match (ignoring country)
      final matchingLocale = AppLocalizations.supportedLocales.firstWhere(
        (supportedLocale) =>
            supportedLocale.languageCode == systemLocale.languageCode,
        orElse: () => const Locale('en'),
      );

      if (matchingLocale.languageCode != 'en') {
        return matchingLocale;
      }
    }

    // Default fallback
    return const Locale('en');
  }

  @override
  Future<LanguageState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);

    if (languageCode != null) {
      final locale = Locale(languageCode);
      if (AppLocalizations.supportedLocales.contains(locale)) {
        return LanguageState(locale: locale);
      }
    }

    // Auto-detect system language if no saved preference
    final detectedLocale = _detectSystemLanguage();
    return LanguageState(locale: detectedLocale);
  }

  Future<void> _saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  Future<void> changeLanguage(Locale locale) async {
    if (AppLocalizations.supportedLocales.contains(locale)) {
      state = AsyncData(LanguageState(locale: locale));
      await _saveLanguage(locale.languageCode);

      // Update API service language header
      try {
        final apiService = ApiService();
        apiService.setLanguage(locale.languageCode);
      } catch (e) {
        print('LanguageProvider: Could not update API service language: $e');
      }
    }
  }

  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'hi':
        return 'हिन्दी';
      case 'ne':
        return 'नेपाली';
      case 'bn':
        return 'বাংলা';
      case 'ta':
        return 'தமிழ்';
      case 'te':
        return 'తెలుగు';
      case 'ml':
        return 'മലയാളം';
      case 'ur':
        return 'اردو';
      case 'ar':
        return 'العربية';
      default:
        return languageCode.toUpperCase();
    }
  }

  String getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇺🇸';
      case 'es':
        return '🇪🇸';
      case 'hi':
        return '🇮🇳';
      case 'ne':
        return '🇳🇵';
      case 'bn':
        return '🇧🇩';
      case 'ta':
        return '🇮🇳';
      case 'te':
        return '🇮🇳';
      case 'ml':
        return '🇮🇳';
      case 'ur':
        return '🇵🇰';
      case 'ar':
        return '🇸🇦';
      default:
        return '🌍';
    }
  }
}
