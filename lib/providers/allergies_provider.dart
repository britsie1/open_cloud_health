import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/repositories/allergies_repository.dart';
import 'package:open_cloud_health/utils/result.dart';

class AllergiesNotifier extends FamilyAsyncNotifier<List<Allergy>, String> {
  AllergiesRepository get _repository => ref.read(allergiesRepositoryProvider);

  @override
  Future<List<Allergy>> build(String arg) async {
    return _repository.getAllergies(arg);
  }

  Future<Result<void, Exception>> addAllergy(Allergy allergy) async {
    try {
      await _repository.addAllergy(allergy);
      await refreshAllergies();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> deleteAllergy(String id) async {
    try {
      await _repository.deleteAllergy(id);
      await refreshAllergies();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<void> refreshAllergies() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAllergies(arg));
  }
}

final allergiesProvider =
    AsyncNotifierProvider.family<AllergiesNotifier, List<Allergy>, String>(
        AllergiesNotifier.new);
