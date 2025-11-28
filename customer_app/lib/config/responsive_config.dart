import 'package:flutter/material.dart';

/// Responsive breakpoint configuration for the application
/// Provides a consistent system for building adaptive layouts
class ResponsiveConfig {
  // Breakpoints (in logical pixels)
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 900;
  static const double desktopMaxWidth = 1200;
  static const double wideScreenMinWidth = 1200;

  // Screen type detection
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMaxWidth;
  }

  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= wideScreenMinWidth;
  }

  // Responsive values
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  // Grid columns based on screen size
  static int gridColumns(BuildContext context) {
    if (isWideScreen(context)) return 4;
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 3;
    return 2;
  }

  // Adaptive spacing scale based on screen size
  static double spacing(BuildContext context, double baseSpacing) {
    return responsiveValue(
      context,
      mobile: baseSpacing,
      tablet: baseSpacing * 1.2,
      desktop: baseSpacing * 1.5,
    );
  }

  // Adaptive padding
  static EdgeInsets adaptivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: responsiveValue(
        context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
      vertical: responsiveValue(
        context,
        mobile: 12.0,
        tablet: 16.0,
        desktop: 20.0,
      ),
    );
  }

  // Content max width for readability
  static double contentMaxWidth(BuildContext context) {
    return responsiveValue(
      context,
      mobile: double.infinity,
      tablet: 720.0,
      desktop: 1200.0,
    );
  }

  // Adaptive card width
  static double cardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = gridColumns(context);
    final spacing = adaptivePadding(context).horizontal;

    return (screenWidth - (spacing * 2) - ((columns - 1) * 12)) / columns;
  }

  // Adaptive font size multiplier
  static double fontSizeMultiplier(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.15,
    );
  }

  // Touch target size (minimum 48dp for mobile)
  static double touchTargetSize(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 48.0,
      tablet: 56.0,
      desktop: 44.0,
    );
  }

  // App bar height
  static double appBarHeight(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 56.0,
      tablet: 64.0,
      desktop: 72.0,
    );
  }

  // Bottom navigation height
  static double bottomNavHeight(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 64.0,
      tablet: 72.0,
      desktop: 0.0, // Use drawer/rail on desktop
    );
  }

  // Card elevation
  static double cardElevation(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 2.0,
      tablet: 3.0,
      desktop: 4.0,
    );
  }

  // Border radius
  static double borderRadius(BuildContext context, {double base = 12.0}) {
    return responsiveValue(
      context,
      mobile: base,
      tablet: base * 1.2,
      desktop: base * 1.3,
    );
  }

  // Icon size
  static double iconSize(BuildContext context, {double base = 24.0}) {
    return responsiveValue(
      context,
      mobile: base,
      tablet: base * 1.15,
      desktop: base * 1.2,
    );
  }

  // Maximum dialog width
  static double maxDialogWidth(BuildContext context) {
    return responsiveValue(
      context,
      mobile: double.infinity,
      tablet: 600.0,
      desktop: 800.0,
    );
  }

  // Sidebar width for tablet/desktop layouts
  static double sidebarWidth(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 0.0,
      tablet: 300.0,
      desktop: 320.0,
    );
  }

  // Product image aspect ratio
  static double productImageAspectRatio(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 0.85,
      tablet: 0.9,
      desktop: 1.0,
    );
  }
}

/// Extension methods for easier responsive development
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveConfig.isMobile(this);
  bool get isTablet => ResponsiveConfig.isTablet(this);
  bool get isDesktop => ResponsiveConfig.isDesktop(this);
  bool get isWideScreen => ResponsiveConfig.isWideScreen(this);

  int get gridColumns => ResponsiveConfig.gridColumns(this);
  double spacing(double base) => ResponsiveConfig.spacing(this, base);
  EdgeInsets get adaptivePadding => ResponsiveConfig.adaptivePadding(this);

  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) =>
      ResponsiveConfig.responsiveValue(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );
}
