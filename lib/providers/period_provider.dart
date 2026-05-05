import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/repositories/period_repository.dart';
import 'package:open_cloud_health/utils/result.dart';

class PeriodState {
  final PeriodCycle? currentCycle;
  final List<PeriodCycle> pastCycles;
  final List<PeriodLog> currentCycleLogs;
  final int averageCycleLength;
  final int currentDayOfCycle;
  final int predictedOvulationDay;

  PeriodState({
    required this.currentCycle,
    required this.pastCycles,
    required this.currentCycleLogs,
    required this.averageCycleLength,
    required this.currentDayOfCycle,
    required this.predictedOvulationDay,
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

      // Calculate average cycle length from past cycles (if they have an end date)
      final completedCycles = allCycles.where((c) => c.cycleLength != null).toList();
      if (completedCycles.isNotEmpty) {
         int totalDays = completedCycles.fold(0, (sum, item) => sum + item.cycleLength!);
         averageCycleLength = (totalDays / completedCycles.length).round();
      }

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

    // Ovulation is generally 14 days before the END of the cycle
    int predictedOvulationDay = averageCycleLength - 14;
    if (predictedOvulationDay <= 0) predictedOvulationDay = 14;

    return PeriodState(
      currentCycle: currentCycle,
      pastCycles: pastCycles,
      currentCycleLogs: currentCycleLogs,
      averageCycleLength: averageCycleLength,
      currentDayOfCycle: currentDayOfCycle,
      predictedOvulationDay: predictedOvulationDay,
    );
  }

  Future<Result<void, Exception>> startNewCycle(DateTime startDate) async {
    try {
      final stateValue = state.value;
      if (stateValue?.currentCycle != null) {
        // End the previous cycle
        final oldCycle = stateValue!.currentCycle!;
        final endDate = startDate.subtract(const Duration(days: 1));
        await _repository.updateCycle(
          PeriodCycle(id: oldCycle.id, profileId: oldCycle.profileId, startDate: oldCycle.startDate, endDate: endDate)
        );
      }

      // Start new cycle
      final newCycle = PeriodCycle(profileId: arg, startDate: startDate);
      await _repository.addCycle(newCycle);

      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _loadState());
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> logSymptom(PeriodLog log) async {
    try {
      if (state.value?.currentCycle == null) {
        return Failure(Exception("No active cycle to log against."));
      }
      await _repository.upsertLog(log);
      
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _loadState());
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
