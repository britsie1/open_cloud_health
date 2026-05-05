import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/vital_log.dart';

class VitalsRepository {
  final DatabaseHelper _dbHelper;
  VitalsRepository(this._dbHelper);

  Future<List<VitalLog>> getLogs(String profileId, VitalType type) async {
    final db = await _dbHelper.getDatabase();
    final data = await db.query(
      'vital_logs',
      where: 'profileId = ? AND type = ?',
      whereArgs: [profileId, type.name],
      orderBy: 'date ASC',
    );

    return data.map((row) => VitalLog(
      id: row['id'] as String,
      profileId: row['profileId'] as String,
      type: VitalType.values.byName(row['type'] as String),
      date: DateTime.parse(row['date'] as String),
      value1: row['value1'] as double,
      value2: row['value2'] as double?,
      unit: row['unit'] as String,
      note: row['note'] as String?,
    )).toList();
  }

  Future<void> addLog(VitalLog log) async {
    final db = await _dbHelper.getDatabase();
    await db.insert('vital_logs', {
      'id': log.id,
      'profileId': log.profileId,
      'type': log.type.name,
      'date': log.date.toIso8601String(),
      'value1': log.value1,
      'value2': log.value2,
      'unit': log.unit,
      'note': log.note,
    });
  }

  Future<void> deleteLog(String id) async {
    final db = await _dbHelper.getDatabase();
    await db.delete('vital_logs', where: 'id = ?', whereArgs: [id]);
  }
}

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return VitalsRepository(dbHelper);
});
