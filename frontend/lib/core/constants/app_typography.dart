import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 📝 INDULINK Premium Typography System
/// World-class typography using Google Fonts
class AppTypography {
  AppTypography._();

  // ==================== Font Families ====================
  /// Primary font for headings and important text
  static const String primaryFont = 'Inter';

  /// Secondary font for body text
  static const String secondaryFont = 'Roboto';

  /// Monospace font for code and numbers
  static const String monoFont = 'RobotoMono';

  // ==================== Font Weights ====================
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // ==================== Display Styles (Large Hero Text) ====================
  static TextStyle display1 = GoogleFonts.inter(
    fontSize: 57,
    fontWeight: extraBold,
    height: 1.2,
    letterSpacing: -0.25,
  );

  static TextStyle display2 = GoogleFonts.inter(
    fontSize: 45,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: 0,
  );

  static TextStyle display3 = GoogleFonts.inter(
    fontSize: 36,
    fontWeight: bold,
    height: 1.3,
    letterSpacing: 0,
  );

  // ==================== Headline Styles ====================
  static TextStyle h1 = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: bold,
    height: 1.25,
    letterSpacing: 0,
  );

  static TextStyle h2 = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: bold,
    height: 1.3,
    letterSpacing: 0,
  );

  static TextStyle h3 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: 0,
  );

  static TextStyle h4 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.4,
    letterSpacing: 0.15,
  );

  static TextStyle h5 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: semiBold,
    height: 1.4,
    letterSpacing: 0.15,
  );

  static TextStyle h6 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: medium,
    height: 1.5,
    letterSpacing: 0.15,
  );

  // ==================== Body Styles ====================
  static TextStyle bodyLarge = GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.5,
  );

  static TextStyle bodyMedium = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.25,
  );

  static TextStyle bodySmall = GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.4,
  );

  // ==================== Label Styles ====================
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // ==================== Button Styles ====================
  static TextStyle buttonLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static TextStyle buttonMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: semiBold,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static TextStyle buttonSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // ==================== Caption & Overline ====================
  static TextStyle caption = GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: regular,
    height: 1.3,
    letterSpacing: 0.4,
  );

  static TextStyle overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: medium,
    height: 1.6,
    letterSpacing: 1.5,
  );

  // ==================== Price Styles ====================
  static TextStyle priceHuge = GoogleFonts.robotoMono(
    fontSize: 36,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle priceLarge = GoogleFonts.robotoMono(
    fontSize: 24,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: 0,
  );

  static TextStyle priceMedium = GoogleFonts.robotoMono(
    fontSize: 18,
    fontWeight: semiBold,
    height: 1.2,
    letterSpacing: 0,
  );

  static TextStyle priceSmall = GoogleFonts.robotoMono(
    fontSize: 14,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0,
  );

  static TextStyle priceStrikethrough = GoogleFonts.robotoMono(
    fontSize: 14,
    fontWeight: regular,
    height: 1.2,
    letterSpacing: 0,
    decoration: TextDecoration.lineThrough,
    decorationThickness: 2,
  );

  // ==================== Badge & Tag Styles ====================
  static TextStyle badge = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: semiBold,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static TextStyle tag = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // ==================== Input Styles ====================
  static TextStyle inputLabel = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.15,
  );

  static TextStyle inputText = GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static TextStyle inputHint = GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static TextStyle inputError = GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: regular,
    height: 1.3,
    letterSpacing: 0.4,
  );

  // ==================== Helper Methods ====================
  /// Apply color to text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply weight to text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Apply size to text style
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Apply multiple properties
  static TextStyle customize(
    TextStyle style, {
    Color? color,
    FontWeight? weight,
    double? size,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return style.copyWith(
      color: color,
      fontWeight: weight,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }
}
