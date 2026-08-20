import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/checkup.dart';
import 'package:open_cloud_health/models/checkup_log.dart';
import 'package:open_cloud_health/repositories/shared_profiles_repository.dart';

class CheckupsRepository {
  final AppDatabase _db;
  final SharedProfilesRepository? _sharedRepo;
  CheckupsRepository(this._db, [this._sharedRepo]);

  Checkup _mapCheckup(CheckupEntry row) {
    return Checkup(
      id: row.id,
      profileId: row.profileId,
      name: row.name,
      frequencyInMonths: row.frequencyInMonths,
      iconName: row.iconName,
      isCustomInterval: row.isCustomInterval ?? false,
      isActive: row.isActive ?? true,
    );
  }

  CheckupLog _mapLog(CheckupLogEntry row) {
    return CheckupLog(
      id: row.id,
      checkupId: row.checkupId,
      dateCompleted: row.dateCompleted,
      location: row.location,
      doctorName: row.doctorName,
      notes: row.notes,
    );
  }

  Future<List<Checkup>> loadCheckups(String profileId) async {
    if (_sharedRepo != null && await _sharedRepo.isSharedProfile(profileId)) {
      return _sharedRepo.getCheckups(profileId);
    }
    final query = _db.select(_db.checkups)
      ..where((tbl) => tbl.profileId.equals(profileId));
    final data = await query.get();
    return data.map(_mapCheckup).toList();
  }

  Future<List<Checkup>> fetchCheckups(String profileId) => loadCheckups(profileId);

  Stream<List<Checkup>> watchCheckups(String profileId) {
    final query = _db.select(_db.checkups)
      ..where((tbl) => tbl.profileId.equals(profileId));
    return query.watch().map((data) => data.map(_mapCheckup).toList());
  }

  Future<void> addCheckup(Checkup checkup) async {
    await _db.into(_db.checkups).insert(
      CheckupEntry(
        id: checkup.id,
        profileId: checkup.profileId,
        name: checkup.name,
        frequencyInMonths: checkup.frequencyInMonths,
        iconName: checkup.iconName,
        isCustomInterval: checkup.isCustomInterval,
        isActive: checkup.isActive,
      ),
    );
  }

  Future<void> updateCheckup(Checkup checkup) async {
    await _db.update(_db.checkups).replace(
      CheckupEntry(
        id: checkup.id,
        profileId: checkup.profileId,
        name: checkup.name,
        frequencyInMonths: checkup.frequencyInMonths,
        iconName: checkup.iconName,
        isCustomInterval: checkup.isCustomInterval,
        isActive: checkup.isActive,
      ),
    );
  }

  Future<void> deleteCheckup(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.checkups)..where((tbl) => tbl.id.equals(id))).go();
      await (_db.delete(_db.checkupLogs)..where((tbl) => tbl.checkupId.equals(id))).go();
    });
  }

  Future<CheckupLog?> getLatestLogForCheckup(String checkupId) async {
    final query = _db.select(_db.checkupLogs)
      ..where((tbl) => tbl.checkupId.equals(checkupId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.dateCompleted)])
      ..limit(1);

    final row = await query.getSingleOrNull();
    return row != null ? _mapLog(row) : null;
  }

  Stream<CheckupLog?> watchLatestLogForCheckup(String checkupId) {
    final query = _db.select(_db.checkupLogs)
      ..where((tbl) => tbl.checkupId.equals(checkupId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.dateCompleted)])
      ..limit(1);

    return query.watchSingleOrNull().map((row) => row != null ? _mapLog(row) : null);
  }

  Future<void> addCheckupLog(CheckupLog log) async {
    await _db.into(_db.checkupLogs).insert(
      CheckupLogEntry(
        id: log.id,
        checkupId: log.checkupId,
        dateCompleted: log.dateCompleted,
        location: log.location,
        doctorName: log.doctorName,
        notes: log.notes,
      ),
    );
  }

  Future<List<CheckupLog>> loadAllLogsForProfile(String profileId) async {
    final query = _db.select(_db.checkupLogs).join([
      innerJoin(_db.checkups, _db.checkups.id.equalsExp(_db.checkupLogs.checkupId)),
    ])..where(_db.checkups.profileId.equals(profileId));

    final rows = await query.get();
    return rows.map((r) => _mapLog(r.readTable(_db.checkupLogs))).toList();
  }

  Stream<List<CheckupLog>> watchAllLogsForProfile(String profileId) {
    final query = _db.select(_db.checkupLogs).join([
      innerJoin(_db.checkups, _db.checkups.id.equalsExp(_db.checkupLogs.checkupId)),
    ])..where(_db.checkups.profileId.equals(profileId));

    return query.watch().map((rows) => rows.map((r) => _mapLog(r.readTable(_db.checkupLogs))).toList());
  }

  Future<List<CheckupLog>> loadLogsForCheckup(String checkupId) async {
    if (_sharedRepo != null) {
      final sharedLogs = await _sharedRepo.getCheckupLogs(checkupId);
      if (sharedLogs.isNotEmpty) return sharedLogs;
    }
    final query = _db.select(_db.checkupLogs)
      ..where((tbl) => tbl.checkupId.equals(checkupId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.dateCompleted)]);

    final rows = await query.get();
    return rows.map(_mapLog).toList();
  }

  Future<List<CheckupLog>> fetchCheckupLogs(String checkupId) => loadLogsForCheckup(checkupId);

  Stream<List<CheckupLog>> watchLogsForCheckup(String checkupId) {
    final query = _db.select(_db.checkupLogs)
      ..where((tbl) => tbl.checkupId.equals(checkupId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.dateCompleted)]);

    return query.watch().map((rows) => rows.map(_mapLog).toList());
  }

  Future<void> deleteCheckupLog(String logId) async {
    await (_db.delete(_db.checkupLogs)..where((tbl) => tbl.id.equals(logId))).go();
  }
}

final checkupsRepositoryProvider = Provider<CheckupsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sharedRepo = ref.watch(sharedProfilesRepositoryProvider);
  return CheckupsRepository(db, sharedRepo);
});
