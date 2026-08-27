import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/insurance_policy.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/repositories/emergency_repository.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/utils/result.dart';

class EmergencyContactsNotifier extends FamilyAsyncNotifier<List<EmergencyContact>, String> {
  EmergencyRepository get _repository => ref.read(emergencyRepositoryProvider);

  @override
  Future<List<EmergencyContact>> build(String arg) async {
    final sub = ref.watch(emergencyRepositoryProvider).watchEmergencyContacts(arg).listen((contacts) {
      state = AsyncValue.data(contacts);
    });
    ref.onDispose(sub.cancel);
    return _repository.getEmergencyContacts(arg);
  }

  Future<Result<void, Exception>> addContact(EmergencyContact contact) async {
    try {
      await _repository.addEmergencyContact(contact);
      await refreshContacts();
      // Sync emergency notification
      await ref.read(notificationServiceProvider).syncEmergencyNotification(arg);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> deleteContact(String id) async {
    try {
      await _repository.deleteEmergencyContact(id);
      await refreshContacts();
      // Sync emergency notification
      await ref.read(notificationServiceProvider).syncEmergencyNotification(arg);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<void> refreshContacts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getEmergencyContacts(arg));
  }
}

final emergencyContactsProvider =
    AsyncNotifierProvider.family<EmergencyContactsNotifier, List<EmergencyContact>, String>(
        EmergencyContactsNotifier.new);

class LockScreenSettingsNotifier extends FamilyAsyncNotifier<LockScreenSetting, String> {
  EmergencyRepository get _repository => ref.read(emergencyRepositoryProvider);

  @override
  Future<LockScreenSetting> build(String arg) async {
    final sub = ref.watch(emergencyRepositoryProvider).watchLockScreenSetting(arg).listen((setting) {
      state = AsyncValue.data(setting);
    });
    ref.onDispose(sub.cancel);
    return _repository.getLockScreenSetting(arg);
  }

  Future<Result<void, Exception>> updateSettings(LockScreenSetting setting) async {
    try {
      await _repository.saveLockScreenSetting(setting);
      state = AsyncValue.data(setting);
      // Sync emergency notification
      await ref.read(notificationServiceProvider).syncEmergencyNotification(arg);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}

final lockScreenSettingsProvider =
    AsyncNotifierProvider.family<LockScreenSettingsNotifier, LockScreenSetting, String>(
        LockScreenSettingsNotifier.new);

class PrimaryProfileIdNotifier extends AsyncNotifier<String?> {
  EmergencyRepository get _repository => ref.read(emergencyRepositoryProvider);

  @override
  Future<String?> build() async {
    return _repository.getPrimaryProfileId();
  }

  Future<void> setPrimaryProfileId(String? profileId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.setPrimaryProfileId(profileId);
      state = AsyncValue.data(profileId);
      // Sync emergency notification
      if (profileId != null) {
        await ref.read(notificationServiceProvider).syncEmergencyNotification(profileId);
      } else {
        await ref.read(notificationServiceProvider).syncEmergencyNotification('');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final primaryProfileIdProvider = AsyncNotifierProvider<PrimaryProfileIdNotifier, String?>(PrimaryProfileIdNotifier.new);

final emergencyProfilesDetailsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final fileService = ref.watch(fileServiceProvider);

  final activeSettings = await (db.select(db.lockScreenSettings)..where((tbl) => tbl.isEnabled.equals(true))).get();
  if (activeSettings.isEmpty) {
    return [];
  }

  final List<Map<String, dynamic>> results = [];
  final primaryId = await db.getPrimaryProfileId();

  for (final setRow in activeSettings) {
    final pId = setRow.profileId;

    final settings = LockScreenSetting(
      profileId: pId,
      showName: setRow.showName ?? true,
      showAge: setRow.showAge ?? true,
      showBloodType: setRow.showBloodType ?? true,
      showOrganDonor: setRow.showOrganDonor ?? true,
      showChronicConditions: setRow.showChronicConditions ?? true,
      showAllergies: setRow.showAllergies ?? true,
      showMedications: setRow.showMedications ?? true,
      showContacts: setRow.showContacts ?? true,
      showInsurance: setRow.showInsurance ?? true,
      isEnabled: true,
    );

    final p = await (db.select(db.profiles)..where((tbl) => tbl.id.equals(pId))).getSingleOrNull();
    if (p == null) continue;

    final chronicConditionsStr = p.chronicConditions ?? '';
    final chronicConditions = chronicConditionsStr
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final profile = Profile(
      id: p.id,
      name: p.name,
      middleNames: p.middleNames,
      surname: p.surname,
      dateOfBirth: p.dateOfBirth,
      gender: p.gender == 'male' ? Gender.male : Gender.female,
      bloodType: p.bloodType,
      isOrganDonor: p.isOrganDonor,
      chronicConditions: chronicConditions,
    );

    final allergiesData = await (db.select(db.allergy)..where((tbl) => tbl.profileId.equals(pId))).get();
    final allergies = allergiesData
        .map((row) => Allergy(
              id: row.id,
              profileId: row.profileId,
              name: row.name,
              note: row.note,
            ))
        .toList();

    final medsData = await (db.select(db.medications)
          ..where((tbl) => tbl.profileId.equals(pId))
          ..where((tbl) => tbl.isActive.equals(true)))
        .get();
    final medications = medsData
        .map((row) => Medication(
              id: row.id,
              profileId: row.profileId,
              name: row.name,
              dosage: row.dosage,
              type: row.type ?? 'Other',
              isActive: row.isActive ?? true,
              notificationEnabled: row.notificationEnabled ?? false,
              alarmEnabled: row.alarmEnabled ?? false,
            ))
        .toList();

    final contactsData = await (db.select(db.emergencyContacts)..where((tbl) => tbl.profileId.equals(pId))).get();
    final contacts = contactsData
        .map((row) => EmergencyContact(
              id: row.id,
              profileId: row.profileId,
              name: row.name,
              relationship: row.relationship,
              phoneNumber: row.phoneNumber,
            ))
        .toList();

    InsurancePolicy? insurance;
    if (settings.showInsurance) {
      final insRow = await (db.select(db.insurance)..where((tbl) => tbl.profileId.equals(pId))).getSingleOrNull();
      if (insRow != null) {
        final frontPath = await fileService.getInsuranceCardPath(pId, 'front');
        final backPath = await fileService.getInsuranceCardPath(pId, 'back');
        insurance = InsurancePolicy(
          id: insRow.id,
          profileId: insRow.profileId,
          provider: insRow.provider,
          planName: insRow.planName,
          policyNumber: insRow.policyNumber,
          groupNumber: insRow.groupNumber,
          subscriberName: insRow.subscriberName,
          memberId: insRow.memberId,
          emergencyPhone: insRow.emergencyPhone,
          frontCardImagePath: frontPath.isNotEmpty ? frontPath : insRow.frontCardImage,
          backCardImagePath: backPath.isNotEmpty ? backPath : insRow.backCardImage,
          notes: insRow.notes,
        );
      }
    }

    final imagePath = await fileService.getProfileImagePath(pId);

    results.add({
      'settings': settings,
      'profile': profile,
      'allergies': allergies,
      'medications': medications,
      'contacts': contacts,
      'insurance': insurance,
      'imagePath': imagePath,
      'isPrimary': primaryId == pId,
    });
  }

  if (primaryId != null) {
    results.sort((a, b) {
      final aIsPrimary = a['isPrimary'] == true;
      final bIsPrimary = b['isPrimary'] == true;
      if (aIsPrimary && !bIsPrimary) return -1;
      if (!aIsPrimary && bIsPrimary) return 1;
      return 0;
    });
  }

  return results;
});
