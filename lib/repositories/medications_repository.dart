import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';

class MedicationsRepository {
  final DatabaseHelper _dbHelper;
  MedicationsRepository(this._dbHelper);

  Future<List<Medication>> loadMedications(String profileId) async {
    final db = await _dbHelper.getDatabase();
    final data = await db.query('medications',
        where: 'profileId = ?', whereArgs: [profileId]);

    return data.map((row) {
      final daysOfWeekStr = row['daysOfWeek'] as String?;
      final List<int> daysOfWeek = daysOfWeekStr != null
          ? List<int>.from(jsonDecode(daysOfWeekStr))
          : const [1, 2, 3, 4, 5, 6, 7];

      final timesOfDayStr = row['timesOfDay'] as String?;
      final List<TimeOfDay> timesOfDay;
      if (timesOfDayStr != null) {
        final decoded = jsonDecode(timesOfDayStr) as List;
        timesOfDay = decoded.map((t) {
          final parts = (t as String).split(':');
          return TimeOfDay(
              hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }).toList();
      } else {
        final timeParts = (row['timeOfDay'] as String).split(':');
        timesOfDay = [
          TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          )
        ];
      }

      final timeParts = (row['timeOfDay'] as String).split(':');
      return Medication(
        id: row['id'] as String,
        profileId: row['profileId'] as String,
        name: row['name'] as String,
        dosage: row['dosage'] as String,
        type: row['type'] as String? ?? 'Other',
        notificationEnabled: row['notificationEnabled'] == 'true',
        alarmEnabled: row['alarmEnabled'] == 'true',
        timeOfDay: TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        ),
        isActive: row['isActive'] == 'true',
        daysOfWeek: daysOfWeek,
        timesOfDay: timesOfDay,
        isAsNeeded: row['isAsNeeded'] == 'true',
        trackInventory: row['trackInventory'] == 'true',
        stockQuantity: (row['stockQuantity'] as num?)?.toDouble() ?? 0.0,
        lowStockThreshold: (row['lowStockThreshold'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  Future<void> addMedication(Medication medication) async {
    final db = await _dbHelper.getDatabase();
    await db.insert('medications', {
      'id': medication.id,
      'profileId': medication.profileId,
      'name': medication.name,
      'dosage': medication.dosage,
      'type': medication.type,
      'notificationEnabled': medication.notificationEnabled.toString(),
      'alarmEnabled': medication.alarmEnabled.toString(),
      'timeOfDay': '${medication.timeOfDay.hour}:${medication.timeOfDay.minute}',
      'isActive': medication.isActive.toString(),
      'daysOfWeek': jsonEncode(medication.daysOfWeek),
      'timesOfDay': jsonEncode(medication.timesOfDay.map((t) => '${t.hour}:${t.minute}').toList()),
      'isAsNeeded': medication.isAsNeeded.toString(),
      'trackInventory': medication.trackInventory.toString(),
      'stockQuantity': medication.stockQuantity,
      'lowStockThreshold': medication.lowStockThreshold,
    });
  }

  Future<void> updateMedication(Medication medication) async {
    final db = await _dbHelper.getDatabase();
    await db.update(
        'medications',
        {
          'name': medication.name,
          'dosage': medication.dosage,
          'type': medication.type,
          'notificationEnabled': medication.notificationEnabled.toString(),
          'alarmEnabled': medication.alarmEnabled.toString(),
          'timeOfDay':
              '${medication.timeOfDay.hour}:${medication.timeOfDay.minute}',
          'isActive': medication.isActive.toString(),
          'daysOfWeek': jsonEncode(medication.daysOfWeek),
          'timesOfDay': jsonEncode(medication.timesOfDay.map((t) => '${t.hour}:${t.minute}').toList()),
          'isAsNeeded': medication.isAsNeeded.toString(),
          'trackInventory': medication.trackInventory.toString(),
          'stockQuantity': medication.stockQuantity,
          'lowStockThreshold': medication.lowStockThreshold,
        },
        where: 'id = ?',
        whereArgs: [medication.id]);
  }

  Future<void> deleteMedication(String id) async {
    final db = await _dbHelper.getDatabase();
    await db.delete('medications', where: 'id = ?', whereArgs: [id]);
    await db.delete('medication_logs', where: 'medicationId = ?', whereArgs: [id]);
  }

  Future<void> toggleIsActive(String id, bool isActive) async {
    final db = await _dbHelper.getDatabase();
    await db.update('medications', {'isActive': isActive.toString()},
        where: 'id = ?', whereArgs: [id]);
  }

  // Medication Logs
  Future<List<MedicationLog>> loadLogsForDate(
      DateTime date, String profileId) async {
    final db = await _dbHelper.getDatabase();
    final dateStr = date.toIso8601String().split('T')[0];

    final data = await db.rawQuery('''
      SELECT ml.* FROM medication_logs ml
      JOIN medications m ON ml.medicationId = m.id
      WHERE m.profileId = ? AND ml.timestamp LIKE ?
    ''', [profileId, '$dateStr%']);

    return data
        .map((row) => MedicationLog(
              id: row['id'] as String,
              medicationId: row['medicationId'] as String,
              timestamp: DateTime.parse(row['timestamp'] as String),
              isTaken: row['isTaken'] == 'true',
              dosage: row['dosage'] as String?,
            ))
        .toList();
  }

  Future<List<MedicationLog>> loadAllLogs(String profileId, {int limit = 20, int offset = 0}) async {
    final db = await _dbHelper.getDatabase();

    final data = await db.rawQuery('''
      SELECT ml.* FROM medication_logs ml
      JOIN medications m ON ml.medicationId = m.id
      WHERE m.profileId = ?
      ORDER BY ml.timestamp DESC
      LIMIT ? OFFSET ?
    ''', [profileId, limit, offset]);

    return data
        .map((row) => MedicationLog(
              id: row['id'] as String,
              medicationId: row['medicationId'] as String,
              timestamp: DateTime.parse(row['timestamp'] as String),
              isTaken: row['isTaken'] == 'true',
              dosage: row['dosage'] as String?,
            ))
        .toList();
  }

  Future<void> addLog(MedicationLog log) async {
    final db = await _dbHelper.getDatabase();
    await db.insert('medication_logs', {
      'id': log.id,
      'medicationId': log.medicationId,
      'timestamp': log.timestamp.toIso8601String(),
      'isTaken': log.isTaken.toString(),
      'dosage': log.dosage,
    });

    // Decrement stock if trackInventory is enabled
    final List<Map<String, dynamic>> meds = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [log.medicationId],
    );
    if (meds.isNotEmpty) {
      final med = meds.first;
      final trackInventory = med['trackInventory'] == 'true';
      if (trackInventory) {
        final currentStock = (med['stockQuantity'] as num?)?.toDouble() ?? 0.0;
        final dosageToParse = (log.dosage != null && log.dosage!.trim().isNotEmpty)
            ? log.dosage!
            : (med['dosage'] as String? ?? '');
        final decrementVal = parseDosageQuantity(dosageToParse);
        final newStock = (currentStock - decrementVal).clamp(0.0, double.infinity);
        await db.update(
          'medications',
          {'stockQuantity': newStock},
          where: 'id = ?',
          whereArgs: [log.medicationId],
        );
      }
    }
  }

  Future<void> removeLog(String medicationId, DateTime date, {TimeOfDay? time}) async {
    final db = await _dbHelper.getDatabase();
    final dateStr = date.toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> logsToDelete;
    if (time != null) {
      final hourStr = time.hour.toString().padLeft(2, '0');
      final minuteStr = time.minute.toString().padLeft(2, '0');
      logsToDelete = await db.query(
        'medication_logs',
        where: 'medicationId = ? AND timestamp LIKE ?',
        whereArgs: [medicationId, '${dateStr}T$hourStr:$minuteStr%'],
      );
    } else {
      logsToDelete = await db.query(
        'medication_logs',
        where: 'medicationId = ? AND timestamp LIKE ?',
        whereArgs: [medicationId, '$dateStr%'],
      );
    }

    final deleteCount = logsToDelete.length;

    if (time != null) {
      final hourStr = time.hour.toString().padLeft(2, '0');
      final minuteStr = time.minute.toString().padLeft(2, '0');
      await db.delete('medication_logs',
          where: 'medicationId = ? AND timestamp LIKE ?',
          whereArgs: [medicationId, '${dateStr}T$hourStr:$minuteStr%']);
    } else {
      await db.delete('medication_logs',
          where: 'medicationId = ? AND timestamp LIKE ?',
          whereArgs: [medicationId, '$dateStr%']);
    }

    if (deleteCount > 0) {
      final List<Map<String, dynamic>> meds = await db.query(
        'medications',
        where: 'id = ?',
        whereArgs: [medicationId],
      );
      if (meds.isNotEmpty) {
        final med = meds.first;
        final trackInventory = med['trackInventory'] == 'true';
        if (trackInventory) {
          final currentStock = (med['stockQuantity'] as num?)?.toDouble() ?? 0.0;
          double totalIncrement = 0.0;
          for (final log in logsToDelete) {
            final logDosage = log['dosage'] as String?;
            final dosageToParse = (logDosage != null && logDosage.trim().isNotEmpty)
                ? logDosage
                : (med['dosage'] as String? ?? '');
            totalIncrement += parseDosageQuantity(dosageToParse);
          }
          final newStock = currentStock + totalIncrement;
          await db.update(
            'medications',
            {'stockQuantity': newStock},
            where: 'id = ?',
            whereArgs: [medicationId],
          );
        }
      }
    }
  }
}

final medicationsRepositoryProvider = Provider<MedicationsRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return MedicationsRepository(dbHelper);
});
