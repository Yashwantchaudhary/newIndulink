import 'package:flutter/material.dart';

/// App-wide constants for spacing, sizing, borders, and animations
class AppConstants {
  // Constructor is private to prevent instantiation
  AppConstants._();

  // ===== SPACING =====
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // ===== PADDING =====
  static const EdgeInsets paddingAll4 = EdgeInsets.all(spacing4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(spacing8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(spacing12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(spacing16);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(spacing20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(spacing24);
  static const EdgeInsets paddingAll32 = EdgeInsets.all(spacing32);

  static const EdgeInsets paddingH16 =
      EdgeInsets.symmetric(horizontal: spacing16);
  static const EdgeInsets paddingH20 =
      EdgeInsets.symmetric(horizontal: spacing20);
  static const EdgeInsets paddingH24 =
      EdgeInsets.symmetric(horizontal: spacing24);

  static const EdgeInsets paddingV8 = EdgeInsets.symmetric(vertical: spacing8);
  static const EdgeInsets paddingV12 =
      EdgeInsets.symmetric(vertical: spacing12);
  static const EdgeInsets paddingV16 =
      EdgeInsets.symmetric(vertical: spacing16);
  static const EdgeInsets paddingV20 =
      EdgeInsets.symmetric(vertical: spacing20);

  static const EdgeInsets paddingPage = EdgeInsets.symmetric(
    horizontal: spacing16,
    vertical: spacing20,
  );

  // ===== BORDER RADIUS - Smooth & Modern =====
  static const double radiusSmall = 8.0; // Buttons, chips
  static const double radiusMedium = 12.0; // Cards, containers
  static const double radiusLarge = 16.0; // Modals, sheets
  static const double radiusXLarge = 20.0; // Large cards
  static const double radiusXXLarge = 24.0; // Hero sections
  static const double radiusCircle = 999.0; // Pills, avatars

  static const BorderRadius borderRadiusSmall = BorderRadius.all(
    Radius.circular(radiusSmall),
  );
  static const BorderRadius borderRadiusMedium = BorderRadius.all(
    Radius.circular(radiusMedium),
  );
  static const BorderRadius borderRadiusLarge = BorderRadius.all(
    Radius.circular(radiusLarge),
  );
  static const BorderRadius borderRadiusXLarge = BorderRadius.all(
    Radius.circular(radiusXLarge),
  );
  static const BorderRadius borderRadiusXXLarge = BorderRadius.all(
    Radius.circular(radiusXXLarge),
  );

  static const BorderRadius borderRadiusTop = BorderRadius.only(
    topLeft: Radius.circular(radiusLarge),
    topRight: Radius.circular(radiusLarge),
  );

  static const BorderRadius borderRadiusBottom = BorderRadius.only(
    bottomLeft: Radius.circular(radiusLarge),
    bottomRight: Radius.circular(radiusLarge),
  );

  // ===== ICON SIZES =====
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // ===== AVATAR SIZES =====
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 64.0;
  static const double avatarSizeXLarge = 96.0;

  // ===== ELEVATION =====
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double elevationXHigh = 16.0;

  // ===== ANIMATION DURATIONS - World-Class Standards =====
  static const Duration durationInstant =
      Duration(milliseconds: 100); // State changes
  static const Duration durationFast =
      Duration(milliseconds: 200); // Micro-interactions
  static const Duration durationNormal =
      Duration(milliseconds: 300); // Standard transitions
  static const Duration durationSlow =
      Duration(milliseconds: 500); // Page transitions
  static const Duration durationXSlow =
      Duration(milliseconds: 800); // Hero animations
  static const Duration durationChart =
      Duration(milliseconds: 800); // Chart animations
  static const Duration durationPageTransition = Duration(milliseconds: 350);

  // ===== ANIMATION CURVES - Smooth & Purposeful =====
  static const Curve curveStandard = Curves.easeInOutCubic; // Most animations
  static const Curve curveEmphasized = Curves.easeOutCubic; // Enter animations
  static const Curve curveDeemphasized = Curves.easeInCubic; // Exit animations
  static const Curve curveBounce = Curves.elasticOut; // Success states
  static const Curve curveSpring = Curves.fastOutSlowIn; // Natural motion

  // ===== SHADOWS - Material 3 Inspired =====
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  // ===== BREAKPOINTS (for responsive design) =====
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1200;

  // ===== CARD DIMENSIONS =====
  static const double cardHeight = 160.0;
  static const double cardHeightSmall = 100.0;
  static const double cardHeightLarge = 200.0;
  static const double statCardHeight = 120.0;

  // ===== CHART DIMENSIONS =====
  static const double chartHeight = 250.0;
  static const double chartHeightSmall = 180.0;
  static const double chartHeightLarge = 320.0;
  static const double pieChartSize = 200.0;

  // ===== BUTTON DIMENSIONS =====
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 44.0;
  static const double buttonHeightLarge = 52.0;
  static const double buttonMinWidth = 100.0;

  // ===== IMAGE DIMENSIONS =====
  static const double productImageSize = 80.0;
  static const double productImageSizeSmall = 48.0;
  static const double productImageSizeLarge = 120.0;

  // ===== OPACITY =====
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityLight = 0.8;
  static const double opacityGlass = 0.1;
  static const double opacityOverlay = 0.4;

  // ===== DIVIDER =====
  static const double dividerThickness = 1.0;
  static const double dividerIndent = 16.0;

  // ===== APP BAR =====
  static const double appBarHeight = 56.0;
  static const double appBarElevation = 0.0;

  // ===== BOTTOM NAV BAR =====
  static const double bottomNavHeight = 60.0;
  static const double bottomNavElevation = 8.0;

  // ===== Z-INDEX (for stacking) =====
  static const int zIndexBase = 0;
  static const int zIndexDropdown = 10;
  static const int zIndexModal = 100;
  static const int zIndexToast = 1000;

  // ===== MAX WIDTHS =====
  static const double maxWidthMobile = 600;
  static const double maxWidthTablet = 900;
  static const double maxWidthDesktop = 1200;
  static const double maxContentWidth = 1400;

  // ===== GRID =====
  static const int gridCrossAxisCountMobile = 2;
  static const int gridCrossAxisCountTablet = 3;
  static const int gridCrossAxisCountDesktop = 4;
  static const double gridChildAspectRatio = 0.7;
  static const double gridSpacing = 12.0;

  // ===== LIST =====
  static const double listItemHeight = 72.0;
  static const double listItemHeightSmall = 56.0;
  static const double listItemHeightLarge = 96.0;

  // ===== HELPER METHODS =====

  /// Get grid cross axis count based on screen width
  static int getGridCrossAxisCount(double screenWidth) {
    if (screenWidth >= breakpointDesktop) {
      return gridCrossAxisCountDesktop;
    } else if (screenWidth >= breakpointTablet) {
      return gridCrossAxisCountTablet;
    } else {
      return gridCrossAxisCountMobile;
    }
  }

  /// Check if screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpointMobile;
  }

  /// Check if screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointMobile && width < breakpointDesktop;
  }

  /// Check if screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= breakpointDesktop;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isDesktop(context)) {
      return paddingAll24;
    } else if (isTablet(context)) {
      return paddingAll20;
    } else {
      return paddingAll16;
    }
  }

  /// Get responsive font size multiplier
  static double getResponsiveFontMultiplier(BuildContext context) {
    if (isDesktop(context)) {
      return 1.1;
    } else if (isTablet(context)) {
      return 1.05;
    } else {
      return 1.0;
    }
  }
}
