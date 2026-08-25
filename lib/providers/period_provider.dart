import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/repositories/period_repository.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/utils/result.dart';

class PeriodState {
  final PeriodCycle? currentCycle;
  final List<PeriodCycle> pastCycles;
  final List<PeriodLog> currentCycleLogs;
  final List<PeriodLog> allLogs;
  final int averageCycleLength;
  final int currentDayOfCycle;
  final bool trackOvulation;
  final int? fertileWindowStartDay;
  final int? fertileWindowEndDay;

  PeriodState({
    required this.currentCycle,
    required this.pastCycles,
    required this.currentCycleLogs,
    this.allLogs = const [],
    required this.averageCycleLength,
    required this.currentDayOfCycle,
    required this.trackOvulation,
    this.fertileWindowStartDay,
    this.fertileWindowEndDay,
  });

  DateTime? get expectedNextPeriodDate {
    if (currentCycle == null || averageCycleLength <= 0) return null;
    return currentCycle!.startDate.add(Duration(days: averageCycleLength));
  }
}

class PeriodNotifier extends FamilyAsyncNotifier<PeriodState, String> {
  PeriodRepository get _repository => ref.read(periodRepositoryProvider);

  @override
  Future<PeriodState> build(String arg) async {
    return _loadState();
  }

  Future<void> _reconcileCycleEndDates(List<PeriodCycle> cycles) async {
    if (cycles.isEmpty) return;

    // Sort chronologically ascending
    final sorted = List<PeriodCycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    for (int i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      DateTime? expectedEndDate;
      if (i < sorted.length - 1) {
        final nextStart = sorted[i + 1].startDate;
        expectedEndDate = DateTime(nextStart.year, nextStart.month, nextStart.day)
            .subtract(const Duration(days: 1));
      } else {
        expectedEndDate = null;
      }

      final currentEnd = current.endDate != null
          ? DateTime(current.endDate!.year, current.endDate!.month, current.endDate!.day)
          : null;

      if (currentEnd != expectedEndDate) {
        final updated = PeriodCycle(
          id: current.id,
          profileId: current.profileId,
          startDate: current.startDate,
          endDate: expectedEndDate,
        );
        await _repository.updateCycle(updated);
      }
    }
  }

  Future<PeriodState> _loadState() async {
    final allCycles = await _repository.getCycles(arg);
    
    PeriodCycle? currentCycle;
    List<PeriodCycle> pastCycles = [];
    List<PeriodLog> currentCycleLogs = [];
    List<PeriodLog> allLogs = [];
    int averageCycleLength = 28; // Default

    if (allCycles.isNotEmpty) {
      // The most recent cycle is the first one since we sort DESC
      currentCycle = allCycles.first;
      pastCycles = allCycles.sublist(1);
    }

    for (var cycle in allCycles) {
      final logs = await _repository.getLogsForCycle(cycle.id);
      allLogs.addAll(logs);
    }
    allLogs.sort((a, b) => b.date.compareTo(a.date));

    if (currentCycle != null) {
      currentCycleLogs = allLogs.where((l) => l.cycleId == currentCycle!.id).toList();
    }

    final completedCycles = allCycles
        .where((c) => c.cycleLength != null && c.cycleLength! > 0)
        .toList();

    if (completedCycles.isNotEmpty) {
      int totalDays = 0;
      for (var c in completedCycles) {
        totalDays += c.cycleLength!;
      }
      final calculatedAvg = (totalDays / completedCycles.length).round();
      if (calculatedAvg > 0) {
        averageCycleLength = calculatedAvg;
      }
    }

    // Calculations
    int currentDayOfCycle = 0;
    if (currentCycle != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = DateTime(currentCycle.startDate.year, currentCycle.startDate.month, currentCycle.startDate.day);
      currentDayOfCycle = today.difference(start).inDays + 1; // Day 1 is the start date
    }

    Profile? profile;
    try {
      profile = await ref.read(profilesRepositoryProvider).getProfile(arg);
    } catch (_) {}
    final trackOvulation = profile?.trackOvulation ?? false;

    int? fertileWindowStartDay;
    int? fertileWindowEndDay;

    if (trackOvulation) {
      int estimatedOvulationDay = averageCycleLength - 14;
      fertileWindowStartDay = estimatedOvulationDay - 5;
      fertileWindowEndDay = estimatedOvulationDay;
      
      if (fertileWindowStartDay < 1) fertileWindowStartDay = 1;
      if (fertileWindowEndDay > averageCycleLength) fertileWindowEndDay = averageCycleLength;
    }

    return PeriodState(
      currentCycle: currentCycle,
      pastCycles: pastCycles,
      currentCycleLogs: currentCycleLogs,
      allLogs: allLogs,
      averageCycleLength: averageCycleLength,
      currentDayOfCycle: currentDayOfCycle,
      trackOvulation: trackOvulation,
      fertileWindowStartDay: fertileWindowStartDay,
      fertileWindowEndDay: fertileWindowEndDay,
    );
  }

  Future<Result<void, Exception>> startNewCycle(DateTime startDate) async {
    try {
      final cleanStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final allCycles = await _repository.getCycles(arg);

      // Check if a cycle already starts on this exact date
      PeriodCycle? existingCycle = allCycles.cast<PeriodCycle?>().firstWhere(
        (c) => c != null &&
            c.startDate.year == cleanStartDate.year &&
            c.startDate.month == cleanStartDate.month &&
            c.startDate.day == cleanStartDate.day,
        orElse: () => null,
      );

      final PeriodCycle cycleToUse;
      if (existingCycle == null) {
        cycleToUse = PeriodCycle(profileId: arg, startDate: cleanStartDate);
        await _repository.addCycle(cycleToUse);
        allCycles.add(cycleToUse);
      } else {
        cycleToUse = existingCycle;
      }

      // Reconcile all cycle end dates chronologically
      await _reconcileCycleEndDates(allCycles);

      // Log 3 default period days
      for (int i = 0; i < 3; i++) {
        final logDate = cleanStartDate.add(Duration(days: i));
        
        final log = PeriodLog(
          cycleId: cycleToUse.id,
          date: logDate,
          flowLevel: FlowLevel.medium,
        );
        await _repository.upsertLog(log);
      }

      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _loadState());
      ref.invalidate(allPeriodLogsProvider(arg));
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> logSymptom(PeriodLog log) async {
    try {
      final cleanDate = DateTime(log.date.year, log.date.month, log.date.day);
      final allCycles = await _repository.getCycles(arg);
      PeriodLog finalLog = log;

      if (allCycles.isEmpty) {
        await startNewCycle(cleanDate);
        final newCycles = await _repository.getCycles(arg);
        if (newCycles.isNotEmpty) {
          finalLog = PeriodLog(
            id: log.id,
            cycleId: newCycles.first.id,
            date: log.date,
            flowLevel: log.flowLevel,
            moods: log.moods,
            physicalSymptoms: log.physicalSymptoms,
          );
        }
      } else {
        final sortedAsc = List<PeriodCycle>.from(allCycles)
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
        
        final latestCycle = sortedAsc.last;
        final earliestCycle = sortedAsc.first;
        final stateValue = state.value;
        final avgLen = (stateValue?.averageCycleLength != null && stateValue!.averageCycleLength > 0)
            ? stateValue.averageCycleLength
            : 28;
        final threshold = avgLen - 5;
        final minThreshold = threshold < 15 ? 15 : threshold;

        if (log.flowLevel != null && cleanDate.difference(latestCycle.startDate).inDays >= minThreshold) {
          // Starting a new cycle ahead of current
          await startNewCycle(cleanDate);
          final updatedCycles = await _repository.getCycles(arg);
          final matchingCycle = updatedCycles.firstWhere(
            (c) => c.startDate.year == cleanDate.year &&
                c.startDate.month == cleanDate.month &&
                c.startDate.day == cleanDate.day,
            orElse: () => updatedCycles.first,
          );
          finalLog = PeriodLog(
            id: log.id,
            cycleId: matchingCycle.id,
            date: log.date,
            flowLevel: log.flowLevel,
            moods: log.moods,
            physicalSymptoms: log.physicalSymptoms,
          );
        } else if (log.flowLevel != null && cleanDate.isBefore(earliestCycle.startDate)) {
          // Starting a new historical cycle before the earliest recorded
          await startNewCycle(cleanDate);
          final updatedCycles = await _repository.getCycles(arg);
          final matchingCycle = updatedCycles.firstWhere(
            (c) => c.startDate.year == cleanDate.year &&
                c.startDate.month == cleanDate.month &&
                c.startDate.day == cleanDate.day,
            orElse: () => updatedCycles.first,
          );
          finalLog = PeriodLog(
            id: log.id,
            cycleId: matchingCycle.id,
            date: log.date,
            flowLevel: log.flowLevel,
            moods: log.moods,
            physicalSymptoms: log.physicalSymptoms,
          );
        } else {
          // Belongs to an existing cycle range
          PeriodCycle matchingCycle = latestCycle;
          for (final c in sortedAsc) {
            if (!cleanDate.isBefore(c.startDate)) {
              if (c.endDate == null || !cleanDate.isAfter(c.endDate!)) {
                matchingCycle = c;
                break;
              }
              matchingCycle = c;
            }
          }
          finalLog = PeriodLog(
            id: log.id,
            cycleId: matchingCycle.id,
            date: log.date,
            flowLevel: log.flowLevel,
            moods: log.moods,
            physicalSymptoms: log.physicalSymptoms,
          );
        }
      }

      await _repository.upsertLog(finalLog);
      
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _loadState());
      ref.invalidate(allPeriodLogsProvider(arg));
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}

final periodProvider =
    AsyncNotifierProvider.family<PeriodNotifier, PeriodState, String>(
        PeriodNotifier.new);

final cycleLogsProvider = FutureProvider.family<List<PeriodLog>, String>((ref, cycleId) async {
  final repository = ref.read(periodRepositoryProvider);
  return repository.getLogsForCycle(cycleId);
});

final allPeriodLogsProvider = FutureProvider.family<List<PeriodLog>, String>((ref, profileId) async {
  final repository = ref.read(periodRepositoryProvider);
  final cycles = await repository.getCycles(profileId);
  List<PeriodLog> allLogs = [];
  for (var cycle in cycles) {
    final logs = await repository.getLogsForCycle(cycle.id);
    allLogs.addAll(logs);
  }
  allLogs.sort((a, b) => b.date.compareTo(a.date));
  return allLogs;
});
