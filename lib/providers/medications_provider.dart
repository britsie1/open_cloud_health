import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/repositories/medications_repository.dart';
import 'package:open_cloud_health/services/notification_service.dart';

class MedicationsNotifier extends FamilyAsyncNotifier<List<Medication>, String> {
  MedicationsRepository get _repository =>
      ref.read(medicationsRepositoryProvider);
  NotificationService get _notificationService =>
      ref.read(notificationServiceProvider);

  @override
  Future<List<Medication>> build(String arg) async {
    return _repository.loadMedications(arg);
  }

  Future<void> addMedication(Medication medication) async {
    await _repository.addMedication(medication);
    if (state.hasValue) {
      state = AsyncValue.data([...state.value!, medication]);
    }

    // Schedule notification using hash of ID for integer ID
    final notificationId = medication.id.hashCode;
    await _notificationService.scheduleDailyNotification(
      notificationId,
      'Medication Reminder',
      'Time to take your medication: ${medication.name} (${medication.dosage})',
      medication.timeOfDay,
    );
  }

  Future<void> updateMedication(Medication medication) async {
    await _repository.updateMedication(medication);

    if (state.hasValue) {
      state = AsyncValue.data(state.value!.map((m) {
        if (m.id == medication.id) {
          return medication;
        }
        return m;
      }).toList());
    }

    // Cancel old notification and reschedule with updated details
    await _notificationService.cancelNotification(medication.id.hashCode);
    if (medication.isActive) {
      await _notificationService.scheduleDailyNotification(
        medication.id.hashCode,
        'Medication Reminder',
        'Time to take your medication: ${medication.name} (${medication.dosage})',
        medication.timeOfDay,
      );
    }
  }

  Future<void> deleteMedication(String id) async {
    await _repository.deleteMedication(id);
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.where((m) => m.id != id).toList());
    }

    // Cancel notification
    await _notificationService.cancelNotification(id.hashCode);
  }

  Future<void> toggleIsActive(Medication medication) async {
    final newIsActive = !medication.isActive;
    await _repository.toggleIsActive(medication.id, newIsActive);

    if (state.hasValue) {
      state = AsyncValue.data(state.value!.map((m) {
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
      }).toList());
    }

    if (newIsActive) {
      await _notificationService.scheduleDailyNotification(
        medication.id.hashCode,
        'Medication Reminder',
        'Time to take your medication: ${medication.name} (${medication.dosage})',
        medication.timeOfDay,
      );
    } else {
      await _notificationService.cancelNotification(medication.id.hashCode);
    }
  }

  Future<void> refreshMedications() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.loadMedications(arg));
  }
}

final medicationsProvider =
    AsyncNotifierProvider.family<MedicationsNotifier, List<Medication>, String>(
        MedicationsNotifier.new);

class MedicationLogsNotifier
    extends FamilyAsyncNotifier<List<MedicationLog>, String> {
  MedicationsRepository get _repository =>
      ref.read(medicationsRepositoryProvider);

  @override
  Future<List<MedicationLog>> build(String arg) async {
    // Default to today for the initial build
    return _repository.loadLogsForDate(DateTime.now(), arg);
  }

  Future<void> loadLogsForDate(DateTime date) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.loadLogsForDate(date, arg));
  }

  Future<void> addLog(MedicationLog log) async {
    await _repository.addLog(log);
    if (state.hasValue) {
      state = AsyncValue.data([...state.value!, log]);
    }
  }

  Future<void> removeLog(String medicationId, DateTime date) async {
    await _repository.removeLog(medicationId, date);

    if (state.hasValue) {
      final dateStr = date.toIso8601String().split('T')[0];
      state = AsyncValue.data(state.value!.where((log) => !(log.medicationId == medicationId && log.timestamp.toIso8601String().startsWith(dateStr))).toList());
    }
  }
}

final medicationLogsProvider =
    AsyncNotifierProvider.family<MedicationLogsNotifier, List<MedicationLog>, String>(
        MedicationLogsNotifier.new);
