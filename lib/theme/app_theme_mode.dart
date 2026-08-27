import 'package:flutter/material.dart';

/// Represents the active theme mode preference for the application.
enum AppThemeMode {
  system,
  light,
  dark;

  /// Converts this [AppThemeMode] to Flutter's native [ThemeMode].
  ThemeMode toFlutterThemeMode() {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// User-friendly display title.
  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return 'System Default';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  /// Explanatory subtitle for settings UI.
  String get description {
    switch (this) {
      case AppThemeMode.system:
        return 'Follows your device dark mode settings';
      case AppThemeMode.light:
        return 'Classic bright appearance';
      case AppThemeMode.dark:
        return 'Easy on the eyes in low light';
    }
  }

  /// Icon representing this mode.
  IconData get icon {
    switch (this) {
      case AppThemeMode.system:
        return Icons.brightness_auto_outlined;
      case AppThemeMode.light:
        return Icons.light_mode_outlined;
      case AppThemeMode.dark:
        return Icons.dark_mode_outlined;
    }
  }

  /// Parses an [AppThemeMode] from a stored string value.
  static AppThemeMode fromString(String? value) {
    if (value == null) return AppThemeMode.system;
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AppThemeMode.system,
    );
  }
}
