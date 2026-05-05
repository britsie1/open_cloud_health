import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';

class PeriodRepository {
  final DatabaseHelper _dbHelper;
  PeriodRepository(this._dbHelper);

  Future<List<PeriodCycle>> getCycles(String profileId) async {
    final db = await _dbHelper.getDatabase();
    final data = await db.query(
      'period_cycles',
      where: 'profileId = ?',
      whereArgs: [profileId],
      orderBy: 'startDate DESC',
    );

    return data.map((row) => PeriodCycle(
      id: row['id'] as String,
      profileId: row['profileId'] as String,
      startDate: DateTime.parse(row['startDate'] as String),
      endDate: row['endDate'] != null ? DateTime.parse(row['endDate'] as String) : null,
    )).toList();
  }

  Future<void> addCycle(PeriodCycle cycle) async {
    final db = await _dbHelper.getDatabase();
    await db.insert('period_cycles', {
      'id': cycle.id,
      'profileId': cycle.profileId,
      'startDate': cycle.startDate.toIso8601String(),
      'endDate': cycle.endDate?.toIso8601String(),
    });
  }

  Future<void> updateCycle(PeriodCycle cycle) async {
    final db = await _dbHelper.getDatabase();
    await db.update(
      'period_cycles',
      {
        'startDate': cycle.startDate.toIso8601String(),
        'endDate': cycle.endDate?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [cycle.id],
    );
  }
  
  Future<void> deleteCycle(String id) async {
    final db = await _dbHelper.getDatabase();
    await db.delete('period_cycles', where: 'id = ?', whereArgs: [id]);
    await db.delete('period_logs', where: 'cycleId = ?', whereArgs: [id]);
  }

  Future<List<PeriodLog>> getLogsForCycle(String cycleId) async {
    final db = await _dbHelper.getDatabase();
    final data = await db.query(
      'period_logs',
      where: 'cycleId = ?',
      whereArgs: [cycleId],
      orderBy: 'date ASC',
    );

    return data.map((row) {
      final moodsStr = row['moods'] as String?;
      final List<Mood> moods = moodsStr != null && moodsStr.isNotEmpty
          ? moodsStr.split(',').map((e) => Mood.values.byName(e)).toList()
          : [];

      final physStr = row['physicalSymptoms'] as String?;
      final List<PhysicalSymptom> physicalSymptoms = physStr != null && physStr.isNotEmpty
          ? physStr.split(',').map((e) => PhysicalSymptom.values.byName(e)).toList()
          : [];

      return PeriodLog(
        id: row['id'] as String,
        cycleId: row['cycleId'] as String,
        date: DateTime.parse(row['date'] as String),
        flowLevel: row['flowLevel'] != null ? FlowLevel.values.byName(row['flowLevel'] as String) : null,
        moods: moods,
        physicalSymptoms: physicalSymptoms,
      );
    }).toList();
  }

  Future<void> upsertLog(PeriodLog log) async {
    final db = await _dbHelper.getDatabase();
    
    // Check if log exists for this date and cycle
    final dateStr = log.date.toIso8601String().split('T')[0];
    final existing = await db.query(
      'period_logs',
      where: 'cycleId = ? AND date LIKE ?',
      whereArgs: [log.cycleId, '$dateStr%'],
    );

    final map = {
      'id': existing.isNotEmpty ? existing.first['id'] : log.id,
      'cycleId': log.cycleId,
      'date': log.date.toIso8601String(),
      'flowLevel': log.flowLevel?.name,
      'moods': log.moods.map((e) => e.name).join(','),
      'physicalSymptoms': log.physicalSymptoms.map((e) => e.name).join(','),
    };

    if (existing.isNotEmpty) {
      await db.update('period_logs', map, where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      await db.insert('period_logs', map);
    }
  }
}

final periodRepositoryProvider = Provider<PeriodRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return PeriodRepository(dbHelper);
});
