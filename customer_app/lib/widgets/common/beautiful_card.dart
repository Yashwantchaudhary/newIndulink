import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Beautiful card component with multiple variants: glass, gradient, elevated
class BeautifulCard extends StatelessWidget {
  final Widget child;
  final BeautifulCardVariant variant;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double? elevation;

  const BeautifulCard({
    super.key,
    required this.child,
    this.variant = BeautifulCardVariant.elevated,
    this.padding,
    this.margin,
    this.gradient,
    this.onTap,
    this.borderRadius,
    this.elevation,
  });

  /// Glass morphism card with blur effect
  factory BeautifulCard.glass({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    return BeautifulCard(
      variant: BeautifulCardVariant.glass,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }

  /// Gradient card with beautiful colors
  factory BeautifulCard.gradient({
    required Widget child,
    LinearGradient? gradient,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    return BeautifulCard(
      variant: BeautifulCardVariant.gradient,
      gradient: gradient,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }

  /// Standard elevated card
  factory BeautifulCard.elevated({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
    double? elevation,
  }) {
    return BeautifulCard(
      variant: BeautifulCardVariant.elevated,
      padding: padding,
      margin: margin,
      onTap: onTap,
      elevation: elevation,
      child: child,
    );
  }

  /// Outlined card
  factory BeautifulCard.outlined({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    return BeautifulCard(
      variant: BeautifulCardVariant.outlined,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final widget = Container(
      margin: margin ?? AppConstants.paddingAll12,
      decoration: _buildDecoration(isDark),
      child: ClipRRect(
        borderRadius: borderRadius ?? AppConstants.borderRadiusMedium,
        child: variant == BeautifulCardVariant.glass
            ? _buildGlassContent(isDark)
            : Container(
                padding: padding ?? AppConstants.paddingAll16,
                child: child,
              ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? AppConstants.borderRadiusMedium,
          child: widget,
        ),
      );
    }

    return widget;
  }

  BoxDecoration _buildDecoration(bool isDark) {
    switch (variant) {
      case BeautifulCardVariant.glass:
        return BoxDecoration(
          borderRadius: borderRadius ?? AppConstants.borderRadiusMedium,
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.lightBorder.withValues(alpha: 0.5),
            width: 1,
          ),
        );

      case BeautifulCardVariant.gradient:
        return BoxDecoration(
          gradient: gradient ?? AppColors.primaryGradient,
          borderRadius: borderRadius ?? AppConstants.borderRadiusMedium,
          boxShadow: [
            BoxShadow(
              color: (gradient?.colors.first ?? AppColors.primaryBlue)
                  .withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        );

      case BeautifulCardVariant.elevated:
        return BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: borderRadius ?? AppConstants.borderRadiusMedium,
          boxShadow: AppConstants.shadowMedium,
        );

      case BeautifulCardVariant.outlined:
        return BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: borderRadius ?? AppConstants.borderRadiusMedium,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        );
    }
  }

  Widget _buildGlassContent(bool isDark) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: padding ?? AppConstants.paddingAll16,
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassDark : AppColors.glassLight,
          borderRadius: borderRadius ?? AppConstants.borderRadiusMedium,
        ),
        child: child,
      ),
    );
  }
}

enum BeautifulCardVariant {
  glass,
  gradient,
  elevated,
  outlined,
}
