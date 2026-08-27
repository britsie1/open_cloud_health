import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/theme/app_theme_data.dart';
import 'package:open_cloud_health/theme/app_theme_mode.dart';
import 'package:open_cloud_health/theme/app_theme_preset.dart';
import 'package:open_cloud_health/theme/theme_settings.dart';

/// Manages application-wide theme mode (System, Light, Dark) and theme palette preset.
class ThemeNotifier extends StateNotifier<ThemeSettings> {
  final SecureStorage _secureStorage;

  ThemeNotifier(this._secureStorage) : super(const ThemeSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final mode = await _secureStorage.getThemeMode();
      final presetId = await _secureStorage.getThemePreset();
      state = ThemeSettings(themeMode: mode, presetId: presetId);
    } catch (e) {
      debugPrint('Error loading theme settings: $e');
    }
  }

  /// Updates the theme mode (System, Light, Dark) and persists to secure storage.
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (state.themeMode == mode) return;
    state = state.copyWith(themeMode: mode);
    try {
      await _secureStorage.setThemeMode(mode);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  /// Updates the theme color preset / palette and persists to secure storage.
  Future<void> setThemePreset(String presetId) async {
    if (state.presetId == presetId) return;
    state = state.copyWith(presetId: presetId);
    try {
      await _secureStorage.setThemePreset(presetId);
    } catch (e) {
      debugPrint('Error saving theme preset: $e');
    }
  }
}

/// Provider managing active [ThemeSettings].
final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeSettings>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ThemeNotifier(secureStorage);
});

/// Alias provider for convenience.
final themeSettingsProvider = themeNotifierProvider;

/// Provider exposing the native Flutter [ThemeMode] for [MaterialApp.themeMode].
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return settings.themeMode.toFlutterThemeMode();
});

/// Provider exposing the resolved active [AppThemePreset].
final currentPresetProvider = Provider<AppThemePreset>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return settings.preset;
});

/// Computed [ThemeData] for Light theme based on active preset.
final lightThemeProvider = Provider<ThemeData>((ref) {
  final preset = ref.watch(currentPresetProvider);
  return AppThemeData.createLightTheme(preset);
});

/// Computed [ThemeData] for Dark theme based on active preset.
final darkThemeProvider = Provider<ThemeData>((ref) {
  final preset = ref.watch(currentPresetProvider);
  return AppThemeData.createDarkTheme(preset);
});
