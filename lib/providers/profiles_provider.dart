import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ProfilesNotifier extends StateNotifier<List<Profile>> {
  final ProfilesRepository _repository;

  ProfilesNotifier(this._repository) : super(const []);

  Future<String> getProfileImagePath(String id) async {
    var appDir = await getApplicationDocumentsDirectory();
    final filePath = path.join(appDir.path, 'profileImages/$id.jpg');
    if (await File(filePath).exists()) {
      return filePath;
    }

    return '';
  }

  Future<List<Profile>> _fetchProfiles() async {
    try {
      return await _repository.fetchProfiles();
    } catch (error) {
      debugPrint('Error: $error');
      return [];
    }
  }

  Future<void> loadProfiles() async {
    final profiles = await _fetchProfiles();
    state = profiles;
  }

  Profile getProfile(String id) {
    return state.firstWhere((profile) => profile.id == id,
        orElse: () => throw Exception('Profile not found'));
  }

  void updateProfile(Profile profile) async {
    await _repository.updateProfile(profile);

    final updatedProfiles = state.map((oldProfile) {
      if (oldProfile.id == profile.id) {
        return profile;
      } else {
        return oldProfile;
      }
    }).toList();

    state = updatedProfiles;
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

    state = [...state, newProfile];
    return newProfile.id;
  }
}

final profilesProvider =
    StateNotifierProvider<ProfilesNotifier, List<Profile>>((ref) {
  final repository = ref.watch(profilesRepositoryProvider);
  return ProfilesNotifier(repository);
});
