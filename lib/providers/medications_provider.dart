import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/services/notification_service.dart';

class MedicationsNotifier extends StateNotifier<List<Medication>> {
  MedicationsNotifier() : super(const []);

  Future<void> loadMedications(String profileId) async {
    final db = await getDatabase();
    final data = await db.query(
      'medications',
      where: 'profileId = ?',
      whereArgs: [profileId],
    );

    final medications = data.map((row) {
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

    state = medications;
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

    state = [...state, medication];

    // Schedule notification using hash of ID for integer ID
    final notificationId = medication.id.hashCode;
    await NotificationService().scheduleDailyNotification(
      notificationId,
      'Medication Reminder',
      'Time to take your medication: ${medication.name} (${medication.dosage})',
      medication.timeOfDay,
    );
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

    state = state.map((m) {
      if (m.id == medication.id) {
        return medication;
      }
      return m;
    }).toList();

    // Cancel old notification and reschedule with updated details
    await NotificationService().cancelNotification(medication.id.hashCode);
    if (medication.isActive) {
      await NotificationService().scheduleDailyNotification(
        medication.id.hashCode,
        'Medication Reminder',
        'Time to take your medication: ${medication.name} (${medication.dosage})',
        medication.timeOfDay,
      );
    }
  }

  Future<void> deleteMedication(String id) async {
    final db = await getDatabase();
    await db.delete('medications', where: 'id = ?', whereArgs: [id]);
    await db.delete('medication_logs', where: 'medicationId = ?', whereArgs: [id]);

    state = state.where((m) => m.id != id).toList();

    // Cancel notification
    await NotificationService().cancelNotification(id.hashCode);
  }
  
  Future<void> toggleIsActive(Medication medication) async {
    final newIsActive = !medication.isActive;
    final db = await getDatabase();
    await db.update(
        'medications',
        {'isActive': newIsActive.toString()},
        where: 'id = ?',
        whereArgs: [medication.id]);
        
    state = state.map((m) {
      if (m.id == medication.id) {
        return Medication(
            id: m.id,
            profileId: m.profileId,
            name: m.name,
            dosage: m.dosage,
            timeOfDay: m.timeOfDay,
            isActive: newIsActive);
      }
      return m;
    }).toList();

    if (newIsActive) {
      await NotificationService().scheduleDailyNotification(
        medication.id.hashCode,
        'Medication Reminder',
        'Time to take your medication: ${medication.name} (${medication.dosage})',
        medication.timeOfDay,
      );
    } else {
      await NotificationService().cancelNotification(medication.id.hashCode);
    }
  }
}

final medicationsProvider =
    StateNotifierProvider<MedicationsNotifier, List<Medication>>((ref) {
  return MedicationsNotifier();
});

class MedicationLogsNotifier extends StateNotifier<List<MedicationLog>> {
  MedicationLogsNotifier() : super(const []);

  Future<void> loadLogsForDate(DateTime date, String profileId) async {
    final db = await getDatabase();
    
    // For simplicity, we just fetch logs for medications that belong to the profile
    final dateStr = date.toIso8601String().split('T')[0]; // simple matching
    
    final data = await db.rawQuery('''
      SELECT l.* FROM medication_logs l
      JOIN medications m ON l.medicationId = m.id
      WHERE m.profileId = ? AND l.timestamp LIKE ?
    ''', [profileId, '$dateStr%']);

    final logs = data.map((row) {
      return MedicationLog(
        id: row['id'] as String,
        medicationId: row['medicationId'] as String,
        timestamp: DateTime.parse(row['timestamp'] as String),
        isTaken: row['isTaken'] == 'true',
      );
    }).toList();

    state = logs;
  }

  Future<void> addLog(MedicationLog log) async {
    final db = await getDatabase();
    await db.insert('medication_logs', {
      'id': log.id,
      'medicationId': log.medicationId,
      'timestamp': log.timestamp.toIso8601String(),
      'isTaken': log.isTaken.toString(),
    });

    state = [...state, log];
  }

  Future<void> removeLog(String medicationId, DateTime date) async {
    final db = await getDatabase();
    final dateStr = date.toIso8601String().split('T')[0];
    
    await db.rawDelete('''
      DELETE FROM medication_logs 
      WHERE medicationId = ? AND timestamp LIKE ?
    ''', [medicationId, '$dateStr%']);

    state = state.where((log) => !(log.medicationId == medicationId && log.timestamp.toIso8601String().startsWith(dateStr))).toList();
  }
}

final medicationLogsProvider =
    StateNotifierProvider<MedicationLogsNotifier, List<MedicationLog>>((ref) {
  return MedicationLogsNotifier();
});
