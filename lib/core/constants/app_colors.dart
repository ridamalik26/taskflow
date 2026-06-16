import 'package:flutter/material.dart';

/// Central palette for the entire application.
///
/// Keeping every color in one place guarantees a consistent look and makes
/// theming (light/dark) trivial to maintain.
class AppColors {
  AppColors._();

  // Brand colors.
  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF06B6D4);

  // Semantic colors.
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Light theme surfaces.
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardLight = Colors.white;

  // Dark theme surfaces.
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);

  // Text colors.
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Misc.
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);

  /// Gradient used by the splash screen and prominent headers.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
}
