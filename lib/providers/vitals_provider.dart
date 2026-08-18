import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/repositories/vitals_repository.dart';
import 'package:open_cloud_health/utils/result.dart';

typedef VitalsArgs = ({String profileId, VitalType type});

class VitalsNotifier extends FamilyAsyncNotifier<List<VitalLog>, VitalsArgs> {
  VitalsRepository get _repository => ref.read(vitalsRepositoryProvider);

  @override
  Future<List<VitalLog>> build(VitalsArgs arg) async {
    final sub = ref.watch(vitalsRepositoryProvider).watchLogs(arg.profileId, arg.type).listen((logs) {
      state = AsyncValue.data(logs);
    });
    ref.onDispose(sub.cancel);
    return _repository.getLogs(arg.profileId, arg.type);
  }

  Future<Result<void, Exception>> addLog(VitalLog log) async {
    try {
      await _repository.addLog(log);
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _repository.getLogs(arg.profileId, arg.type));
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> deleteLog(String id) async {
    try {
      await _repository.deleteLog(id);
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _repository.getLogs(arg.profileId, arg.type));
      return const Success(null);
    } catch (e) {
       return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}

final vitalsProvider =
    AsyncNotifierProvider.family<VitalsNotifier, List<VitalLog>, VitalsArgs>(
        VitalsNotifier.new);
