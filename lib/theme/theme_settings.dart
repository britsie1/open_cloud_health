import 'package:open_cloud_health/theme/app_theme_mode.dart';
import 'package:open_cloud_health/theme/app_theme_preset.dart';

/// Immutable model representing the user's active theme configuration.
class ThemeSettings {
  final AppThemeMode themeMode;
  final String presetId;

  const ThemeSettings({
    this.themeMode = AppThemeMode.system,
    this.presetId = AppThemePresets.defaultPresetId,
  });

  /// Convenient getter for the resolved [AppThemePreset].
  AppThemePreset get preset => AppThemePresets.fromId(presetId);

  ThemeSettings copyWith({
    AppThemeMode? themeMode,
    String? presetId,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      presetId: presetId ?? this.presetId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeSettings &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          presetId == other.presetId;

  @override
  int get hashCode => themeMode.hashCode ^ presetId.hashCode;
}
