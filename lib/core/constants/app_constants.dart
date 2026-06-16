/// Application-wide constant values (strings, durations, sizes).
///
/// Avoids "magic numbers/strings" scattered across the codebase.
class AppConstants {
  AppConstants._();

  // App metadata.
  static const String appName = 'TaskFlow';
  static const String appTagline = 'Organize your day, effortlessly';

  // Hive.
  static const String taskBoxName = 'tasks_box';

  // Durations.
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration shortAnimation = Duration(milliseconds: 250);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 700);

  // Spacing scale.
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  // Radius scale.
  static const double radiusSm = 8;
  static const double radiusMd = 16;
  static const double radiusLg = 24;

  // Responsive breakpoints.
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
}
