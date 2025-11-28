import 'package:intl/intl.dart';

/// Cultural Adaptation Utilities
/// Provides culturally appropriate formatting for dates, numbers, and currencies
class CulturalAdaptation {
  static const Map<String, String> _currencySymbols = {
    'en': '\$', // USD
    'es': '€', // EUR (can be customized per region)
    'hi': '₹', // INR
    'ne': 'रु', // NPR
    'bn': '৳', // BDT
    'ta': '₹', // INR
    'te': '₹', // INR
    'ml': '₹', // INR
    'ur': '₨', // PKR
    'ar': 'ر.س', // SAR
  };

  static const Map<String, String> _dateFormats = {
    'en': 'MM/dd/yyyy',
    'es': 'dd/MM/yyyy',
    'hi': 'dd/MM/yyyy',
    'ne': 'yyyy/MM/dd', // Nepali format
    'bn': 'dd/MM/yyyy',
    'ta': 'dd/MM/yyyy',
    'te': 'dd/MM/yyyy',
    'ml': 'dd/MM/yyyy',
    'ur': 'dd/MM/yyyy',
    'ar': 'dd/MM/yyyy',
  };

  static const Map<String, String> _timeFormats = {
    'en': 'hh:mm a',
    'es': 'HH:mm',
    'hi': 'hh:mm a',
    'ne': 'hh:mm a',
    'bn': 'hh:mm a',
    'ta': 'hh:mm a',
    'te': 'hh:mm a',
    'ml': 'hh:mm a',
    'ur': 'hh:mm a',
    'ar': 'HH:mm',
  };

  /// Format currency based on language
  static String formatCurrency(double amount, String languageCode) {
    final symbol = _currencySymbols[languageCode] ?? '\$';
    final formatter = NumberFormat.currency(
      locale: languageCode,
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format date based on language
  static String formatDate(DateTime date, String languageCode) {
    final format = _dateFormats[languageCode] ?? 'MM/dd/yyyy';
    final formatter = DateFormat(format, languageCode);
    return formatter.format(date);
  }

  /// Format time based on language
  static String formatTime(DateTime time, String languageCode) {
    final format = _timeFormats[languageCode] ?? 'hh:mm a';
    final formatter = DateFormat(format, languageCode);
    return formatter.format(time);
  }

  /// Format number based on language
  static String formatNumber(num number, String languageCode) {
    final formatter = NumberFormat.decimalPattern(languageCode);
    return formatter.format(number);
  }

  /// Get culturally appropriate greeting based on time and language
  static String getGreeting(String languageCode) {
    final hour = DateTime.now().hour;

    switch (languageCode) {
      case 'hi':
        if (hour < 12) return 'सुप्रभात'; // Good morning
        if (hour < 17) return 'नमस्ते'; // Good afternoon
        return 'शुभ संध्या'; // Good evening

      case 'ne':
        if (hour < 12) return 'सुप्रभात'; // Good morning
        if (hour < 17) return 'नमस्ते'; // Good afternoon
        return 'शुभ संध्या'; // Good evening

      case 'bn':
        if (hour < 12) return 'সুপ্রভাত'; // Good morning
        if (hour < 17) return 'নমস্কার'; // Good afternoon
        return 'শুভ সন্ধ্যা'; // Good evening

      case 'ta':
        if (hour < 12) return 'காலை வணக்கம்'; // Good morning
        if (hour < 17) return 'மதிய வணக்கம்'; // Good afternoon
        return 'மாலை வணக்கம்'; // Good evening

      case 'te':
        if (hour < 12) return 'శుభోదయం'; // Good morning
        if (hour < 17) return 'నమస్కారం'; // Good afternoon
        return 'శుభ సాయంత్రం'; // Good evening

      case 'ml':
        if (hour < 12) return 'സുപ്രഭാതം'; // Good morning
        if (hour < 17) return 'നമസ്കാരം'; // Good afternoon
        return 'ശുഭ സന്ധ്യ'; // Good evening

      case 'ur':
        if (hour < 12) return 'صبح بخیر'; // Good morning
        if (hour < 17) return 'دوپہر بخیر'; // Good afternoon
        return 'شام بخیر'; // Good evening

      case 'ar':
        if (hour < 12) return 'صباح الخير'; // Good morning
        if (hour < 17) return 'مساء الخير'; // Good afternoon
        return 'مساء الخير'; // Good evening

      case 'es':
        if (hour < 12) return 'Buenos días';
        if (hour < 17) return 'Buenas tardes';
        return 'Buenas noches';

      case 'en':
      default:
        if (hour < 12) return 'Good morning';
        if (hour < 17) return 'Good afternoon';
        return 'Good evening';
    }
  }

  /// Get text direction for the language
  static TextDirection getTextDirection(String languageCode) {
    return ['ar', 'ur'].contains(languageCode)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  /// Check if language uses RTL text direction
  static bool isRTL(String languageCode) {
    return ['ar', 'ur'].contains(languageCode);
  }

  /// Get culturally appropriate date separator
  static String getDateSeparator(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '/';
      case 'es':
      case 'hi':
      case 'ne':
      case 'bn':
      case 'ta':
      case 'te':
      case 'ml':
      case 'ur':
      case 'ar':
        return '/';
      default:
        return '/';
    }
  }

  /// Format address based on cultural conventions
  static String formatAddress({
    required String street,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    String? languageCode,
  }) {
    // Most countries follow similar address formatting
    // Street, City, State ZIP, Country
    return '$street\n$city, $state $zipCode\n$country';
  }
}
