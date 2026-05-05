import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/repositories/medications_repository.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/utils/result.dart';

class MedicationsNotifier extends FamilyAsyncNotifier<List<Medication>, String> {
  MedicationsRepository get _repository =>
      ref.read(medicationsRepositoryProvider);
  NotificationService get _notificationService =>
      ref.read(notificationServiceProvider);

  @override
  Future<List<Medication>> build(String arg) async {
    return _repository.loadMedications(arg);
  }

  Future<Result<void, Exception>> addMedication(Medication medication) async {
    try {
      await _repository.addMedication(medication);
      
      // Schedule notification using hash of ID for integer ID
      final notificationId = medication.id.hashCode;
      await _notificationService.scheduleDailyNotification(
        notificationId,
        'Medication Reminder',
        'Time to take your medication: ${medication.name} (${medication.dosage})',
        medication.timeOfDay,
      );
      
      await refreshMedications();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> updateMedication(Medication medication) async {
    try {
      await _repository.updateMedication(medication);

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
      
      await refreshMedications();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> deleteMedication(String id) async {
    try {
      await _repository.deleteMedication(id);

      // Cancel notification
      await _notificationService.cancelNotification(id.hashCode);
      
      await refreshMedications();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> toggleIsActive(Medication medication) async {
    try {
      final newIsActive = !medication.isActive;
      await _repository.toggleIsActive(medication.id, newIsActive);

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
      
      await refreshMedications();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
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

class AllMedicationLogsNotifier extends FamilyAsyncNotifier<List<MedicationLog>, String> {
  MedicationsRepository get _repository => ref.read(medicationsRepositoryProvider);
  
  static const int _limit = 20;
  int _offset = 0;
  bool hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<MedicationLog>> build(String arg) async {
    _offset = 0;
    hasMore = true;
    final initialLogs = await _repository.loadAllLogs(arg, limit: _limit, offset: _offset);
    if (initialLogs.length < _limit) {
      hasMore = false;
    }
    return initialLogs;
  }

  Future<void> loadMore() async {
    if (!hasMore || _isLoadingMore || state.isLoading || state.hasError) return;

    _isLoadingMore = true;
    _offset += _limit;

    try {
      final moreLogs = await _repository.loadAllLogs(arg, limit: _limit, offset: _offset);
      
      if (moreLogs.isEmpty) {
        hasMore = false;
      } else {
        if (moreLogs.length < _limit) {
          hasMore = false;
        }
        final currentLogs = state.value ?? [];
        state = AsyncValue.data([...currentLogs, ...moreLogs]);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    _offset = 0;
    hasMore = true;
    _isLoadingMore = false;
    state = await AsyncValue.guard(() async {
      final logs = await _repository.loadAllLogs(arg, limit: _limit, offset: _offset);
      if (logs.length < _limit) {
        hasMore = false;
      }
      return logs;
    });
  }
}

final allMedicationLogsProvider = AsyncNotifierProvider.family<AllMedicationLogsNotifier, List<MedicationLog>, String>(
    AllMedicationLogsNotifier.new);

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

  Future<Result<void, Exception>> addLog(MedicationLog log) async {
    try {
      await _repository.addLog(log);
      
      // We need to refresh the current view, but build() might be for a different date.
      // For simplicity, let's just refresh.
      state = await AsyncValue.guard(() => _repository.loadLogsForDate(log.timestamp, arg));
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> removeLog(String medicationId, DateTime date) async {
    try {
      await _repository.removeLog(medicationId, date);
      state = await AsyncValue.guard(() => _repository.loadLogsForDate(date, arg));
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}

final medicationLogsProvider =
    AsyncNotifierProvider.family<MedicationLogsNotifier, List<MedicationLog>, String>(
        MedicationLogsNotifier.new);
