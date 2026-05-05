import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/repositories/medications_repository.dart';
import 'package:open_cloud_health/services/notification_service.dart';

class MedicationsNotifier extends StateNotifier<List<Medication>> {
  final MedicationsRepository _repository;

  MedicationsNotifier(this._repository) : super(const []);

  Future<void> loadMedications(String profileId) async {
    final medications = await _repository.loadMedications(profileId);
    state = medications;
  }

  Future<void> addMedication(Medication medication) async {
    await _repository.addMedication(medication);
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
    await _repository.updateMedication(medication);

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
    await _repository.deleteMedication(id);
    state = state.where((m) => m.id != id).toList();

    // Cancel notification
    await NotificationService().cancelNotification(id.hashCode);
  }
  
  Future<void> toggleIsActive(Medication medication) async {
    final newIsActive = !medication.isActive;
    await _repository.toggleIsActive(medication.id, newIsActive);
        
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
  final repository = ref.watch(medicationsRepositoryProvider);
  return MedicationsNotifier(repository);
});

class MedicationLogsNotifier extends StateNotifier<List<MedicationLog>> {
  final MedicationsRepository _repository;

  MedicationLogsNotifier(this._repository) : super(const []);

  Future<void> loadLogsForDate(DateTime date, String profileId) async {
    final logs = await _repository.loadLogsForDate(date, profileId);
    state = logs;
  }

  Future<void> addLog(MedicationLog log) async {
    await _repository.addLog(log);
    state = [...state, log];
  }

  Future<void> removeLog(String medicationId, DateTime date) async {
    await _repository.removeLog(medicationId, date);

    final dateStr = date.toIso8601String().split('T')[0];
    state = state.where((log) => !(log.medicationId == medicationId && log.timestamp.toIso8601String().startsWith(dateStr))).toList();
  }
}

final medicationLogsProvider =
    StateNotifierProvider<MedicationLogsNotifier, List<MedicationLog>>((ref) {
  final repository = ref.watch(medicationsRepositoryProvider);
  return MedicationLogsNotifier(repository);
});
