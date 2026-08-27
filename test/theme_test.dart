import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/providers/theme_provider.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/theme/app_theme_data.dart';
import 'package:open_cloud_health/theme/app_theme_mode.dart';
import 'package:open_cloud_health/theme/app_theme_preset.dart';
import 'package:open_cloud_health/theme/theme_settings.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(AppThemeMode.system);
  });

  group('AppThemeMode Enum Tests', () {
    test('toFlutterThemeMode maps correctly', () {
      expect(AppThemeMode.system.toFlutterThemeMode(), ThemeMode.system);
      expect(AppThemeMode.light.toFlutterThemeMode(), ThemeMode.light);
      expect(AppThemeMode.dark.toFlutterThemeMode(), ThemeMode.dark);
    });

    test('fromString parses known and unknown values gracefully', () {
      expect(AppThemeMode.fromString('system'), AppThemeMode.system);
      expect(AppThemeMode.fromString('SYSTEM'), AppThemeMode.system);
      expect(AppThemeMode.fromString('light'), AppThemeMode.light);
      expect(AppThemeMode.fromString('Light'), AppThemeMode.light);
      expect(AppThemeMode.fromString('dark'), AppThemeMode.dark);
      expect(AppThemeMode.fromString('Dark'), AppThemeMode.dark);
      expect(AppThemeMode.fromString(null), AppThemeMode.system);
      expect(AppThemeMode.fromString('unknown_value'), AppThemeMode.system);
    });

    test('displayName, description, and icon are populated', () {
      for (final mode in AppThemeMode.values) {
        expect(mode.displayName.isNotEmpty, isTrue);
        expect(mode.description.isNotEmpty, isTrue);
        expect(mode.icon, isNotNull);
      }
    });
  });

  group('AppThemePreset & Registry Tests', () {
    test('AppThemePresets.all contains expected default palettes', () {
      expect(AppThemePresets.all.length, greaterThanOrEqualTo(6));
      expect(AppThemePresets.all.any((p) => p.id == 'ocean_blue'), isTrue);
      expect(AppThemePresets.all.any((p) => p.id == 'emerald_green'), isTrue);
      expect(AppThemePresets.all.any((p) => p.id == 'royal_purple'), isTrue);
      expect(AppThemePresets.all.any((p) => p.id == 'coral_sunset'), isTrue);
      expect(AppThemePresets.all.any((p) => p.id == 'rose_health'), isTrue);
      expect(AppThemePresets.all.any((p) => p.id == 'slate_monochrome'), isTrue);
    });

    test('AppThemePresets.fromId returns corresponding preset or default', () {
      expect(AppThemePresets.fromId('emerald_green').id, 'emerald_green');
      expect(AppThemePresets.fromId('royal_purple').name, 'Royal Purple');
      expect(AppThemePresets.fromId('non_existent').id, AppThemePresets.defaultPresetId);
      expect(AppThemePresets.fromId(null).id, AppThemePresets.defaultPresetId);
    });
  });

  group('AppThemeData Builder Tests', () {
    test('createLightTheme creates Light theme with Material 3 and preset primary color', () {
      const preset = AppThemePresets.emeraldGreen;
      final theme = AppThemeData.createLightTheme(preset);

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.primaryColor, preset.primaryColor);
      expect(theme.appBarTheme.backgroundColor, preset.primaryColor);
      expect(theme.cardTheme.color, Colors.white);
    });

    test('createDarkTheme creates Dark theme with dark surface and dark scaffold background', () {
      const preset = AppThemePresets.royalPurple;
      final theme = AppThemeData.createDarkTheme(preset);

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF121212));
      expect(theme.cardTheme.color, const Color(0xFF1E1E1E));
      expect(theme.appBarTheme.backgroundColor, const Color(0xFF1E1E1E));
    });
  });

  group('ThemeSettings Model Tests', () {
    test('Default constructor sets system mode and default preset', () {
      const settings = ThemeSettings();
      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.presetId, AppThemePresets.defaultPresetId);
      expect(settings.preset.id, AppThemePresets.defaultPresetId);
    });

    test('copyWith works correctly', () {
      const settings = ThemeSettings();
      final updated = settings.copyWith(
        themeMode: AppThemeMode.dark,
        presetId: 'coral_sunset',
      );
      expect(updated.themeMode, AppThemeMode.dark);
      expect(updated.presetId, 'coral_sunset');
      expect(updated.preset.id, 'coral_sunset');
    });
  });

  group('ThemeNotifier & Providers Tests', () {
    late MockSecureStorage mockSecureStorage;

    setUp(() {
      mockSecureStorage = MockSecureStorage();
      when(() => mockSecureStorage.getThemeMode())
          .thenAnswer((_) async => AppThemeMode.system);
      when(() => mockSecureStorage.getThemePreset())
          .thenAnswer((_) async => AppThemePresets.defaultPresetId);
      when(() => mockSecureStorage.setThemeMode(any()))
          .thenAnswer((_) async {});
      when(() => mockSecureStorage.setThemePreset(any()))
          .thenAnswer((_) async {});
    });

    test('ThemeNotifier loads saved settings on initialization', () async {
      when(() => mockSecureStorage.getThemeMode())
          .thenAnswer((_) async => AppThemeMode.dark);
      when(() => mockSecureStorage.getThemePreset())
          .thenAnswer((_) async => 'emerald_green');

      final notifier = ThemeNotifier(mockSecureStorage);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.themeMode, AppThemeMode.dark);
      expect(notifier.state.presetId, 'emerald_green');
    });

    test('setThemeMode updates state and persists to SecureStorage', () async {
      final notifier = ThemeNotifier(mockSecureStorage);
      await Future<void>.delayed(Duration.zero);

      await notifier.setThemeMode(AppThemeMode.light);

      expect(notifier.state.themeMode, AppThemeMode.light);
      verify(() => mockSecureStorage.setThemeMode(AppThemeMode.light)).called(1);
    });

    test('setThemePreset updates state and persists to SecureStorage', () async {
      final notifier = ThemeNotifier(mockSecureStorage);
      await Future<void>.delayed(Duration.zero);

      await notifier.setThemePreset('royal_purple');

      expect(notifier.state.presetId, 'royal_purple');
      verify(() => mockSecureStorage.setThemePreset('royal_purple')).called(1);
    });
  });

  group('Theme Reactive Widget Tests', () {
    testWidgets('App updates theme mode and palette dynamically via Riverpod',
        (WidgetTester tester) async {
      final mockSecureStorage = MockSecureStorage();
      when(() => mockSecureStorage.getThemeMode())
          .thenAnswer((_) async => AppThemeMode.light);
      when(() => mockSecureStorage.getThemePreset())
          .thenAnswer((_) async => AppThemePresets.defaultPresetId);
      when(() => mockSecureStorage.setThemeMode(any()))
          .thenAnswer((_) async {});
      when(() => mockSecureStorage.setThemePreset(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(mockSecureStorage),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              final lightTheme = ref.watch(lightThemeProvider);
              final darkTheme = ref.watch(darkThemeProvider);
              final themeMode = ref.watch(themeModeProvider);

              return MaterialApp(
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: themeMode,
                home: Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) {
                      final currentPreset = ref.watch(currentPresetProvider);
                      final currentMode = ref.watch(themeSettingsProvider).themeMode;
                      return Column(
                        children: [
                          Text('Current Mode: ${currentMode.name}'),
                          Text('Current Preset: ${currentPreset.name}'),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(themeNotifierProvider.notifier)
                                  .setThemeMode(AppThemeMode.dark);
                            },
                            child: const Text('Switch To Dark'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(themeNotifierProvider.notifier)
                                  .setThemePreset('emerald_green');
                            },
                            child: const Text('Switch To Emerald'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Current Mode: light'), findsOneWidget);
      expect(find.text('Current Preset: Ocean Blue'), findsOneWidget);

      // Tap Switch To Dark
      await tester.tap(find.text('Switch To Dark'));
      await tester.pumpAndSettle();

      expect(find.text('Current Mode: dark'), findsOneWidget);

      // Tap Switch To Emerald
      await tester.tap(find.text('Switch To Emerald'));
      await tester.pumpAndSettle();

      expect(find.text('Current Preset: Emerald Green'), findsOneWidget);
    });
  });
}
