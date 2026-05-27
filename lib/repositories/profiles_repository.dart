import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/profile.dart';

class ProfilesRepository {
  final DatabaseHelper _dbHelper;
  ProfilesRepository(this._dbHelper);

  Future<List<Profile>> fetchProfiles({bool includeArchived = false}) async {
    final db = await _dbHelper.getDatabase();
    final List<Map<String, Object?>> data;
    
    if (includeArchived) {
      data = await db.query('profiles');
    } else {
      data = await db.query(
        'profiles',
        where: 'isArchived = ? OR isArchived IS NULL',
        whereArgs: ['false'],
      );
    }

    return data
        .map((row) => Profile(
            id: row['id'] as String,
            name: row['name'] as String,
            middleNames: row['middleNames'] as String,
            surname: row['surname'] as String,
            dateOfBirth: DateTime.parse(row['dateOfBirth'] as String),
            bloodType: row['bloodType'] as String,
            gender: Gender.values.byName(row['gender'] as String),
            isOrganDonor: bool.parse(row['isOrganDonor'] as String),
            trackOvulation: row['trackOvulation'] != null ? bool.parse(row['trackOvulation'] as String) : true,
            isArchived: row['isArchived'] != null ? bool.parse(row['isArchived'] as String) : false,
            archivedAt: row['archivedAt'] != null ? DateTime.parse(row['archivedAt'] as String) : null,
            chronicConditions: row['chronicConditions'] != null && (row['chronicConditions'] as String).isNotEmpty
                ? (row['chronicConditions'] as String).split(',')
                : [],
        ))
        .toList();
  }

  Future<void> updateProfile(Profile profile) async {
    final db = await _dbHelper.getDatabase();
    await db.update(
        'profiles',
        {
          'name': profile.name,
          'middleNames': profile.middleNames,
          'surname': profile.surname,
          'dateOfBirth': profile.formattedDate,
          'bloodType': profile.bloodType,
          'gender': profile.gender.name,
          'isOrganDonor': profile.isOrganDonor.toString(),
          'trackOvulation': profile.trackOvulation.toString(),
          'isArchived': profile.isArchived.toString(),
          'archivedAt': profile.archivedAt?.toIso8601String(),
          'chronicConditions': profile.chronicConditions.join(','),
        },
        where: 'id = ?',
        whereArgs: [profile.id]);
  }

  Future<void> addProfile(Profile profile) async {
    final db = await _dbHelper.getDatabase();
    await db.insert('profiles', {
      'id': profile.id,
      'name': profile.name,
      'middleNames': profile.middleNames,
      'surname': profile.surname,
      'dateOfBirth': profile.formattedDate,
      'bloodType': profile.bloodType,
      'gender': profile.gender.name,
      'isOrganDonor': profile.isOrganDonor.toString(),
      'trackOvulation': profile.trackOvulation.toString(),
      'isArchived': profile.isArchived.toString(),
      'archivedAt': profile.archivedAt?.toIso8601String(),
      'chronicConditions': profile.chronicConditions.join(','),
    });
  }

  Future<void> deleteProfile(String id) async {
    final db = await _dbHelper.getDatabase();
    await db.delete('profiles', where: 'id = ?', whereArgs: [id]);
    await db.delete('history', where: 'profileId = ?', whereArgs: [id]);
    await db.delete('allergy', where: 'profileId = ?', whereArgs: [id]);
    await db.delete('medications', where: 'profileId = ?', whereArgs: [id]);
    await db.delete('checkups', where: 'profileId = ?', whereArgs: [id]);
    await db.delete('period_cycles', where: 'profileId = ?', whereArgs: [id]);
    await db.delete('vital_logs', where: 'profileId = ?', whereArgs: [id]);
  }
}

final profilesRepositoryProvider = Provider<ProfilesRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return ProfilesRepository(dbHelper);
});
