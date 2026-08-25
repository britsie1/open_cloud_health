import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';

class WeightPreferences {
  const WeightPreferences({
    this.heightCm,
    this.targetWeightKg,
    this.unit = 'kg',
  });

  final double? heightCm;
  final double? targetWeightKg;
  final String unit; // 'kg' or 'lbs'

  WeightPreferences copyWith({
    double? heightCm,
    double? targetWeightKg,
    bool clearTargetWeight = false,
    String? unit,
  }) {
    return WeightPreferences(
      heightCm: heightCm ?? this.heightCm,
      targetWeightKg: clearTargetWeight ? null : (targetWeightKg ?? this.targetWeightKg),
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() => {
        'heightCm': heightCm,
        'targetWeightKg': targetWeightKg,
        'unit': unit,
      };

  factory WeightPreferences.fromJson(Map<String, dynamic> json) {
    return WeightPreferences(
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      unit: (json['unit'] as String?) ?? 'kg',
    );
  }
}

class WeightPreferencesNotifier
    extends FamilyAsyncNotifier<WeightPreferences, String> {
  AppDatabase get _db => ref.read(appDatabaseProvider);
  String get _settingKey => 'weight_preferences_$arg';

  @override
  Future<WeightPreferences> build(String arg) async {
    final query = _db.select(_db.settings)..where((tbl) => tbl.key.equals(_settingKey));
    final entry = await query.getSingleOrNull();
    if (entry != null && entry.value != null && entry.value!.isNotEmpty) {
      try {
        final decoded = jsonDecode(entry.value!) as Map<String, dynamic>;
        return WeightPreferences.fromJson(decoded);
      } catch (_) {
        return const WeightPreferences();
      }
    }
    return const WeightPreferences();
  }

  Future<void> setHeight(double? heightCm) async {
    final current = state.value ?? const WeightPreferences();
    final updated = current.copyWith(heightCm: heightCm);
    await _save(updated);
  }

  Future<void> setTargetWeight(double? targetKg) async {
    final current = state.value ?? const WeightPreferences();
    final updated = targetKg == null
        ? current.copyWith(clearTargetWeight: true)
        : current.copyWith(targetWeightKg: targetKg);
    await _save(updated);
  }

  Future<void> setUnit(String unit) async {
    final current = state.value ?? const WeightPreferences();
    final updated = current.copyWith(unit: unit);
    await _save(updated);
  }

  Future<void> _save(WeightPreferences prefs) async {
    final encoded = jsonEncode(prefs.toJson());
    await _db.into(_db.settings).insertOnConflictUpdate(
      SettingEntry(key: _settingKey, value: encoded),
    );
    state = AsyncValue.data(prefs);
  }
}

final weightPreferencesProvider = AsyncNotifierProvider.family<
    WeightPreferencesNotifier, WeightPreferences, String>(
  WeightPreferencesNotifier.new,
);
