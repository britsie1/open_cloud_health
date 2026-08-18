import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';

class EmergencyRepository {
  final AppDatabase _db;
  EmergencyRepository(this._db);

  EmergencyContact _mapContact(EmergencyContactEntry row) {
    return EmergencyContact(
      id: row.id,
      profileId: row.profileId,
      name: row.name,
      relationship: row.relationship,
      phoneNumber: row.phoneNumber,
    );
  }

  LockScreenSetting _mapSetting(LockScreenSettingEntry? row, String profileId) {
    if (row == null) {
      return LockScreenSetting(profileId: profileId);
    }
    return LockScreenSetting(
      profileId: row.profileId,
      showName: row.showName ?? true,
      showAge: row.showAge ?? true,
      showBloodType: row.showBloodType ?? true,
      showOrganDonor: row.showOrganDonor ?? true,
      showChronicConditions: row.showChronicConditions ?? true,
      showAllergies: row.showAllergies ?? true,
      showMedications: row.showMedications ?? true,
      showContacts: row.showContacts ?? true,
      isEnabled: row.isEnabled ?? false,
    );
  }

  Future<List<EmergencyContact>> getEmergencyContacts(String profileId) async {
    final query = _db.select(_db.emergencyContacts)
      ..where((tbl) => tbl.profileId.equals(profileId));
    final data = await query.get();
    return data.map(_mapContact).toList();
  }

  Stream<List<EmergencyContact>> watchEmergencyContacts(String profileId) {
    final query = _db.select(_db.emergencyContacts)
      ..where((tbl) => tbl.profileId.equals(profileId));
    return query.watch().map((data) => data.map(_mapContact).toList());
  }

  Future<void> addEmergencyContact(EmergencyContact contact) async {
    await _db.into(_db.emergencyContacts).insert(
      EmergencyContactEntry(
        id: contact.id,
        profileId: contact.profileId,
        name: contact.name,
        relationship: contact.relationship,
        phoneNumber: contact.phoneNumber,
      ),
    );
  }

  Future<void> deleteEmergencyContact(String id) async {
    await (_db.delete(_db.emergencyContacts)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<LockScreenSetting> getLockScreenSetting(String profileId) async {
    final query = _db.select(_db.lockScreenSettings)
      ..where((tbl) => tbl.profileId.equals(profileId));
    final row = await query.getSingleOrNull();
    return _mapSetting(row, profileId);
  }

  Stream<LockScreenSetting> watchLockScreenSetting(String profileId) {
    final query = _db.select(_db.lockScreenSettings)
      ..where((tbl) => tbl.profileId.equals(profileId));
    return query.watchSingleOrNull().map((row) => _mapSetting(row, profileId));
  }

  Future<void> saveLockScreenSetting(LockScreenSetting setting) async {
    await _db.into(_db.lockScreenSettings).insertOnConflictUpdate(
      LockScreenSettingEntry(
        profileId: setting.profileId,
        showName: setting.showName,
        showAge: setting.showAge,
        showBloodType: setting.showBloodType,
        showOrganDonor: setting.showOrganDonor,
        showChronicConditions: setting.showChronicConditions,
        showAllergies: setting.showAllergies,
        showMedications: setting.showMedications,
        showContacts: setting.showContacts,
        isEnabled: setting.isEnabled,
      ),
    );
  }

  Future<String?> getPrimaryProfileId() async {
    return _db.getPrimaryProfileId();
  }

  Future<void> setPrimaryProfileId(String? profileId) async {
    await _db.setPrimaryProfileId(profileId);
  }
}

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return EmergencyRepository(db);
});
