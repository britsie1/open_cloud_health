import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/utils/result.dart';

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

  Future<Result<String, Exception>> saveProfile({
    String? id,
    required String name,
    required String middleNames,
    required String surname,
    required DateTime dateOfBirth,
    required Gender gender,
    required String bloodType,
    required bool isOrganDonor,
    bool trackOvulation = true,
    File? imageFile,
    bool isUpdate = false,
  }) async {
    try {
      String profileId;
      final profile = Profile(
        id: id,
        name: name,
        middleNames: middleNames,
        surname: surname,
        dateOfBirth: dateOfBirth,
        gender: gender,
        bloodType: bloodType,
        isOrganDonor: isOrganDonor,
        trackOvulation: trackOvulation,
      );

      if (!isUpdate) {
        await _repository.addProfile(profile);
        profileId = profile.id;
      } else {
        await _repository.updateProfile(profile);
        profileId = id!;
      }

      if (imageFile != null) {
        await _fileService.saveProfileImage(profileId, imageFile);
      }

      await loadProfiles();
      return Success(profileId);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
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

  Future<Result<void, Exception>> updateProfile(Profile profile) async {
    try {
      await _repository.updateProfile(profile);
      await loadProfiles();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<String, Exception>> addProfile(
      String name,
      String middleNames,
      String surname,
      DateTime dateOfBirth,
      Gender gender,
      String bloodType,
      bool isOrganDonor) async {
    try {
      final newProfile = Profile(
          name: name,
          middleNames: middleNames,
          surname: surname,
          dateOfBirth: dateOfBirth,
          bloodType: bloodType,
          gender: gender,
          isOrganDonor: isOrganDonor);

      await _repository.addProfile(newProfile);
      await loadProfiles();

      return Success(newProfile.id);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}

final profilesProvider =
    AsyncNotifierProvider<ProfilesNotifier, List<Profile>>(ProfilesNotifier.new);
