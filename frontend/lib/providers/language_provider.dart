import 'package:flutter/foundation.dart';

/// 🌐 Language Provider
/// Manages app localization and language preferences
class LanguageProvider with ChangeNotifier {
  // Currently supported languages
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'en', name: 'English', nativeName: 'English'),
    LanguageOption(code: 'ne', name: 'Nepali', nativeName: 'नेपाली'),
  ];

  // State
  String _languageCode = 'en'; // Default to English

  // Getter
  String get languageCode => _languageCode;
  LanguageOption get currentLanguage => supportedLanguages.firstWhere(
        (lang) => lang.code == _languageCode,
        orElse: () => supportedLanguages.first,
      );

  /// Initialize language from storage
  Future<void> init() async {
    // For now, default to English
    // TODO: Load from storage when implemented
    _languageCode = 'en';
    notifyListeners();
  }

  /// Change language
  Future<void> changeLanguage(String code) async {
    if (!supportedLanguages.any((lang) => lang.code == code)) {
      debugPrint('Unsupported language code: $code');
      return;
    }

    _languageCode = code;
    // TODO: Save to storage
    notifyListeners();
  }

  /// Get available languages
  List<LanguageOption> getAvailableLanguages() {
    return supportedLanguages;
  }
}

/// Language option model
class LanguageOption {
  final String code;
  final String name;
  final String nativeName;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}
