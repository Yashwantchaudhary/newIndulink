import 'package:flutter/material.dart';
import '../config/responsive_config.dart';

/// Utility class for responsive typography
class ResponsiveTypography {
  /// Get responsive text style with fluid scaling
  static TextStyle fluidTextStyle(
    BuildContext context,
    TextStyle baseStyle, {
    double? mobileFontSize,
    double? tabletFontSize,
    double? desktopFontSize,
  }) {
    final multiplier = ResponsiveConfig.fontSizeMultiplier(context);
    final baseFontSize = baseStyle.fontSize ?? 14.0;

    final fontSize = ResponsiveConfig.responsiveValue(
      context,
      mobile: mobileFontSize ?? baseFontSize,
      tablet: tabletFontSize ?? baseFontSize * 1.1,
      desktop: desktopFontSize ?? baseFontSize * 1.15,
    );

    return baseStyle.copyWith(fontSize: fontSize * multiplier);
  }

  /// Responsive heading styles
  static TextStyle h1(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: ResponsiveConfig.responsiveValue(
        context,
        mobile: 28.0,
        tablet: 32.0,
        desktop: 36.0,
      ),
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle h2(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: ResponsiveConfig.responsiveValue(
        context,
        mobile: 24.0,
        tablet: 28.0,
        desktop: 32.0,
      ),
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle h3(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: ResponsiveConfig.responsiveValue(
        context,
        mobile: 20.0,
        tablet: 22.0,
        desktop: 24.0,
      ),
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle h4(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: ResponsiveConfig.responsiveValue(
        context,
        mobile: 18.0,
        tablet: 19.0,
        desktop: 20.0,
      ),
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle body1(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: ResponsiveConfig.responsiveValue(
        context,
        mobile: 16.0,
        tablet: 17.0,
        desktop: 18.0,
      ),
      fontWeight: FontWeight.normal,
      color: color,
      height: 1.5,
    );
  }

  static TextStyle body2(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: ResponsiveConfig.responsiveValue(
        context,
        mobile: 14.0,
        tablet: 15.0,
        desktop: 16.0,
      ),
      fontWeight: FontWeight.normal,
      color: color,
      height: 1.5,
    );
  }

  static TextStyle subtitle1(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: ResponsiveConfig.responsiveValue(
        context,
        mobile: 16.0,
        tablet: 17.0,
        desktop: 18.0,
      ),
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle subtitle2(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: ResponsiveConfig.responsiveValue(
        context,
        mobile: 14.0,
        tablet: 15.0,
        desktop: 16.0,
      ),
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle caption(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: ResponsiveConfig.responsiveValue(
        context,
        mobile: 12.0,
        tablet: 13.0,
        desktop: 14.0,
      ),
      fontWeight: FontWeight.normal,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle overline(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: ResponsiveConfig.responsiveValue(
        context,
        mobile: 10.0,
        tablet: 11.0,
        desktop: 12.0,
      ),
      fontWeight: FontWeight.w500,
      letterSpacing: 1.5,
      color: color,
      height: 1.2,
    );
  }
}

/// Utility class for responsive spacing
class ResponsiveSpacing {
  /// Standard spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  /// Get adaptive spacing based on screen size
  static double adaptive(BuildContext context, double baseSpacing) {
    return ResponsiveConfig.spacing(context, baseSpacing);
  }

  /// Spacing between grid items
  static double gridSpacing(BuildContext context) {
    return ResponsiveConfig.responsiveValue(
      context,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    );
  }

  /// Spacing between sections
  static double sectionSpacing(BuildContext context) {
    return ResponsiveConfig.responsiveValue(
      context,
      mobile: 24.0,
      tablet: 32.0,
      desktop: 40.0,
    );
  }

  /// Card padding
  static EdgeInsets cardPadding(BuildContext context) {
    return EdgeInsets.all(
      ResponsiveConfig.responsiveValue(
        context,
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
      ),
    );
  }

  /// Screen edge padding
  static EdgeInsets screenPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: ResponsiveConfig.responsiveValue(
        context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
    );
  }
}

/// Utility class for responsive layout helpers
class ResponsiveLayout {
  /// Build a responsive grid
  static Widget responsiveGrid(
    BuildContext context, {
    required List<Widget> children,
    double? mainAxisSpacing,
    double? crossAxisSpacing,
    double? childAspectRatio,
  }) {
    final columns = ResponsiveConfig.gridColumns(context);
    final spacing = mainAxisSpacing ?? ResponsiveSpacing.gridSpacing(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: spacing,
        crossAxisSpacing: crossAxisSpacing ?? spacing,
        childAspectRatio: childAspectRatio ?? 0.75,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  /// Wrap content with max width constraint
  static Widget constrainedContent(
    BuildContext context, {
    required Widget child,
    double? maxWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveConfig.contentMaxWidth(context),
        ),
        child: child,
      ),
    );
  }

  /// Build responsive row/column based on screen size
  static Widget adaptiveLayout(
    BuildContext context, {
    required List<Widget> children,
    bool reverseOnMobile = false,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    double spacing = 16.0,
  }) {
    if (ResponsiveConfig.isMobile(context)) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: reverseOnMobile ? children.reversed.toList() : children,
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }

  /// Two-column layout on desktop, single column on mobile
  static Widget twoColumnLayout(
    BuildContext context, {
    required Widget left,
    required Widget right,
    double spacing = 24.0,
  }) {
    if (ResponsiveConfig.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          left,
          SizedBox(height: spacing),
          right,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: left),
        SizedBox(width: spacing),
        Expanded(flex: 1, child: right),
      ],
    );
  }
}

/// Utility class for responsive animations
class ResponsiveAnimations {
  /// Standard animation duration based on device performance
  static Duration animationDuration(BuildContext context) {
    return ResponsiveConfig.responsiveValue(
      context,
      mobile: const Duration(milliseconds: 300),
      tablet: const Duration(milliseconds: 350),
      desktop: const Duration(milliseconds: 400),
    );
  }

  /// Fast animation for micro-interactions
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard animation
  static const Duration standard = Duration(milliseconds: 300);

  /// Slow animation for complex transitions
  static const Duration slow = Duration(milliseconds: 500);

  /// Standard curve
  static const Curve curve = Curves.easeInOut;

  /// Emphasized curve for important animations
  static const Curve emphasizedCurve = Curves.easeOutCubic;
}

// Legacy ResponsiveUtils for backward compatibility
class ResponsiveUtils {
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    return ResponsiveSpacing.adaptive(context, baseSpacing);
  }

  static double getResponsiveFontSize(
      BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return baseFontSize * 0.9;
    } else if (screenWidth < 600) {
      return baseFontSize;
    } else {
      return baseFontSize * 1.1;
    }
  }
}
