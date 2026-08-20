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
  final int averageCycleLength;
  final int currentDayOfCycle;
  final bool trackOvulation;
  final int? fertileWindowStartDay;
  final int? fertileWindowEndDay;

  PeriodState({
    required this.currentCycle,
    required this.pastCycles,
    required this.currentCycleLogs,
    required this.averageCycleLength,
    required this.currentDayOfCycle,
    required this.trackOvulation,
    this.fertileWindowStartDay,
    this.fertileWindowEndDay,
  });

  DateTime? get expectedNextPeriodDate {
    if (currentCycle == null) return null;
    return currentCycle!.startDate.add(Duration(days: averageCycleLength));
  }
}

class PeriodNotifier extends FamilyAsyncNotifier<PeriodState, String> {
  PeriodRepository get _repository => ref.read(periodRepositoryProvider);

  @override
  Future<PeriodState> build(String arg) async {
    return _loadState();
  }

  Future<PeriodState> _loadState() async {
    final allCycles = await _repository.getCycles(arg);
    
    PeriodCycle? currentCycle;
    List<PeriodCycle> pastCycles = [];
    List<PeriodLog> currentCycleLogs = [];
    int averageCycleLength = 28; // Default

    if (allCycles.isNotEmpty) {
      // The most recent cycle is the first one since we sort DESC
      currentCycle = allCycles.first;
      pastCycles = allCycles.sublist(1);
    }

    final completedCycles = allCycles.where((c) => c.cycleLength != null).toList();
    int? shortestCycle;
    int? longestCycle;

    if (completedCycles.isNotEmpty) {
      int totalDays = 0;
      for (var c in completedCycles) {
        int length = c.cycleLength!;
        totalDays += length;
        if (shortestCycle == null || length < shortestCycle) {
          shortestCycle = length;
        }
        if (longestCycle == null || length > longestCycle) {
          longestCycle = length;
        }
      }
      averageCycleLength = (totalDays / completedCycles.length).round();
    }

    if (currentCycle != null) {
      currentCycleLogs = await _repository.getLogsForCycle(currentCycle.id);
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
      averageCycleLength: averageCycleLength,
      currentDayOfCycle: currentDayOfCycle,
      trackOvulation: trackOvulation,
      fertileWindowStartDay: fertileWindowStartDay,
      fertileWindowEndDay: fertileWindowEndDay,
    );
  }

  Future<Result<void, Exception>> startNewCycle(DateTime startDate) async {
    try {
      final stateValue = state.value;
      final cleanStartDate = DateTime(startDate.year, startDate.month, startDate.day);

      if (stateValue?.currentCycle != null) {
        // End the previous cycle
        final oldCycle = stateValue!.currentCycle!;
        final endDate = cleanStartDate.subtract(const Duration(days: 1));
        await _repository.updateCycle(
          PeriodCycle(id: oldCycle.id, profileId: oldCycle.profileId, startDate: oldCycle.startDate, endDate: endDate)
        );
      }

      // Start new cycle
      final newCycle = PeriodCycle(profileId: arg, startDate: cleanStartDate);
      await _repository.addCycle(newCycle);

      // Log 3 default period days
      for (int i = 0; i < 3; i++) {
        final logDate = cleanStartDate.add(Duration(days: i));
        
        final log = PeriodLog(
          cycleId: newCycle.id,
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
      final stateValue = state.value;
      PeriodLog finalLog = log;

      if (stateValue?.currentCycle == null) {
        await startNewCycle(log.date);
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
      } else if (log.flowLevel != null) {
        final currentCycle = stateValue!.currentCycle!;
        final daysElapsed = log.date.difference(currentCycle.startDate).inDays;
        final threshold = (stateValue.averageCycleLength > 0 ? stateValue.averageCycleLength : 28) - 5;
        final minThreshold = threshold < 15 ? 15 : threshold;
        
        if (daysElapsed >= minThreshold) {
           await startNewCycle(log.date);
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
