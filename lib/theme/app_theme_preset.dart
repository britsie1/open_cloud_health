import 'package:flutter/material.dart';

/// Represents a distinct visual theme preset with its own primary brand color
/// and styling rules. This allows adding custom color schemes and themes easily.
class AppThemePreset {
  final String id;
  final String name;
  final Color primaryColor;
  final String description;
  final IconData icon;

  const AppThemePreset({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.description,
    this.icon = Icons.circle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemePreset &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Registry of available theme presets. New themes can easily be added here.
class AppThemePresets {
  static const String defaultPresetId = 'ocean_blue';

  static const oceanBlue = AppThemePreset(
    id: 'ocean_blue',
    name: 'Ocean Blue',
    primaryColor: Color(0xFF1976D2), // Classic Health Blue
    description: 'Default calm medical blue theme',
    icon: Icons.water_drop_outlined,
  );

  static const emeraldGreen = AppThemePreset(
    id: 'emerald_green',
    name: 'Emerald Green',
    primaryColor: Color(0xFF00897B), // Teal / Emerald
    description: 'Fresh health and wellness theme',
    icon: Icons.eco_outlined,
  );

  static const royalPurple = AppThemePreset(
    id: 'royal_purple',
    name: 'Royal Purple',
    primaryColor: Color(0xFF6750A4), // Calming Lavender / Purple
    description: 'Gentle mindfulness and care theme',
    icon: Icons.spa_outlined,
  );

  static const coralSunset = AppThemePreset(
    id: 'coral_sunset',
    name: 'Coral Sunset',
    primaryColor: Color(0xFFE65100), // Warm Coral / Amber
    description: 'Warm energetic vitality theme',
    icon: Icons.wb_sunny_outlined,
  );

  static const roseHealth = AppThemePreset(
    id: 'rose_health',
    name: 'Rose Care',
    primaryColor: Color(0xFFD81B60), // Rose Pink
    description: 'Compassionate soft rose theme',
    icon: Icons.favorite_border,
  );

  static const slateMonochrome = AppThemePreset(
    id: 'slate_monochrome',
    name: 'Slate Slate',
    primaryColor: Color(0xFF455A64), // Neutral Blue Grey
    description: 'Clean minimalist slate theme',
    icon: Icons.shield_outlined,
  );

  /// All registered theme presets available for user selection.
  static const List<AppThemePreset> all = [
    oceanBlue,
    emeraldGreen,
    royalPurple,
    coralSunset,
    roseHealth,
    slateMonochrome,
  ];

  /// Finds a preset by its ID, defaulting to [oceanBlue] if not found.
  static AppThemePreset fromId(String? id) {
    if (id == null) return oceanBlue;
    return all.firstWhere(
      (preset) => preset.id == id,
      orElse: () => oceanBlue,
    );
  }
}
