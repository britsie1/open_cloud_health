import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';

class MedicationsRepository {
  Future<List<Medication>> loadMedications(String profileId) async {
    final db = await getDatabase();
    final data = await db.query(
      'medications',
      where: 'profileId = ?',
      whereArgs: [profileId],
    );

    return data.map((row) {
      final timeParts = (row['timeOfDay'] as String).split(':');
      return Medication(
        id: row['id'] as String,
        profileId: row['profileId'] as String,
        name: row['name'] as String,
        dosage: row['dosage'] as String,
        timeOfDay: TimeOfDay(
            hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
        isActive: row['isActive'] == 'true',
      );
    }).toList();
  }

  Future<void> addMedication(Medication medication) async {
    final db = await getDatabase();
    await db.insert('medications', {
      'id': medication.id,
      'profileId': medication.profileId,
      'name': medication.name,
      'dosage': medication.dosage,
      'timeOfDay': medication.timeFormatted,
      'isActive': medication.isActive.toString(),
    });
  }

  Future<void> updateMedication(Medication medication) async {
    final db = await getDatabase();
    await db.update(
      'medications',
      {
        'name': medication.name,
        'dosage': medication.dosage,
        'timeOfDay': medication.timeFormatted,
        'isActive': medication.isActive.toString(),
      },
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<void> toggleIsActive(String id, bool isActive) async {
    final db = await getDatabase();
    await db.update(
        'medications',
        {'isActive': isActive.toString()},
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> deleteMedication(String id) async {
    final db = await getDatabase();
    await db.delete('medications', where: 'id = ?', whereArgs: [id]);
    await db.delete('medication_logs', where: 'medicationId = ?', whereArgs: [id]);
  }

  Future<List<MedicationLog>> loadLogsForDate(DateTime date, String profileId) async {
    final db = await getDatabase();
    final dateStr = date.toIso8601String().split('T')[0];
    
    final data = await db.rawQuery('''
      SELECT l.* FROM medication_logs l
      JOIN medications m ON l.medicationId = m.id
      WHERE m.profileId = ? AND l.timestamp LIKE ?
    ''', [profileId, '$dateStr%']);

    return data.map((row) {
      return MedicationLog(
        id: row['id'] as String,
        medicationId: row['medicationId'] as String,
        timestamp: DateTime.parse(row['timestamp'] as String),
        isTaken: row['isTaken'] == 'true',
      );
    }).toList();
  }

  Future<void> addLog(MedicationLog log) async {
    final db = await getDatabase();
    await db.insert('medication_logs', {
      'id': log.id,
      'medicationId': log.medicationId,
      'timestamp': log.timestamp.toIso8601String(),
      'isTaken': log.isTaken.toString(),
    });
  }

  Future<void> removeLog(String medicationId, DateTime date) async {
    final db = await getDatabase();
    final dateStr = date.toIso8601String().split('T')[0];
    
    await db.rawDelete('''
      DELETE FROM medication_logs 
      WHERE medicationId = ? AND timestamp LIKE ?
    ''', [medicationId, '$dateStr%']);
  }
}

final medicationsRepositoryProvider = Provider<MedicationsRepository>((ref) {
  return MedicationsRepository();
});
