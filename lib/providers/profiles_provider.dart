import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/services/file_service.dart';

class ProfilesNotifier extends AsyncNotifier<List<Profile>> {
  ProfilesRepository get _repository => ref.read(profilesRepositoryProvider);
  FileService get _fileService => ref.read(fileServiceProvider);

  @override
  Future<List<Profile>> build() async {
    return _fetchProfiles();
  }

  Future<String> getProfileImagePath(String id) async {
    return _fileService.getProfileImagePath(id);
  }

  Future<List<Profile>> _fetchProfiles() async {
    try {
      return await _repository.fetchProfiles();
    } catch (error) {
      debugPrint('Error: $error');
      rethrow;
    }
  }

  Future<void> loadProfiles() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfiles());
  }

  Profile getProfile(String id) {
    return state.value!.firstWhere((profile) => profile.id == id,
        orElse: () => throw Exception('Profile not found'));
  }

  Future<void> updateProfile(Profile profile) async {
    await _repository.updateProfile(profile);

    if (state.hasValue) {
      final updatedProfiles = state.value!.map((oldProfile) {
        if (oldProfile.id == profile.id) {
          return profile;
        } else {
          return oldProfile;
        }
      }).toList();

      state = AsyncValue.data(updatedProfiles);
    }
  }

  Future<String> addProfile(
      String name,
      String middleNames,
      String surname,
      DateTime dateOfBirth,
      Gender gender,
      String bloodType,
      bool isOrganDonor) async {
    final newProfile = Profile(
        name: name,
        middleNames: middleNames,
        surname: surname,
        dateOfBirth: dateOfBirth,
        bloodType: bloodType,
        gender: gender,
        isOrganDonor: isOrganDonor);

    await _repository.addProfile(newProfile);

    if (state.hasValue) {
      state = AsyncValue.data([...state.value!, newProfile]);
    } else {
      await loadProfiles();
    }
    
    return newProfile.id;
  }
}

final profilesProvider =
    AsyncNotifierProvider<ProfilesNotifier, List<Profile>>(ProfilesNotifier.new);
