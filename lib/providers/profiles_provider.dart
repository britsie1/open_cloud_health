import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/profile_share_models.dart';
import 'package:open_cloud_health/providers/allergies_provider.dart';
import 'package:open_cloud_health/repositories/allergies_repository.dart';
import 'package:open_cloud_health/repositories/history_repository.dart';
import 'package:open_cloud_health/repositories/medications_repository.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/repositories/shared_profiles_repository.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/services/profile_sharing_service.dart';
import 'package:open_cloud_health/utils/result.dart';

export 'package:open_cloud_health/providers/active_shares_provider.dart';

class ProfilesNotifier extends AsyncNotifier<List<Profile>> {
  ProfilesRepository get _repository => ref.read(profilesRepositoryProvider);
  HistoryRepository get _historyRepo => ref.read(historyRepositoryProvider);
  SharedProfilesRepository get _sharedRepo => ref.read(sharedProfilesRepositoryProvider);
  FileService get _fileService => ref.read(fileServiceProvider);
  ProfileSharingService get _sharingService => ref.read(profileSharingServiceProvider);

  @override
  Future<List<Profile>> build() async {
    final subscription = ref.watch(profilesRepositoryProvider).watchProfiles().listen((_) async {
      state = await AsyncValue.guard(() => _fetchProfiles());
    });
    ref.onDispose(subscription.cancel);
    return _fetchProfiles();
  }

  Future<String> getProfileImagePath(String id) async {
    final localPath = await _fileService.getProfileImagePath(id);
    if (localPath.isNotEmpty && File(localPath).existsSync()) {
      return localPath;
    }
    return _sharedRepo.getSharedProfileImagePath(id);
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
    List<String> chronicConditions = const [],
    List<Allergy>? allergies,
    File? imageFile,
    bool isUpdate = false,
  }) async {
    try {
      final resolvedConditions = List<String>.from(chronicConditions);
      if (gender == Gender.male) {
        resolvedConditions.remove('Endometriosis');
        resolvedConditions.remove('Polycystic Ovary Syndrome (PCOS)');
      }

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
        chronicConditions: resolvedConditions,
      );

      if (!isUpdate) {
        await _repository.addProfile(profile);
        profileId = profile.id;
      } else {
        await _repository.updateProfile(profile);
        profileId = id!;
      }

      if (allergies != null) {
        await ref.read(allergiesRepositoryProvider).setAllergies(profileId, allergies);
        ref.invalidate(allergiesProvider(profileId));
      }

      if (imageFile != null) {
        await _fileService.saveProfileImage(profileId, imageFile);
        final filePath = await _fileService.getProfileImagePath(profileId);
        if (filePath.isNotEmpty) {
          await FileImage(File(filePath)).evict();
        }
      }

      await loadProfiles();
      await ref.read(notificationServiceProvider).syncEmergencyNotification(profileId);
      return Success(profileId);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<List<Profile>> _fetchProfiles() async {
    try {
      final localProfiles = await _repository.fetchProfiles(includeArchived: false);
      final sharedProfiles = await _sharedRepo.getSharedProfiles();
      return [...localProfiles, ...sharedProfiles];
    } catch (error) {
      debugPrint('Error fetching profiles: $error');
      rethrow;
    }
  }

  Future<void> loadProfiles() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfiles());
  }

  Future<Profile> importSharedProfile(ShareLinkPayload payload) async {
    final profile = await _sharingService.importSharedProfile(payload);
    await loadProfiles();
    return profile;
  }

  /// Imports an individual profile bundle into the local database.
  Future<Profile> importProfileBundle(SharedProfileBundle bundle) async {
    final db = ref.read(appDatabaseProvider);
    final profile = Profile(
      id: bundle.profile.id,
      name: bundle.profile.name,
      middleNames: bundle.profile.middleNames,
      surname: bundle.profile.surname,
      dateOfBirth: bundle.profile.dateOfBirth,
      gender: bundle.profile.gender,
      bloodType: bundle.profile.bloodType,
      isOrganDonor: bundle.profile.isOrganDonor,
      trackOvulation: bundle.profile.trackOvulation,
      isArchived: false,
      archivedAt: null,
      chronicConditions: bundle.profile.chronicConditions,
      isShared: false,
      isReadOnly: false,
    );

    await db.transaction(() async {
      // 1. Insert or update Profile
      await db.into(db.profiles).insertOnConflictUpdate(
        ProfileEntry(
          id: profile.id,
          name: profile.name,
          middleNames: profile.middleNames,
          surname: profile.surname,
          dateOfBirth: profile.dateOfBirth,
          bloodType: profile.bloodType,
          gender: profile.gender.name,
          isOrganDonor: profile.isOrganDonor,
          trackOvulation: profile.trackOvulation,
          isArchived: profile.isArchived,
          archivedAt: profile.archivedAt,
          chronicConditions: profile.chronicConditions.join(','),
        ),
      );

      // 2. Allergies
      for (final a in bundle.allergies) {
        await db.into(db.allergy).insertOnConflictUpdate(
          AllergyEntry(
            id: a.id,
            profileId: profile.id,
            name: a.name,
            note: a.note,
          ),
        );
      }

      // 3. Medications & Logs
      for (final mb in bundle.medications) {
        final med = mb.medication;
        await db.into(db.medications).insertOnConflictUpdate(
          MedicationEntry(
            id: med.id,
            profileId: profile.id,
            name: med.name,
            dosage: med.dosage,
            type: med.type,
            notificationEnabled: med.notificationEnabled,
            alarmEnabled: med.alarmEnabled,
            timeOfDay: '${med.timeOfDay.hour.toString().padLeft(2, '0')}:${med.timeOfDay.minute.toString().padLeft(2, '0')}',
            isActive: med.isActive,
            daysOfWeek: jsonEncode(med.daysOfWeek),
            timesOfDay: med.timesOfDay.isNotEmpty
                ? jsonEncode(med.timesOfDay.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').toList())
                : null,
            isAsNeeded: med.isAsNeeded,
            trackInventory: med.trackInventory,
            stockQuantity: med.stockQuantity,
            lowStockThreshold: med.lowStockThreshold,
          ),
        );
        for (final log in mb.logs) {
          await db.into(db.medicationLogs).insertOnConflictUpdate(
            MedicationLogEntry(
              id: log.id,
              medicationId: med.id,
              timestamp: log.timestamp,
              isTaken: log.isTaken,
              dosage: log.dosage,
            ),
          );
        }
      }

      // 4. Checkups & Logs
      for (final cb in bundle.checkups) {
        final checkup = cb.checkup;
        await db.into(db.checkups).insertOnConflictUpdate(
          CheckupEntry(
            id: checkup.id,
            profileId: profile.id,
            name: checkup.name,
            frequencyInMonths: checkup.frequencyInMonths,
            iconName: checkup.iconName,
            isCustomInterval: checkup.isCustomInterval,
            isActive: checkup.isActive,
          ),
        );
        for (final log in cb.logs) {
          await db.into(db.checkupLogs).insertOnConflictUpdate(
            CheckupLogEntry(
              id: log.id,
              checkupId: checkup.id,
              dateCompleted: log.dateCompleted,
              location: log.location,
              doctorName: log.doctorName,
              notes: log.notes,
            ),
          );
        }
      }

      // 5. Period Cycles & Logs
      for (final pb in bundle.periodCycles) {
        final cycle = pb.cycle;
        await db.into(db.periodCycles).insertOnConflictUpdate(
          PeriodCycleEntry(
            id: cycle.id,
            profileId: profile.id,
            startDate: cycle.startDate,
            endDate: cycle.endDate,
          ),
        );
        for (final log in pb.logs) {
          await db.into(db.periodLogs).insertOnConflictUpdate(
            PeriodLogEntry(
              id: log.id,
              cycleId: cycle.id,
              date: log.date,
              flowLevel: log.flowLevel?.name,
              moods: log.moods.isNotEmpty ? log.moods.map((m) => m.name).join(',') : null,
              physicalSymptoms: log.physicalSymptoms.isNotEmpty ? log.physicalSymptoms.map((s) => s.name).join(',') : null,
            ),
          );
        }
      }

      // 6. Vitals
      for (final v in bundle.vitals) {
        await db.into(db.vitalLogs).insertOnConflictUpdate(
          VitalLogEntry(
            id: v.id,
            profileId: profile.id,
            type: v.type.name,
            date: v.date,
            value1: v.value1,
            value2: v.value2,
            unit: v.unit,
            note: v.note,
          ),
        );
      }

      // 7. History Events
      for (final h in bundle.historyEvents) {
        await db.into(db.history).insertOnConflictUpdate(
          HistoryEntry(
            id: h.id,
            profileId: profile.id,
            title: h.title,
            description: h.description,
            date: h.date,
            eventType: h.eventType.name,
            hasTime: h.hasTime,
            provider: h.provider,
            facility: h.facility,
          ),
        );
      }

      // 8. Emergency Contacts
      for (final e in bundle.emergencyContacts) {
        await db.into(db.emergencyContacts).insertOnConflictUpdate(
          EmergencyContactEntry(
            id: e.id,
            profileId: profile.id,
            name: e.name,
            relationship: e.relationship,
            phoneNumber: e.phoneNumber,
          ),
        );
      }

      // 9. Lock Screen Setting
      if (bundle.lockScreenSetting != null) {
        final lock = bundle.lockScreenSetting!;
        await db.into(db.lockScreenSettings).insertOnConflictUpdate(
          LockScreenSettingEntry(
            profileId: profile.id,
            showName: lock.showName,
            showAge: lock.showAge,
            showBloodType: lock.showBloodType,
            showOrganDonor: lock.showOrganDonor,
            showChronicConditions: lock.showChronicConditions,
            showAllergies: lock.showAllergies,
            showMedications: lock.showMedications,
            showContacts: lock.showContacts,
            showInsurance: lock.showInsurance,
            isEnabled: lock.isEnabled,
          ),
        );
      }

      // 10. Insurance
      if (bundle.insurance != null) {
        final ins = bundle.insurance!;
        await db.into(db.insurance).insertOnConflictUpdate(
          InsuranceEntry(
            id: ins.id,
            profileId: profile.id,
            provider: ins.provider,
            planName: ins.planName,
            policyNumber: ins.policyNumber,
            groupNumber: ins.groupNumber,
            subscriberName: ins.subscriberName,
            memberId: ins.memberId,
            emergencyPhone: ins.emergencyPhone,
            frontCardImage: null,
            backCardImage: null,
            notes: ins.notes,
          ),
        );
      }
    });

    // Save profile photo if bundled
    if (bundle.profileImageBase64 != null && bundle.profileImageBase64!.isNotEmpty) {
      try {
        final imageBytes = base64Decode(bundle.profileImageBase64!);
        final imgPath = await _fileService.getProfileImagePath(profile.id);
        final imgFile = File(imgPath);
        if (!imgFile.parent.existsSync()) {
          imgFile.parent.createSync(recursive: true);
        }
        await imgFile.writeAsBytes(imageBytes, flush: true);
        await FileImage(imgFile).evict();
      } catch (e) {
        debugPrint('Error saving imported profile photo: $e');
      }
    }

    await loadProfiles();
    await ref.read(notificationServiceProvider).syncEmergencyNotification(profile.id);
    return profile;
  }

  Future<SyncResult> syncSharedProfile(String profileId) async {
    final result = await _sharingService.syncSharedProfile(profileId);
    if (result.status == SyncStatus.success) {
      await loadProfiles();
    }
    return result;
  }

  Future<void> removeSharedProfile(String profileId) async {
    await _sharedRepo.removeSharedProfile(profileId);
    await loadProfiles();
  }

  Profile getProfile(String id) {
    return state.value!.firstWhere((profile) => profile.id == id,
        orElse: () => throw Exception('Profile not found'));
  }

  Future<Result<void, Exception>> updateProfile(Profile profile) async {
    try {
      await _repository.updateProfile(profile);
      await loadProfiles();
      await ref.read(notificationServiceProvider).syncEmergencyNotification(profile.id);
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
      await ref.read(notificationServiceProvider).syncEmergencyNotification(newProfile.id);

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

  Future<Result<void, Exception>> updateChronicConditions(String profileId, List<String> conditions) async {
    try {
      final activeProfiles = state.value ?? [];
      final profile = activeProfiles.firstWhere((p) => p.id == profileId);
      
      final resolvedConditions = List<String>.from(conditions);
      if (profile.gender == Gender.male) {
        resolvedConditions.remove('Endometriosis');
        resolvedConditions.remove('Polycystic Ovary Syndrome (PCOS)');
      }

      final updatedProfile = Profile(
        id: profile.id,
        name: profile.name,
        middleNames: profile.middleNames,
        surname: profile.surname,
        dateOfBirth: profile.dateOfBirth,
        gender: profile.gender,
        bloodType: profile.bloodType,
        isOrganDonor: profile.isOrganDonor,
        trackOvulation: profile.trackOvulation,
        isArchived: profile.isArchived,
        archivedAt: profile.archivedAt,
        chronicConditions: resolvedConditions,
      );

      await _repository.updateProfile(updatedProfile);
      await loadProfiles();
      await ref.read(notificationServiceProvider).syncEmergencyNotification(profileId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
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
        chronicConditions: profile.chronicConditions,
      );

      await _repository.updateProfile(archivedProfile);
      await loadProfiles();
      await ref.read(notificationServiceProvider).syncEmergencyNotification(id);
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
        chronicConditions: profile.chronicConditions,
      );

      await _repository.updateProfile(restoredProfile);
      await loadProfiles();
      await ref.read(notificationServiceProvider).syncEmergencyNotification(id);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> deleteProfilePermanently(String id) async {
    try {
      // 0. Cancel all scheduled notifications for medications belonging to this profile
      try {
        final meds = await ref.read(medicationsRepositoryProvider).fetchMedications(id);
        final notifService = ref.read(notificationServiceProvider);
        for (final med in meds) {
          await notifService.cancelMedicationNotifications(med.id);
        }
      } catch (e) {
        debugPrint('Error canceling medication notifications for deleted profile $id: $e');
      }

      // 1. Fetch all history events for profile to clean up attachments on disk
      final events = await _historyRepo.fetchEvents(id);
      final historyIds = events.map((e) => e.id).toList();

      // 2. Delete physical profile image & all history attachment directories
      await _fileService.deleteProfileFiles(id, historyIds);

      // 3. Delete database records (cascading all child tables)
      await _repository.deleteProfile(id);

      await loadProfiles();
      await ref.read(notificationServiceProvider).syncEmergencyNotification(id);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<void> checkAndDeleteExpiredProfiles() async {
    try {
      final allProfiles = await _repository.fetchProfiles(includeArchived: true);
      final now = DateTime.now();
      bool deletedAny = false;
      for (final profile in allProfiles) {
        if (profile.isArchived && profile.archivedAt != null) {
          final difference = now.difference(profile.archivedAt!);
          if (difference.inDays >= 30) {
            try {
              final meds = await ref.read(medicationsRepositoryProvider).fetchMedications(profile.id);
              final notifService = ref.read(notificationServiceProvider);
              for (final med in meds) {
                await notifService.cancelMedicationNotifications(med.id);
              }
            } catch (e) {
              debugPrint('Error canceling notifications for expired profile ${profile.id}: $e');
            }
            final events = await _historyRepo.fetchEvents(profile.id);
            final historyIds = events.map((e) => e.id).toList();
            await _fileService.deleteProfileFiles(profile.id, historyIds);
            await _repository.deleteProfile(profile.id);
            deletedAny = true;
            debugPrint('Automatically deleted expired profile: ${profile.name} ${profile.surname}');
          }
        }
      }
      if (deletedAny) {
        await ref.read(notificationServiceProvider).syncEmergencyNotification('');
      }
    } catch (e) {
      debugPrint('Error cleaning up archived profiles: $e');
    }
  }
}

final profilesProvider =
    AsyncNotifierProvider<ProfilesNotifier, List<Profile>>(ProfilesNotifier.new);

