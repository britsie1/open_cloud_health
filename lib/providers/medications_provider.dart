import 'package:flutter/material.dart';
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
      
      if (medication.notificationEnabled && medication.isActive) {
        final baseId = medication.id.hashCode & 0x0FFFFFFF;
        for (final day in medication.daysOfWeek) {
          for (int i = 0; i < medication.timesOfDay.length; i++) {
            final time = medication.timesOfDay[i];
            final notificationId = baseId + day * 100 + i;
            await _notificationService.scheduleWeeklyNotification(
              notificationId,
              'Medication Reminder',
              'Time to take your medication: ${medication.name} (${medication.dosage})',
              time,
              day,
              medication.id,
            );
          }
        }
      }

      if (medication.alarmEnabled && medication.isActive) {
        for (final time in medication.timesOfDay) {
          await _notificationService.setSystemAlarm(
            time, 
            'Take medication: ${medication.name}',
            medication.daysOfWeek,
          );
        }
      }
      
      await refreshMedications();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> updateMedication(Medication medication) async {
    try {
      await _repository.updateMedication(medication);

      await _notificationService.cancelMedicationNotifications(medication.id);
      
      if (medication.isActive && medication.notificationEnabled) {
        final baseId = medication.id.hashCode & 0x0FFFFFFF;
        for (final day in medication.daysOfWeek) {
          for (int i = 0; i < medication.timesOfDay.length; i++) {
            final time = medication.timesOfDay[i];
            final notificationId = baseId + day * 100 + i;
            await _notificationService.scheduleWeeklyNotification(
              notificationId,
              'Medication Reminder',
              'Time to take your medication: ${medication.name} (${medication.dosage})',
              time,
              day,
              medication.id,
            );
          }
        }
      }

      if (medication.isActive && medication.alarmEnabled) {
        for (final time in medication.timesOfDay) {
          await _notificationService.setSystemAlarm(
            time, 
            'Take medication: ${medication.name}',
            medication.daysOfWeek,
          );
        }
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

      // Cancel notifications
      await _notificationService.cancelMedicationNotifications(id);
      
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

      await _notificationService.cancelMedicationNotifications(medication.id);

      if (newIsActive) {
        if (medication.notificationEnabled) {
          final baseId = medication.id.hashCode & 0x0FFFFFFF;
          for (final day in medication.daysOfWeek) {
            for (int i = 0; i < medication.timesOfDay.length; i++) {
              final time = medication.timesOfDay[i];
              final notificationId = baseId + day * 100 + i;
              await _notificationService.scheduleWeeklyNotification(
                notificationId,
                'Medication Reminder',
                'Time to take your medication: ${medication.name} (${medication.dosage})',
                time,
                day,
                medication.id,
              );
            }
          }
        }

        if (medication.alarmEnabled) {
          for (final time in medication.timesOfDay) {
            await _notificationService.setSystemAlarm(
              time, 
              'Take medication: ${medication.name}',
              medication.daysOfWeek,
            );
          }
        }
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
    final sub = ref.read(notificationServiceProvider).onMedicationMarkedTaken.stream.listen((_) {
      ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);

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
    final sub = ref.read(notificationServiceProvider).onMedicationMarkedTaken.stream.listen((_) {
      ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);

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

  Future<Result<void, Exception>> removeLog(String medicationId, DateTime date, {TimeOfDay? time}) async {
    try {
      await _repository.removeLog(medicationId, date, time: time);
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
