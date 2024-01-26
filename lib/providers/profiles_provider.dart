import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ProfilesNotifier extends StateNotifier<List<Profile>> {
  ProfilesNotifier() : super(const []);

  Future<String> getProfileImagePath(Uint8List imageData, String name) async {
    var tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$name.png';
    if (await File(filePath).exists()) {
      return filePath;
    }

    File file = await File('${tempDir.path}/$name.png').create();
    file.writeAsBytesSync(imageData);
    return file.path;
  }

  Future<List<Profile>> fetchProfiles() async {
    final db = await getDatabase();
    final data = await db.query('profiles');

    try {
      final profiles = data
          .map(
            (row) => Profile(
              id: row['id'] as String,
              name: row['name'] as String,
              middleNames: row['middleNames'] as String,
              surname: row['surname'] as String,
              dateOfBirth: DateTime.parse(row['dateOfBirth'] as String),
              bloodType: row['bloodType'] as String,
              gender: Gender.values.byName(row['gender'] as String),
              isOrganDonor: bool.parse(row['isOrganDonor'] as String),
              image: row['image'] as Uint8List
            ),
          )
          .toList();

      return profiles;
    } catch (error) {
      print('Error: $error');
      return [];
    }
  }

  Future<void> loadProfiles() async {
    final profiles = await fetchProfiles();
    state = profiles;
  }

  Profile getProfile(String id) {
    return state.firstWhere((profile) => profile.id == id,
        orElse: () => throw Exception('Profile not found'));
  }

  void updateProfile(Profile profile) async {
    final db = await getDatabase();
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
          'image': profile.image
        },
        where: 'id = ?',
        whereArgs: [profile.id]);

    final updatedProfiles = state.map((oldProfile) {
      if (oldProfile.id == profile.id) {
        return profile;
      } else {
        return oldProfile;
      }
    }).toList();

    state = updatedProfiles;
  }

  void addProfile(
      String name,
      String middleNames,
      String surname,
      DateTime dateOfBirth,
      Gender gender,
      String bloodType,
      bool isOrganDonor,
      Uint8List image) async {
    final newProfile = Profile(
        name: name,
        middleNames: middleNames,
        surname: surname,
        dateOfBirth: dateOfBirth,
        bloodType: bloodType,
        gender: gender,
        isOrganDonor: isOrganDonor,
        image: image);

    final db = await getDatabase();

    db.insert('profiles', {
      'id': newProfile.id,
      'name': newProfile.name,
      'middleNames': newProfile.middleNames,
      'surname': newProfile.surname,
      'dateOfBirth': newProfile.formattedDate,
      'bloodType': newProfile.bloodType,
      'gender': newProfile.gender.name,
      'isOrganDonor': newProfile.isOrganDonor.toString(),
      'image': newProfile.image
    });

    state = [...state, newProfile];
  }
}

final profilesProvider =
    StateNotifierProvider<ProfilesNotifier, List<Profile>>((ref) {
  return ProfilesNotifier();
});
