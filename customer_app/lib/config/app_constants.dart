import 'package:flutter/material.dart';

class AppConstants {
  // ================================
  // APP BAR
  // ================================
  static const double appBarElevation = 0.0;

  // ================================
  // ICON SIZES
  // ================================
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // ================================
  // PADDING VALUES
  // ================================
  static const EdgeInsets paddingAll4 = EdgeInsets.all(4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(16);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(24);

  static const EdgeInsets paddingH16 = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets paddingH20 = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets paddingH24 = EdgeInsets.symmetric(horizontal: 24);

  static const EdgeInsets paddingV8 = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets paddingV12 = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets paddingV16 = EdgeInsets.symmetric(vertical: 16);

  // ================================
  // SPACING (GAP VALUES)
  // ================================
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;

  // ================================
  // BUTTON DIMENSIONS
  // ================================
  static const double buttonMinWidth = 120.0;
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  // ================================
  // SHAPES / BORDER RADII
  // ================================
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 28.0;

  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderRadiusMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(radiusLarge));

  // For bottom sheets/dialogs
  static const BorderRadius borderRadiusTop =
      BorderRadius.only(topLeft: Radius.circular(radiusLarge), topRight: Radius.circular(radiusLarge));

  // ================================
  // ELEVATIONS
  // ================================
  static const double elevationLow = 1.0;
  static const double elevationMedium = 3.0;
  static const double elevationHigh = 6.0;
  static const double elevationXHigh = 10.0;

  // ================================
  // DIVIDERS
  // ================================
  static const double dividerThickness = 1.0;

  // ================================
  // BOTTOM NAVIGATION BAR
  // ================================
  static const double bottomNavElevation = 8.0;

  // ================================
  // CARD SHADOW / EFFECTS
  // ================================
  static const double cardBlurRadius = 12.0;

  // ================================
  // ANIMATION DURATIONS
  // ================================
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animMedium = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  // ================================
  // CHART CONSTANTS (if needed)
  // ================================
  static const double chartBarWidth = 12.0;
  static const double chartSpacing = 20.0;

  // ================================
  // API (optional placeholder)
  // ================================
  static const String baseApiUrl = "http://localhost:3000";
}