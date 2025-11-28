import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Performance Optimization Utilities
class PerformanceUtils {
  /// Debounce function calls (e.g., for search)
  static void debounce(
    Function() action, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    Future.delayed(delay, action);
  }

  /// Throttle function calls (e.g., for scroll events)
  static Function() throttle(
    Function() action, {
    Duration interval = const Duration(milliseconds: 100),
  }) {
    bool isThrottled = false;

    return () {
      if (!isThrottled) {
        action();
        isThrottled = true;
        Future.delayed(interval, () {
          isThrottled = false;
        });
      }
    };
  }
}

/// Formatting Utilities
class FormatUtils {
  /// Format currency (NPR)
  static String formatCurrency(num amount, {bool includeSymbol = true}) {
    final formatter = NumberFormat.currency(
      locale: 'en_NP',
      symbol: includeSymbol ? 'Rs ' : '',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format large numbers (e.g., 1K, 1M)
  static String formatCompactNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Format date (e.g., "Jan 15, 2024")
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date with time (e.g., "Jan 15, 2024 at 3:30 PM")
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy \'at\' h:mm a').format(date);
  }

  /// Format relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  /// Format phone number
  static String formatPhoneNumber(String phone) {
    // Remove non-digits
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    // Format as +977 98XXXXXXXX
    if (digits.length >= 10) {
      return '+977 ${digits.substring(digits.length - 10)}';
    }
    return phone;
  }

  /// Format percentage
  static String formatPercentage(num value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

/// Validation Utilities
class ValidationUtils {
  /// Validate email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number (Nepal)
  static bool isValidPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10 && digits.startsWith('9');
  }

  /// Validate password strength
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 6) return PasswordStrength.weak;

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int strengthScore = 0;
    if (hasUppercase) strengthScore++;
    if (hasLowercase) strengthScore++;
    if (hasDigits) strengthScore++;
    if (hasSpecialChars) strengthScore++;
    if (password.length >= 8) strengthScore++;

    if (strengthScore >= 4) return PasswordStrength.strong;
    if (strengthScore >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(
      String? value, int minLength, String fieldName) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Validate price
  static bool isValidPrice(String price) {
    final priceRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    return priceRegex.hasMatch(price) && double.parse(price) > 0;
  }
}

enum PasswordStrength { none, weak, medium, strong }

/// Color Utilities
class ColorUtils {
  /// Get color from hex string
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Convert color to hex string
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2, 8)}';
  }

  /// Lighten color
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);

    return hsl.withLightness(lightness).toColor();
  }

  /// Darken color
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);

    return hsl.withLightness(lightness).toColor();
  }
}

/// Image Utilities
class ImageUtils {
  /// Get placeholder image URL
  static String getPlaceholder({int width = 300, int height = 300}) {
    return 'https://via.placeholder.com/${width}x$height';
  }

  /// Get initials from name
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Get avatar color based on name
  static Color getAvatarColor(String name) {
    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF4CAF50), // Green
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00BCD4), // Cyan
    ];

    final hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }
}

/// Storage Utilities
class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String themeMode = 'theme_mode';
  static const String language = 'language';
  static const String recentSearches = 'recent_searches';
  static const String cart = 'cart';
  static const String wishlist = 'wishlist';
}

/// Platform Utilities
class PlatformUtils {
  /// Check if running on mobile
  static bool get isMobile {
    return Theme.of(navigatorKey.currentContext!).platform ==
            TargetPlatform.android ||
        Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.iOS;
  }

  /// Check if running on Android
  static bool get isAndroid {
    return Theme.of(navigatorKey.currentContext!).platform ==
        TargetPlatform.android;
  }

  /// Check if running on iOS
  static bool get isIOS {
    return Theme.of(navigatorKey.currentContext!).platform ==
        TargetPlatform.iOS;
  }
}

// Global navigator key for accessing context without BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Network Utilities
class NetworkUtils {
  /// Parse error message from API response
  static String parseErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Map && error.containsKey('message')) {
      return error['message'];
    }
    return 'An error occurred. Please try again.';
  }

  /// Check if error is network error
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection');
  }
}

/// Responsive Utilities
class ResponsiveUtils {
  /// Check if screen is mobile (<600px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if screen is tablet (600-900px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 900;
  }

  /// Check if screen is desktop (>900px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900;
  }

  /// Get responsive value
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }
}
