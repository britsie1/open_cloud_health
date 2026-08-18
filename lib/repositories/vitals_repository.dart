import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/vital_log.dart';

class VitalsRepository {
  final AppDatabase _db;
  VitalsRepository(this._db);

  VitalLog _mapEntry(VitalLogEntry row) {
    return VitalLog(
      id: row.id,
      profileId: row.profileId,
      type: VitalType.values.byName(row.type),
      date: row.date,
      value1: row.value1,
      value2: row.value2,
      unit: row.unit,
      note: row.note,
    );
  }

  Future<List<VitalLog>> getLogs(String profileId, VitalType type) async {
    final query = _db.select(_db.vitalLogs)
      ..where((tbl) => tbl.profileId.equals(profileId) & tbl.type.equals(type.name))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.date)]);

    final data = await query.get();
    return data.map(_mapEntry).toList();
  }

  Stream<List<VitalLog>> watchLogs(String profileId, VitalType type) {
    final query = _db.select(_db.vitalLogs)
      ..where((tbl) => tbl.profileId.equals(profileId) & tbl.type.equals(type.name))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.date)]);

    return query.watch().map((data) => data.map(_mapEntry).toList());
  }

  Future<void> addLog(VitalLog log) async {
    await _db.into(_db.vitalLogs).insert(
      VitalLogEntry(
        id: log.id,
        profileId: log.profileId,
        type: log.type.name,
        date: log.date,
        value1: log.value1,
        value2: log.value2,
        unit: log.unit,
        note: log.note,
      ),
    );
  }

  Future<void> deleteLog(String id) async {
    await (_db.delete(_db.vitalLogs)..where((tbl) => tbl.id.equals(id))).go();
  }
}

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return VitalsRepository(db);
});
