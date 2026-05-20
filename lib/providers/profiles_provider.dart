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
      return await _repository.fetchProfiles(includeArchived: false);
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

  Future<List<Profile>> fetchArchivedProfiles() async {
    try {
      return await _repository.fetchProfiles(includeArchived: true).then((profiles) {
        return profiles.where((p) => p.isArchived).toList();
      });
    } catch (e) {
      debugPrint('Error fetching archived profiles: $e');
      return [];
    }
  }

  Future<Result<void, Exception>> archiveProfile(String id) async {
    try {
      final activeProfiles = state.value ?? [];
      final profile = activeProfiles.firstWhere((p) => p.id == id);
      final archivedProfile = Profile(
        id: profile.id,
        name: profile.name,
        middleNames: profile.middleNames,
        surname: profile.surname,
        dateOfBirth: profile.dateOfBirth,
        gender: profile.gender,
        bloodType: profile.bloodType,
        isOrganDonor: profile.isOrganDonor,
        trackOvulation: profile.trackOvulation,
        isArchived: true,
        archivedAt: DateTime.now(),
      );

      await _repository.updateProfile(archivedProfile);
      await loadProfiles();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> restoreProfile(String id) async {
    try {
      final allProfiles = await _repository.fetchProfiles(includeArchived: true);
      final profile = allProfiles.firstWhere((p) => p.id == id);
      final restoredProfile = Profile(
        id: profile.id,
        name: profile.name,
        middleNames: profile.middleNames,
        surname: profile.surname,
        dateOfBirth: profile.dateOfBirth,
        gender: profile.gender,
        bloodType: profile.bloodType,
        isOrganDonor: profile.isOrganDonor,
        trackOvulation: profile.trackOvulation,
        isArchived: false,
        archivedAt: null,
      );

      await _repository.updateProfile(restoredProfile);
      await loadProfiles();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> deleteProfilePermanently(String id) async {
    try {
      await _repository.deleteProfile(id);
      await loadProfiles();
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<void> checkAndDeleteExpiredProfiles() async {
    try {
      final allProfiles = await _repository.fetchProfiles(includeArchived: true);
      final now = DateTime.now();
      for (final profile in allProfiles) {
        if (profile.isArchived && profile.archivedAt != null) {
          final difference = now.difference(profile.archivedAt!);
          if (difference.inDays >= 30) {
            await _repository.deleteProfile(profile.id);
            debugPrint('Automatically deleted expired profile: ${profile.name} ${profile.surname}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up archived profiles: $e');
    }
  }
}

final profilesProvider =
    AsyncNotifierProvider<ProfilesNotifier, List<Profile>>(ProfilesNotifier.new);
