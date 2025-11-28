import 'package:flutter/material.dart';

/// World-Class App Color Palette
/// Inspired by best-in-class apps with sophisticated, vibrant colors
/// Perfect for light and dark themes with accessibility built-in
class AppColors {
  // Constructor is private to prevent instantiation
  AppColors._();

  // ===== PRIMARY COLORS - Deep Blue (Trust & Professionalism) =====
  static const Color primaryBlue = Color(0xFF0052CC); // Deep blue
  static const Color primaryBlueLight = Color(0xFF0065FF); // Bright blue
  static const Color primaryBlueDark = Color(0xFF003D99); // Dark blue
  static const Color primaryBlueVeryLight =
      Color(0xFF4C9AFF); // Very light blue

  // ===== SECONDARY COLORS - Purple (Creativity & Innovation) =====
  static const Color secondaryPurple = Color(0xFF7C3AED); // Vibrant purple
  static const Color secondaryPurpleLight = Color(0xFFA78BFA); // Light purple
  static const Color secondaryPurpleDark = Color(0xFF6D28D9); // Dark purple

  // ===== ACCENT COLORS - Energy & Action =====
  static const Color accentCoral = Color(0xFFFF3B5C); // Vibrant coral (NEW)
  static const Color accentCoralLight = Color(0xFFFF6B8A); // Light coral (NEW)
  static const Color accentOrange = Color(0xFFF97316); // Vibrant orange
  static const Color accentGreen = Color(0xFF00C853); // Bright green (updated)
  static const Color accentRed = Color(0xFFFF1744); // Bright red (updated)
  static const Color accentYellow = Color(0xFFFBBF24); // Gold yellow
  static const Color accentPink = Color(0xFFEC4899); // Hot pink
  static const Color accentCyan = Color(0xFF00B0FF); // Bright cyan (updated)

  // ===== NEUTRAL SCALE - 12 Shades for Perfect Hierarchy =====
  static const Color neutral100 = Color(0xFFFFFFFF); // Pure white
  static const Color neutral200 = Color(0xFFF7F9FC); // Off-white backgrounds
  static const Color neutral300 = Color(0xFFE8ECF2); // Dividers, borders
  static const Color neutral400 = Color(0xFFD0D7E2); // Disabled states
  static const Color neutral500 = Color(0xFFACB5C3); // Placeholders
  static const Color neutral600 = Color(0xFF8892A6); // Secondary text
  static const Color neutral700 = Color(0xFF69768C); // Primary text (light)
  static const Color neutral800 = Color(0xFF4A5568); // Headings
  static const Color neutral900 = Color(0xFF2D3748); // Almost black
  static const Color neutral1000 = Color(0xFF1A202C); // Black text

  // ===== LIGHT THEME COLORS =====
  static const Color lightBackground = Color(0xFFF7F9FC); // neutral200
  static const Color lightSurface = Color(0xFFFFFFFF); // neutral100
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9); // Lighter variant
  static const Color lightBorder = Color(0xFFE8ECF2); // neutral300

  // Text colors - Light theme
  static const Color lightTextPrimary = Color(0xFF1A202C); // neutral1000
  static const Color lightTextSecondary = Color(0xFF4A5568); // neutral800
  static const Color lightTextTertiary = Color(0xFF8892A6); // neutral600

  // ===== DARK THEME COLORS =====
  static const Color darkBackground =
      Color(0xFF0A0E1A); // Deep navy (not pure black)
  static const Color darkSurface = Color(0xFF141824); // Elevated surface
  static const Color darkSurfaceVariant =
      Color(0xFF1E2532); // Cards, containers
  static const Color darkBorder = Color(0xFF2A3244); // Subtle borders

  // Text colors - Dark theme
  static const Color darkTextPrimary = Color(0xFFF7F9FC); // neutral200
  static const Color darkTextSecondary = Color(0xFFD0D7E2); // neutral400
  static const Color darkTextTertiary = Color(0xFFACB5C3); // neutral500

  // ===== SEMANTIC COLORS =====
  static const Color success = Color(0xFF00C853); // Bright green
  static const Color successLight = Color(0xFFB9F6CA); // Light green bg
  static const Color successDark = Color(0xFF00A344); // Dark green

  static const Color error = Color(0xFFFF1744); // Bright red
  static const Color errorLight = Color(0xFFFF8A80); // Light red bg
  static const Color errorDark = Color(0xFFD50000); // Dark red

  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color warningLight = Color(0xFFFFE0B2); // Light orange bg
  static const Color warningDark = Color(0xFFF57C00); // Dark orange

  static const Color info = Color(0xFF00B0FF); // Cyan
  static const Color infoLight = Color(0xFFB3E5FC); // Light cyan bg
  static const Color infoDark = Color(0xFF0091EA); // Dark cyan

  // ===== ORDER STATUS COLORS =====
  static const Color statusPending = Color(0xFFFF9800); // Orange
  static const Color statusConfirmed = Color(0xFF00B0FF); // Cyan
  static const Color statusProcessing = Color(0xFF7C3AED); // Purple
  static const Color statusShipped = Color(0xFF00B0FF); // Cyan
  static const Color statusDelivered = Color(0xFF00C853); // Green
  static const Color statusCancelled = Color(0xFF8892A6); // Gray
  static const Color statusRefunded = Color(0xFFFF1744); // Red

  // ===== GRADIENTS - Modern & Vibrant =====
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0052CC), Color(0xFF0084FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF3B5C), Color(0xFFFF6B8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00E676)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0052CC), Color(0xFF3B82F6), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangePinkGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEC4899)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cyanBlueGradient = LinearGradient(
    colors: [Color(0xFF00B0FF), Color(0xFF0084FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenTealGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFFF6B8A), Color(0xFFFBBF24), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shimmer gradients
  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFE8ECF2),
      Color(0xFFF7F9FC),
      Color(0xFFE8ECF2),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  static const LinearGradient shimmerGradientDark = LinearGradient(
    colors: [
      Color(0xFF1E2532),
      Color(0xFF2A3244),
      Color(0xFF1E2532),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  // ===== CHART COLORS - Distinct & Accessible =====
  static const List<Color> chartColors = [
    Color(0xFF0052CC), // Blue
    Color(0xFF7C3AED), // Purple
    Color(0xFFF97316), // Orange
    Color(0xFF00C853), // Green
    Color(0xFFFF3B5C), // Coral
    Color(0xFF00B0FF), // Cyan
    Color(0xFFFBBF24), // Yellow
    Color(0xFFEC4899), // Pink
  ];

  // ===== GLASSMORPHISM COLORS =====
  static Color glassLight = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
  static Color glassDark = const Color(0xFF141824).withValues(alpha: 0.7);
  static Color glassBlur = const Color(0xFFFFFFFF).withValues(alpha: 0.3);
  static Color glassBlurDark = const Color(0xFF141824).withValues(alpha: 0.3);

  // ===== OVERLAY COLORS =====
  static Color overlay = const Color(0xFF000000).withValues(alpha: 0.5);
  static Color overlayLight = const Color(0xFF000000).withValues(alpha: 0.3);
  static Color overlayDark = const Color(0xFF000000).withValues(alpha: 0.7);

  // ===== HELPER METHODS =====

  /// Get color for order status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return statusPending;
      case 'confirmed':
        return statusConfirmed;
      case 'processing':
        return statusProcessing;
      case 'shipped':
      case 'out_for_delivery':
        return statusShipped;
      case 'delivered':
        return statusDelivered;
      case 'cancelled':
        return statusCancelled;
      case 'refunded':
        return statusRefunded;
      default:
        return neutral600;
    }
  }

  /// Get background color for status badge
  static Color getStatusBackgroundColor(String status) {
    return getStatusColor(status).withValues(alpha: 0.1);
  }

  /// Get category color based on index
  static Color getCategoryColor(int index) {
    return chartColors[index % chartColors.length];
  }

  /// Get gradient for category based on index
  static LinearGradient getCategoryGradient(int index) {
    final gradients = [
      primaryGradient,
      secondaryGradient,
      accentGradient,
      orangePinkGradient,
      cyanBlueGradient,
      purpleGradient,
      successGradient,
      greenTealGradient,
      sunsetGradient,
      heroGradient,
    ];
    return gradients[index % gradients.length];
  }

  /// Check if color has sufficient contrast with white background
  /// Returns true if contrast ratio is >= 4.5:1 (WCAG AA)
  static bool hasSufficientContrast(Color color) {
    final luminance = color.computeLuminance();
    final contrast = (1.05) / (luminance + 0.05);
    return contrast >= 4.5;
  }

  /// Get text color based on background brightness
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? neutral1000 : neutral100;
  }
}
