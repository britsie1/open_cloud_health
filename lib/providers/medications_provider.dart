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
      
      // Do NOT schedule notifications/alarms if it is AsNeeded (PRN)
      if (!medication.isAsNeeded && medication.notificationEnabled && medication.isActive) {
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

      if (!medication.isAsNeeded && medication.alarmEnabled && medication.isActive) {
        for (final time in medication.timesOfDay) {
          await _notificationService.setSystemAlarm(
            time, 
            'Take medication: ${medication.name}',
            medication.daysOfWeek,
          );
        }
      }
      
      await refreshMedications();
      await _notificationService.syncEmergencyNotification(arg);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> updateMedication(Medication medication) async {
    try {
      await _repository.updateMedication(medication);

      await _notificationService.cancelMedicationNotifications(medication.id);
      
      // Do NOT schedule notifications/alarms if it is AsNeeded (PRN)
      if (medication.isActive && !medication.isAsNeeded && medication.notificationEnabled) {
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

      if (medication.isActive && !medication.isAsNeeded && medication.alarmEnabled) {
        for (final time in medication.timesOfDay) {
          await _notificationService.setSystemAlarm(
            time, 
            'Take medication: ${medication.name}',
            medication.daysOfWeek,
          );
        }
      }
      
      await refreshMedications();
      await _notificationService.syncEmergencyNotification(arg);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> deleteMedication(String id) async {
    try {
      await _repository.deleteMedication(id);

      await _notificationService.cancelMedicationNotifications(id);
      
      await refreshMedications();
      await _notificationService.syncEmergencyNotification(arg);
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
        // Do NOT schedule notifications/alarms if it is AsNeeded (PRN)
        if (!medication.isAsNeeded && medication.notificationEnabled) {
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

        if (!medication.isAsNeeded && medication.alarmEnabled) {
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
      await _notificationService.syncEmergencyNotification(arg);
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
      ref.invalidate(medicationsProvider(arg));
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
      ref.invalidate(medicationsProvider(arg));
    });
    ref.onDispose(sub.cancel);

    return _repository.loadLogsForDate(DateTime.now(), arg);
  }

  Future<void> loadLogsForDate(DateTime date) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.loadLogsForDate(date, arg));
  }

  Future<Result<void, Exception>> addLog(MedicationLog log) async {
    try {
      await _repository.addLog(log);
      
      ref.invalidate(medicationsProvider(arg));
      ref.invalidate(allMedicationLogsProvider(arg));

      state = await AsyncValue.guard(() => _repository.loadLogsForDate(log.timestamp, arg));
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> removeLog(String medicationId, DateTime date, {TimeOfDay? time}) async {
    try {
      await _repository.removeLog(medicationId, date, time: time);
      
      ref.invalidate(medicationsProvider(arg));
      ref.invalidate(allMedicationLogsProvider(arg));

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

// Adherence calculations models and provider
class DayAdherence {
  final DateTime date;
  final int expected;
  final int actual;
  bool get isPerfect => expected == 0 || actual >= expected;
  double get percentage => expected == 0 ? 1.0 : (actual / expected).clamp(0.0, 1.0);

  DayAdherence({
    required this.date,
    required this.expected,
    required this.actual,
  });
}

class AdherenceData {
  final double adherenceRate;
  final List<DayAdherence> dailyAdherence;
  final int streakDays;

  AdherenceData({
    required this.adherenceRate,
    required this.dailyAdherence,
    required this.streakDays,
  });
}

final medicationAdherenceProvider = FutureProvider.family<AdherenceData, String>((ref, profileId) async {
  final medicationsAsync = ref.watch(medicationsProvider(profileId));
  final logsAsync = ref.watch(allMedicationLogsProvider(profileId));

  final medications = medicationsAsync.value ?? [];
  final logs = logsAsync.value ?? [];

  final today = DateTime.now();
  final last7Days = List.generate(7, (index) {
    final d = today.subtract(Duration(days: 6 - index));
    return DateTime(d.year, d.month, d.day);
  });

  final List<DayAdherence> dailyAdherence = [];
  int expectedTotal = 0;
  int actualTotal = 0;

  for (final date in last7Days) {
    int expectedForDay = 0;
    int actualForDay = 0;

    for (final med in medications) {
      if (med.isActive && !med.isAsNeeded) {
        if (med.daysOfWeek.contains(date.weekday)) {
          expectedForDay += med.timesOfDay.length;
        }
      }
    }

    final dayStr = date.toIso8601String().split('T')[0];
    final dayLogs = logs.where((l) =>
        l.isTaken &&
        l.timestamp.toIso8601String().startsWith(dayStr) &&
        medications.any((m) => m.id == l.medicationId && !m.isAsNeeded));
    actualForDay = dayLogs.length;

    expectedTotal += expectedForDay;
    actualTotal += actualForDay > expectedForDay ? expectedForDay : actualForDay;

    dailyAdherence.add(DayAdherence(
      date: date,
      expected: expectedForDay,
      actual: actualForDay,
    ));
  }

  final double rate = expectedTotal == 0 ? 1.0 : actualTotal / expectedTotal;

  int streak = 0;
  for (int i = dailyAdherence.length - 1; i >= 0; i--) {
    final day = dailyAdherence[i];
    if (day.expected == 0) {
      continue;
    }
    if (day.isPerfect) {
      streak++;
    } else {
      if (i == dailyAdherence.length - 1 && day.actual == 0 && day.expected > 0) {
        continue;
      }
      break;
    }
  }

  return AdherenceData(
    adherenceRate: rate,
    dailyAdherence: dailyAdherence,
    streakDays: streak,
  );
});
