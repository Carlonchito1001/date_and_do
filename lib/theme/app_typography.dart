import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final base = GoogleFonts.poppinsTextTheme();

    final colorStrong = isDark ? AppColors.textLight : AppColors.textDark;
    final colorMuted = isDark
        ? AppColors.textMutedLight
        : AppColors.textMutedDark;

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: colorStrong,
        letterSpacing: -0.8,
        height: 1.05,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: colorStrong,
        letterSpacing: -0.6,
        height: 1.08,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorStrong,
        letterSpacing: -0.4,
        height: 1.1,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorStrong,
        letterSpacing: -0.4,
        height: 1.1,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorStrong,
        letterSpacing: -0.2,
        height: 1.15,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorStrong,
        height: 1.18,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorStrong,
        letterSpacing: 0.15,
        height: 1.2,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorStrong,
        letterSpacing: 0.1,
        height: 1.25,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorStrong,
        height: 1.25,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        color: colorStrong,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        color: colorMuted,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        color: colorMuted,
        height: 1.4,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorStrong,
        letterSpacing: 0.2,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorMuted,
        letterSpacing: 0.15,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorMuted,
        letterSpacing: 0.15,
      ),
    );
  }
}
