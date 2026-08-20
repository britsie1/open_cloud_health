import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/repositories/shared_profiles_repository.dart';

class PeriodRepository {
  final AppDatabase _db;
  final SharedProfilesRepository? _sharedRepo;
  PeriodRepository(this._db, [this._sharedRepo]);

  PeriodCycle _mapCycle(PeriodCycleEntry row) {
    return PeriodCycle(
      id: row.id,
      profileId: row.profileId,
      startDate: row.startDate,
      endDate: row.endDate,
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
      date: row.date,
      flowLevel: row.flowLevel != null ? FlowLevel.values.byName(row.flowLevel!) : null,
      moods: moods,
      physicalSymptoms: physicalSymptoms,
    );
  }

  Future<List<PeriodCycle>> getCycles(String profileId) async {
    if (_sharedRepo != null && await _sharedRepo.isSharedProfile(profileId)) {
      return _sharedRepo.getPeriodCycles(profileId);
    }
    final query = _db.select(_db.periodCycles)
      ..where((tbl) => tbl.profileId.equals(profileId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.startDate)]);

    final data = await query.get();
    return data.map(_mapCycle).toList();
  }

  Future<List<PeriodCycle>> fetchPeriodCycles(String profileId) => getCycles(profileId);

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
        startDate: cycle.startDate,
        endDate: cycle.endDate,
      ),
    );
  }

  Future<void> updateCycle(PeriodCycle cycle) async {
    await _db.update(_db.periodCycles).replace(
      PeriodCycleEntry(
        id: cycle.id,
        profileId: cycle.profileId,
        startDate: cycle.startDate,
        endDate: cycle.endDate,
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
    if (_sharedRepo != null) {
      final sharedLogs = await _sharedRepo.getPeriodLogs(cycleId);
      if (sharedLogs.isNotEmpty) return sharedLogs;
    }
    final query = _db.select(_db.periodLogs)
      ..where((tbl) => tbl.cycleId.equals(cycleId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.date)]);

    final data = await query.get();
    return data.map(_mapLog).toList();
  }

  Future<List<PeriodLog>> fetchPeriodLogs(String cycleId) => getLogsForCycle(cycleId);

  Stream<List<PeriodLog>> watchLogsForCycle(String cycleId) {
    final query = _db.select(_db.periodLogs)
      ..where((tbl) => tbl.cycleId.equals(cycleId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.date)]);

    return query.watch().map((data) => data.map(_mapLog).toList());
  }

  Future<void> upsertLog(PeriodLog log) async {
    final startOfDay = DateTime(log.date.year, log.date.month, log.date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final existingQuery = _db.select(_db.periodLogs)
      ..where((tbl) => tbl.cycleId.equals(log.cycleId) &
          tbl.date.isBiggerOrEqualValue(startOfDay) &
          tbl.date.isSmallerThanValue(endOfDay));
    final existing = await existingQuery.getSingleOrNull();

    final entry = PeriodLogEntry(
      id: existing != null ? existing.id : log.id,
      cycleId: log.cycleId,
      date: log.date,
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
  final sharedRepo = ref.watch(sharedProfilesRepositoryProvider);
  return PeriodRepository(db, sharedRepo);
});
