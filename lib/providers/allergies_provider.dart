import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/repositories/allergies_repository.dart';

class AllergiesNotifier extends FamilyAsyncNotifier<List<Allergy>, String> {
  AllergiesRepository get _repository => ref.read(allergiesRepositoryProvider);

  @override
  Future<List<Allergy>> build(String arg) async {
    return _repository.getAllergies(arg);
  }

  Future<void> addAllergy(Allergy allergy) async {
    await _repository.addAllergy(allergy);
    if (state.hasValue) {
      state = AsyncValue.data([...state.value!, allergy]);
    }
  }

  Future<void> deleteAllergy(String id) async {
    await _repository.deleteAllergy(id);
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.where((a) => a.id != id).toList());
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
