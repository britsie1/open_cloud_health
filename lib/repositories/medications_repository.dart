import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';

class MedicationsRepository {
  final AppDatabase _db;
  MedicationsRepository(this._db);

  Medication _mapMedication(MedicationEntry row) {
    final daysOfWeekStr = row.daysOfWeek;
    final List<int> daysOfWeek = daysOfWeekStr != null
        ? List<int>.from(jsonDecode(daysOfWeekStr))
        : const [1, 2, 3, 4, 5, 6, 7];

    final timesOfDayStr = row.timesOfDay;
    final List<TimeOfDay> timesOfDay;
    if (timesOfDayStr != null) {
      final decoded = jsonDecode(timesOfDayStr) as List;
      timesOfDay = decoded.map((t) {
        final parts = (t as String).split(':');
        return TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
    } else {
      final timeParts = row.timeOfDay.split(':');
      timesOfDay = [
        TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        )
      ];
    }

    final timeParts = row.timeOfDay.split(':');
    return Medication(
      id: row.id,
      profileId: row.profileId,
      name: row.name,
      dosage: row.dosage,
      type: row.type ?? 'Other',
      notificationEnabled: row.notificationEnabled == 'true',
      alarmEnabled: row.alarmEnabled == 'true',
      timeOfDay: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      isActive: row.isActive == 'true',
      daysOfWeek: daysOfWeek,
      timesOfDay: timesOfDay,
      isAsNeeded: row.isAsNeeded == 'true',
      trackInventory: row.trackInventory == 'true',
      stockQuantity: row.stockQuantity ?? 0.0,
      lowStockThreshold: row.lowStockThreshold ?? 0.0,
    );
  }

  MedicationLog _mapMedicationLog(MedicationLogEntry row) {
    return MedicationLog(
      id: row.id,
      medicationId: row.medicationId,
      timestamp: DateTime.parse(row.timestamp),
      isTaken: row.isTaken == 'true',
      dosage: row.dosage,
    );
  }

  Future<List<Medication>> loadMedications(String profileId) async {
    final query = _db.select(_db.medications)
      ..where((tbl) => tbl.profileId.equals(profileId));
    final data = await query.get();
    return data.map(_mapMedication).toList();
  }

  Stream<List<Medication>> watchMedications(String profileId) {
    final query = _db.select(_db.medications)
      ..where((tbl) => tbl.profileId.equals(profileId));
    return query.watch().map((data) => data.map(_mapMedication).toList());
  }

  Future<void> addMedication(Medication medication) async {
    await _db.into(_db.medications).insert(
      MedicationEntry(
        id: medication.id,
        profileId: medication.profileId,
        name: medication.name,
        dosage: medication.dosage,
        type: medication.type,
        notificationEnabled: medication.notificationEnabled.toString(),
        alarmEnabled: medication.alarmEnabled.toString(),
        timeOfDay: '${medication.timeOfDay.hour}:${medication.timeOfDay.minute}',
        isActive: medication.isActive.toString(),
        daysOfWeek: jsonEncode(medication.daysOfWeek),
        timesOfDay: jsonEncode(medication.timesOfDay.map((t) => '${t.hour}:${t.minute}').toList()),
        isAsNeeded: medication.isAsNeeded.toString(),
        trackInventory: medication.trackInventory.toString(),
        stockQuantity: medication.stockQuantity,
        lowStockThreshold: medication.lowStockThreshold,
      ),
    );
  }

  Future<void> updateMedication(Medication medication) async {
    await _db.update(_db.medications).replace(
      MedicationEntry(
        id: medication.id,
        profileId: medication.profileId,
        name: medication.name,
        dosage: medication.dosage,
        type: medication.type,
        notificationEnabled: medication.notificationEnabled.toString(),
        alarmEnabled: medication.alarmEnabled.toString(),
        timeOfDay: '${medication.timeOfDay.hour}:${medication.timeOfDay.minute}',
        isActive: medication.isActive.toString(),
        daysOfWeek: jsonEncode(medication.daysOfWeek),
        timesOfDay: jsonEncode(medication.timesOfDay.map((t) => '${t.hour}:${t.minute}').toList()),
        isAsNeeded: medication.isAsNeeded.toString(),
        trackInventory: medication.trackInventory.toString(),
        stockQuantity: medication.stockQuantity,
        lowStockThreshold: medication.lowStockThreshold,
      ),
    );
  }

  Future<void> deleteMedication(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.medications)..where((tbl) => tbl.id.equals(id))).go();
      await (_db.delete(_db.medicationLogs)..where((tbl) => tbl.medicationId.equals(id))).go();
    });
  }

  Future<void> toggleIsActive(String id, bool isActive) async {
    await (_db.update(_db.medications)..where((tbl) => tbl.id.equals(id)))
        .write(MedicationsCompanion(isActive: Value(isActive.toString())));
  }

  // --- Medication Logs ---

  Future<List<MedicationLog>> loadLogsForDate(DateTime date, String profileId) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final query = _db.select(_db.medicationLogs).join([
      innerJoin(_db.medications, _db.medications.id.equalsExp(_db.medicationLogs.medicationId)),
    ])
      ..where(_db.medications.profileId.equals(profileId) & _db.medicationLogs.timestamp.like('$dateStr%'));

    final rows = await query.get();
    return rows.map((r) => _mapMedicationLog(r.readTable(_db.medicationLogs))).toList();
  }

  Stream<List<MedicationLog>> watchLogsForDate(DateTime date, String profileId) {
    final dateStr = date.toIso8601String().split('T')[0];
    final query = _db.select(_db.medicationLogs).join([
      innerJoin(_db.medications, _db.medications.id.equalsExp(_db.medicationLogs.medicationId)),
    ])
      ..where(_db.medications.profileId.equals(profileId) & _db.medicationLogs.timestamp.like('$dateStr%'));

    return query.watch().map((rows) => rows.map((r) => _mapMedicationLog(r.readTable(_db.medicationLogs))).toList());
  }

  Future<List<MedicationLog>> loadAllLogs(String profileId, {int limit = 20, int offset = 0}) async {
    final query = _db.select(_db.medicationLogs).join([
      innerJoin(_db.medications, _db.medications.id.equalsExp(_db.medicationLogs.medicationId)),
    ])
      ..where(_db.medications.profileId.equals(profileId))
      ..orderBy([OrderingTerm.desc(_db.medicationLogs.timestamp)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map((r) => _mapMedicationLog(r.readTable(_db.medicationLogs))).toList();
  }

  Stream<List<MedicationLog>> watchAllLogs(String profileId, {int limit = 20, int offset = 0}) {
    final query = _db.select(_db.medicationLogs).join([
      innerJoin(_db.medications, _db.medications.id.equalsExp(_db.medicationLogs.medicationId)),
    ])
      ..where(_db.medications.profileId.equals(profileId))
      ..orderBy([OrderingTerm.desc(_db.medicationLogs.timestamp)])
      ..limit(limit, offset: offset);

    return query.watch().map((rows) => rows.map((r) => _mapMedicationLog(r.readTable(_db.medicationLogs))).toList());
  }

  Future<void> addLog(MedicationLog log) async {
    await _db.transaction(() async {
      await _db.into(_db.medicationLogs).insert(
        MedicationLogEntry(
          id: log.id,
          medicationId: log.medicationId,
          timestamp: log.timestamp.toIso8601String(),
          isTaken: log.isTaken.toString(),
          dosage: log.dosage,
        ),
      );

      // Decrement stock if trackInventory is enabled
      final med = await (_db.select(_db.medications)..where((tbl) => tbl.id.equals(log.medicationId))).getSingleOrNull();
      if (med != null && med.trackInventory == 'true') {
        final currentStock = med.stockQuantity ?? 0.0;
        final dosageToParse = (log.dosage != null && log.dosage!.trim().isNotEmpty)
            ? log.dosage!
            : med.dosage;
        final decrementVal = parseDosageQuantity(dosageToParse);
        final newStock = (currentStock - decrementVal).clamp(0.0, double.infinity);
        await (_db.update(_db.medications)..where((tbl) => tbl.id.equals(log.medicationId)))
            .write(MedicationsCompanion(stockQuantity: Value(newStock)));
      }
    });
  }

  Future<void> removeLog(String medicationId, DateTime date, {TimeOfDay? time}) async {
    await _db.transaction(() async {
      final dateStr = date.toIso8601String().split('T')[0];
      final matchPattern = time != null
          ? '${dateStr}T${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}%'
          : '$dateStr%';

      final deleteQuery = _db.select(_db.medicationLogs)
        ..where((tbl) => tbl.medicationId.equals(medicationId) & tbl.timestamp.like(matchPattern));
      final logsToDelete = await deleteQuery.get();

      if (logsToDelete.isNotEmpty) {
        await (_db.delete(_db.medicationLogs)
              ..where((tbl) => tbl.medicationId.equals(medicationId) & tbl.timestamp.like(matchPattern)))
            .go();

        final med = await (_db.select(_db.medications)..where((tbl) => tbl.id.equals(medicationId))).getSingleOrNull();
        if (med != null && med.trackInventory == 'true') {
          final currentStock = med.stockQuantity ?? 0.0;
          double totalIncrement = 0.0;
          for (final log in logsToDelete) {
            final dosageToParse = (log.dosage != null && log.dosage!.trim().isNotEmpty)
                ? log.dosage!
                : med.dosage;
            totalIncrement += parseDosageQuantity(dosageToParse);
          }
          final newStock = currentStock + totalIncrement;
          await (_db.update(_db.medications)..where((tbl) => tbl.id.equals(medicationId)))
              .write(MedicationsCompanion(stockQuantity: Value(newStock)));
        }
      }
    });
  }
}

final medicationsRepositoryProvider = Provider<MedicationsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MedicationsRepository(db);
});
