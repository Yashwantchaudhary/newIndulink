import 'package:flutter/material.dart';

/// 🎨 INDULINK Premium Color System
/// World-class color palette inspired by modern e-commerce leaders
/// Designed for building materials marketplace
class AppColors {
  AppColors._();

  // ==================== Primary Brand Colors ====================
  /// Rich Industrial Blue - Represents trust, reliability, and construction
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF4285F4);
  static const Color primaryLighter = Color(0xFFBBDEFB);
  static const Color primaryLightest = Color(0xFFE3F2FD);

  // ==================== Secondary Colors ====================
  /// Vibrant Orange - Energy, action, and CTAs
  static const Color secondary = Color(0xFFFF6F00);
  static const Color secondaryDark = Color(0xFFE65100);
  static const Color secondaryLight = Color(0xFFFF9800);
  static const Color secondaryLighter = Color(0xFFFFCC80);

  // ==================== Accent Colors ====================
  /// Success Green - For positive actions and confirmations
  static const Color success = Color(0xFF00C853);
  static const Color successLight = Color(0xFF69F0AE);
  static const Color successLightest = Color(0xFFE8F5E8);
  static const Color successDark = Color(0xFF00A843);

  /// Warning Amber - For alerts and important information
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFD54F);

  /// Error Red - For errors and destructive actions
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFEF5350);

  /// Info Blue - For informational messages
  static const Color info = Color(0xFF0288D1);
  static const Color infoLight = Color(0xFF4FC3F7);

  // ==================== Neutral Colors ====================
  /// Background colors for modern UI
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// Card and elevated surfaces
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF252525);
  static const Color cardElevated = Color(0xFFFAFAFA);

  /// Dividers and borders
  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);
  static const Color border = Color(0xFFDEDEDE);
  static const Color borderLight = Color(0xFFF0F0F0);

  // ==================== Text Colors ====================
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF121212);

  // Dark theme text colors
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // ==================== Gradient Colors ====================
  /// Premium gradients for hero sections and CTAs
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, successDark],
  );

  /// Glassmorphism gradient overlay
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x40FFFFFF),
      Color(0x20FFFFFF),
    ],
  );

  /// Shimmer loading gradient
  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.5),
    end: Alignment(1.0, 0.5),
    colors: [
      Color(0xFFE0E0E0),
      Color(0xFFF0F0F0),
      Color(0xFFE0E0E0),
    ],
  );

  // ==================== Category-Specific Colors ====================
  /// Colors for product categories
  static const Color categoryCement = Color(0xFF78909C);
  static const Color categorySteel = Color(0xFF607D8B);
  static const Color categoryBricks = Color(0xFFD84315);
  static const Color categorySand = Color(0xFFFDD835);
  static const Color categoryPaint = Color(0xFFE91E63);
  static const Color categoryTools = Color(0xFF455A64);
  static const Color categoryElectrical = Color(0xFFFFC107);
  static const Color categoryPlumbing = Color(0xFF2196F3);

  // ==================== Role-Specific Colors ====================
  static const Color customerRole = Color(0xFF4CAF50);
  static const Color supplierRole = Color(0xFFFF9800);
  static const Color adminRole = Color(0xFF9C27B0);

  // ==================== Overlay Colors ====================
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
  static const Color scrim = Color(0xB3000000);

  // ==================== Badge and Label Colors ====================
  static const Color badgeNew = Color(0xFF00E676);
  static const Color badgeSale = Color(0xFFFF1744);
  static const Color badgeFeatured = Color(0xFFFFD600);
  static const Color badgeLowStock = Color(0xFFFF6F00);

  // ==================== Status Colors for Orders ====================
  static const Color statusPending = Color(0xFFFFA726);
  static const Color statusProcessing = Color(0xFF42A5F5);
  static const Color statusShipped = Color(0xFF9575CD);
  static const Color statusDelivered = Color(0xFF66BB6A);
  static const Color statusCancelled = Color(0xFFEF5350);

  // ==================== Chart and Analytics Colors ====================
  static const List<Color> chartColors = [
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF4CAF50),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFFEB3B),
    Color(0xFF795548),
  ];

  // ==================== Social Media Colors ====================
  static const Color google = Color(0xFFDB4437);
  static const Color facebook = Color(0xFF4267B2);
  static const Color twitter = Color(0xFF1DA1F2);
  static const Color instagram = Color(0xFFE4405F);

  // ==================== Helper Methods ====================
  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get shadow color for elevation
  static Color getShadowColor({bool isDark = false}) {
    return isDark
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.1);
  }

  /// Get theme-aware background
  static Color getBackground(bool isDark) {
    return isDark ? backgroundDark : background;
  }

  /// Get theme-aware surface color
  static Color getSurface(bool isDark) {
    return isDark ? surfaceDark : surface;
  }

  /// Get theme-aware text color
  static Color getTextPrimary(bool isDark) {
    return isDark ? textPrimaryDark : textPrimary;
  }

  /// Get theme-aware text secondary color
  static Color getTextSecondary(bool isDark) {
    return isDark ? textSecondaryDark : textSecondary;
  }

  /// Get rating color based on value
  static Color getRatingColor(double rating) {
    if (rating >= 4.0) return success;
    if (rating >= 3.0) return warning;
    return error;
  }

  /// Get stock availability color
  static Color getStockColor(int stock) {
    if (stock > 50) return success;
    if (stock > 10) return warning;
    if (stock > 0) return badgeLowStock;
    return error;
  }
}
