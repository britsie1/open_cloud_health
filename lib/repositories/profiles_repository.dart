import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/profile.dart';

class ProfilesRepository {
  final DatabaseHelper _dbHelper;
  ProfilesRepository(this._dbHelper);

  Future<List<Profile>> fetchProfiles() async {
    final db = await _dbHelper.getDatabase();
    final data = await db.query('profiles');

    return data
        .map((row) => Profile(
            id: row['id'] as String,
            name: row['name'] as String,
            middleNames: row['middleNames'] as String,
            surname: row['surname'] as String,
            dateOfBirth: DateTime.parse(row['dateOfBirth'] as String),
            bloodType: row['bloodType'] as String,
            gender: Gender.values.byName(row['gender'] as String),
            isOrganDonor: bool.parse(row['isOrganDonor'] as String)))
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
          'isOrganDonor': profile.isOrganDonor.toString()
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
      'isOrganDonor': profile.isOrganDonor.toString()
    });
  }
}

final profilesRepositoryProvider = Provider<ProfilesRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return ProfilesRepository(dbHelper);
});
