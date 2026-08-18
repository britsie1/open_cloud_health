import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';

class PeriodRepository {
  final AppDatabase _db;
  PeriodRepository(this._db);

  PeriodCycle _mapCycle(PeriodCycleEntry row) {
    return PeriodCycle(
      id: row.id,
      profileId: row.profileId,
      startDate: DateTime.parse(row.startDate),
      endDate: row.endDate != null ? DateTime.parse(row.endDate!) : null,
    );
  }

  PeriodLog _mapLog(PeriodLogEntry row) {
    final moodsStr = row.moods;
    final List<Mood> moods = moodsStr != null && moodsStr.isNotEmpty
        ? moodsStr.split(',').map((e) => Mood.values.byName(e)).toList()
        : [];

    final physStr = row.physicalSymptoms;
    final List<PhysicalSymptom> physicalSymptoms = physStr != null && physStr.isNotEmpty
        ? physStr.split(',').map((e) => PhysicalSymptom.values.byName(e)).toList()
        : [];

    return PeriodLog(
      id: row.id,
      cycleId: row.cycleId,
      date: DateTime.parse(row.date),
      flowLevel: row.flowLevel != null ? FlowLevel.values.byName(row.flowLevel!) : null,
      moods: moods,
      physicalSymptoms: physicalSymptoms,
    );
  }

  Future<List<PeriodCycle>> getCycles(String profileId) async {
    final query = _db.select(_db.periodCycles)
      ..where((tbl) => tbl.profileId.equals(profileId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.startDate)]);

    final data = await query.get();
    return data.map(_mapCycle).toList();
  }

  Stream<List<PeriodCycle>> watchCycles(String profileId) {
    final query = _db.select(_db.periodCycles)
      ..where((tbl) => tbl.profileId.equals(profileId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.startDate)]);

    return query.watch().map((data) => data.map(_mapCycle).toList());
  }

  Future<void> addCycle(PeriodCycle cycle) async {
    await _db.into(_db.periodCycles).insert(
      PeriodCycleEntry(
        id: cycle.id,
        profileId: cycle.profileId,
        startDate: cycle.startDate.toIso8601String(),
        endDate: cycle.endDate?.toIso8601String(),
      ),
    );
  }

  Future<void> updateCycle(PeriodCycle cycle) async {
    await _db.update(_db.periodCycles).replace(
      PeriodCycleEntry(
        id: cycle.id,
        profileId: cycle.profileId,
        startDate: cycle.startDate.toIso8601String(),
        endDate: cycle.endDate?.toIso8601String(),
      ),
    );
  }

  Future<void> deleteCycle(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.periodCycles)..where((tbl) => tbl.id.equals(id))).go();
      await (_db.delete(_db.periodLogs)..where((tbl) => tbl.cycleId.equals(id))).go();
    });
  }

  Future<List<PeriodLog>> getLogsForCycle(String cycleId) async {
    final query = _db.select(_db.periodLogs)
      ..where((tbl) => tbl.cycleId.equals(cycleId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.date)]);

    final data = await query.get();
    return data.map(_mapLog).toList();
  }

  Stream<List<PeriodLog>> watchLogsForCycle(String cycleId) {
    final query = _db.select(_db.periodLogs)
      ..where((tbl) => tbl.cycleId.equals(cycleId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.date)]);

    return query.watch().map((data) => data.map(_mapLog).toList());
  }

  Future<void> upsertLog(PeriodLog log) async {
    final dateStr = log.date.toIso8601String().split('T')[0];
    final existingQuery = _db.select(_db.periodLogs)
      ..where((tbl) => tbl.cycleId.equals(log.cycleId) & tbl.date.like('$dateStr%'));
    final existing = await existingQuery.getSingleOrNull();

    final entry = PeriodLogEntry(
      id: existing != null ? existing.id : log.id,
      cycleId: log.cycleId,
      date: log.date.toIso8601String(),
      flowLevel: log.flowLevel?.name,
      moods: log.moods.map((e) => e.name).join(','),
      physicalSymptoms: log.physicalSymptoms.map((e) => e.name).join(','),
    );

    if (existing != null) {
      await _db.update(_db.periodLogs).replace(entry);
    } else {
      await _db.into(_db.periodLogs).insert(entry);
    }
  }
}

final periodRepositoryProvider = Provider<PeriodRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PeriodRepository(db);
});
