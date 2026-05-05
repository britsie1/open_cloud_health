import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/repositories/allergies_repository.dart';

class AllergiesNotifier extends StateNotifier<List<Allergy>> {
  final AllergiesRepository _repository;

  AllergiesNotifier(this._repository) : super(const []);

  Future<void> loadAllergies(String profileId) async {
    final allergies = await _repository.getAllergies(profileId);
    state = allergies;
  }

  Future<void> addAllergy(Allergy allergy) async {
    await _repository.addAllergy(allergy);
    state = [...state, allergy];
  }

  Future<void> deleteAllergy(String id) async {
    await _repository.deleteAllergy(id);
    state = state.where((a) => a.id != id).toList();
  }
}

final allergiesProvider = StateNotifierProvider<AllergiesNotifier, List<Allergy>>((ref) {
  final repository = ref.watch(allergiesRepositoryProvider);
  return AllergiesNotifier(repository);
});
