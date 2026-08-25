import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/providers/weight_preferences_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WeightPreferences Provider Integration Tests', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('Loads default preferences when none stored', () async {
      final prefs = await container.read(weightPreferencesProvider('prof-1').future);
      expect(prefs.heightCm, isNull);
      expect(prefs.targetWeightKg, isNull);
      expect(prefs.unit, 'kg');
    });

    test('Saves and reads height, target weight, and unit preferences', () async {
      final notifier = container.read(weightPreferencesProvider('prof-1').notifier);
      await notifier.setHeight(178.0);
      await notifier.setTargetWeight(72.5);
      await notifier.setUnit('kg');

      final updated = await container.read(weightPreferencesProvider('prof-1').future);
      expect(updated.heightCm, 178.0);
      expect(updated.targetWeightKg, 72.5);
      expect(updated.unit, 'kg');

      // Clear target weight
      await notifier.setTargetWeight(null);
      final cleared = await container.read(weightPreferencesProvider('prof-1').future);
      expect(cleared.heightCm, 178.0);
      expect(cleared.targetWeightKg, isNull);
    });
  });
}
