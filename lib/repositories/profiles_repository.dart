import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/profile.dart';

class ProfilesRepository {
  final AppDatabase _db;
  ProfilesRepository(this._db);

  Profile _mapEntry(ProfileEntry row) {
    return Profile(
      id: row.id,
      name: row.name,
      middleNames: row.middleNames,
      surname: row.surname,
      dateOfBirth: DateTime.parse(row.dateOfBirth),
      bloodType: row.bloodType,
      gender: Gender.values.byName(row.gender),
      isOrganDonor: row.isOrganDonor == 'true',
      trackOvulation: row.trackOvulation != null ? (row.trackOvulation == 'true') : true,
      isArchived: row.isArchived != null ? (row.isArchived == 'true') : false,
      archivedAt: row.archivedAt != null ? DateTime.parse(row.archivedAt!) : null,
      chronicConditions: row.chronicConditions != null && row.chronicConditions!.isNotEmpty
          ? row.chronicConditions!.split(',')
          : [],
    );
  }

  Future<List<Profile>> fetchProfiles({bool includeArchived = false}) async {
    final query = _db.select(_db.profiles);
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals('false') | tbl.isArchived.isNull());
    }
    final data = await query.get();
    return data.map(_mapEntry).toList();
  }

  Stream<List<Profile>> watchProfiles({bool includeArchived = false}) {
    final query = _db.select(_db.profiles);
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals('false') | tbl.isArchived.isNull());
    }
    return query.watch().map((data) => data.map(_mapEntry).toList());
  }

  Future<void> updateProfile(Profile profile) async {
    await _db.update(_db.profiles).replace(
      ProfileEntry(
        id: profile.id,
        name: profile.name,
        middleNames: profile.middleNames,
        surname: profile.surname,
        dateOfBirth: profile.formattedDate,
        bloodType: profile.bloodType,
        gender: profile.gender.name,
        isOrganDonor: profile.isOrganDonor.toString(),
        trackOvulation: profile.trackOvulation.toString(),
        isArchived: profile.isArchived.toString(),
        archivedAt: profile.archivedAt?.toIso8601String(),
        chronicConditions: profile.chronicConditions.join(','),
      ),
    );
  }

  Future<void> addProfile(Profile profile) async {
    await _db.into(_db.profiles).insert(
      ProfileEntry(
        id: profile.id,
        name: profile.name,
        middleNames: profile.middleNames,
        surname: profile.surname,
        dateOfBirth: profile.formattedDate,
        bloodType: profile.bloodType,
        gender: profile.gender.name,
        isOrganDonor: profile.isOrganDonor.toString(),
        trackOvulation: profile.trackOvulation.toString(),
        isArchived: profile.isArchived.toString(),
        archivedAt: profile.archivedAt?.toIso8601String(),
        chronicConditions: profile.chronicConditions.join(','),
      ),
    );
  }

  Future<void> deleteProfile(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.profiles)..where((tbl) => tbl.id.equals(id))).go();
      await (_db.delete(_db.history)..where((tbl) => tbl.profileId.equals(id))).go();
      await (_db.delete(_db.allergy)..where((tbl) => tbl.profileId.equals(id))).go();
      await (_db.delete(_db.medications)..where((tbl) => tbl.profileId.equals(id))).go();
      await (_db.delete(_db.checkups)..where((tbl) => tbl.profileId.equals(id))).go();
      await (_db.delete(_db.periodCycles)..where((tbl) => tbl.profileId.equals(id))).go();
      await (_db.delete(_db.vitalLogs)..where((tbl) => tbl.profileId.equals(id))).go();
      await (_db.delete(_db.emergencyContacts)..where((tbl) => tbl.profileId.equals(id))).go();
      await (_db.delete(_db.lockScreenSettings)..where((tbl) => tbl.profileId.equals(id))).go();
    });
  }
}

final profilesRepositoryProvider = Provider<ProfilesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProfilesRepository(db);
});
