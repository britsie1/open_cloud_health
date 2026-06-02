import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:sqflite/sqflite.dart' as sql;

class EmergencyRepository {
  final DatabaseHelper _dbHelper;
  EmergencyRepository(this._dbHelper);

  Future<List<EmergencyContact>> getEmergencyContacts(String profileId) async {
    final db = await _dbHelper.getDatabase();
    final data = await db.query('emergency_contacts',
        where: 'profileId = ?', whereArgs: [profileId]);

    return data
        .map((row) => EmergencyContact(
              id: row['id'] as String,
              profileId: row['profileId'] as String,
              name: row['name'] as String,
              relationship: row['relationship'] as String,
              phoneNumber: row['phoneNumber'] as String,
            ))
        .toList();
  }

  Future<void> addEmergencyContact(EmergencyContact contact) async {
    final db = await _dbHelper.getDatabase();
    await db.insert('emergency_contacts', {
      'id': contact.id,
      'profileId': contact.profileId,
      'name': contact.name,
      'relationship': contact.relationship,
      'phoneNumber': contact.phoneNumber,
    });
  }

  Future<void> deleteEmergencyContact(String id) async {
    final db = await _dbHelper.getDatabase();
    await db.delete('emergency_contacts', where: 'id = ?', whereArgs: [id]);
  }

  Future<LockScreenSetting> getLockScreenSetting(String profileId) async {
    final db = await _dbHelper.getDatabase();
    final data = await db.query('lock_screen_settings',
        where: 'profileId = ?', whereArgs: [profileId]);

    if (data.isEmpty) {
      return LockScreenSetting(profileId: profileId);
    }

    final row = data.first;
    return LockScreenSetting(
      profileId: row['profileId'] as String,
      showName: row['showName'] == 'true',
      showAge: row['showAge'] == 'true',
      showBloodType: row['showBloodType'] == 'true',
      showOrganDonor: row['showOrganDonor'] == 'true',
      showChronicConditions: row['showChronicConditions'] == 'true',
      showAllergies: row['showAllergies'] == 'true',
      showMedications: row['showMedications'] == 'true',
      showContacts: row['showContacts'] == 'true',
      isEnabled: row['isEnabled'] == 'true',
    );
  }

  Future<void> saveLockScreenSetting(LockScreenSetting setting) async {
    final db = await _dbHelper.getDatabase();
    await db.insert(
      'lock_screen_settings',
      {
        'profileId': setting.profileId,
        'showName': setting.showName.toString(),
        'showAge': setting.showAge.toString(),
        'showBloodType': setting.showBloodType.toString(),
        'showOrganDonor': setting.showOrganDonor.toString(),
        'showChronicConditions': setting.showChronicConditions.toString(),
        'showAllergies': setting.showAllergies.toString(),
        'showMedications': setting.showMedications.toString(),
        'showContacts': setting.showContacts.toString(),
        'isEnabled': setting.isEnabled.toString(),
      },
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }
}

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return EmergencyRepository(dbHelper);
});
