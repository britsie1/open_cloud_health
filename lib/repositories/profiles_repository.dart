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
      dateOfBirth: row.dateOfBirth,
      bloodType: row.bloodType,
      gender: Gender.values.byName(row.gender),
      isOrganDonor: row.isOrganDonor,
      trackOvulation: row.trackOvulation ?? true,
      isArchived: row.isArchived ?? false,
      archivedAt: row.archivedAt,
      chronicConditions: row.chronicConditions != null && row.chronicConditions!.isNotEmpty
          ? row.chronicConditions!.split(',')
          : [],
    );
  }

  Future<List<Profile>> fetchProfiles({bool includeArchived = false}) async {
    final query = _db.select(_db.profiles);
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals(false) | tbl.isArchived.isNull());
    }
    final data = await query.get();
    return data.map(_mapEntry).toList();
  }

  Future<List<Profile>> fetchArchivedProfiles() async {
    final query = _db.select(_db.profiles)
      ..where((tbl) => tbl.isArchived.equals(true));
    final data = await query.get();
    return data.map(_mapEntry).toList();
  }

  Stream<List<Profile>> watchProfiles({bool includeArchived = false}) {
    final query = _db.select(_db.profiles);
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals(false) | tbl.isArchived.isNull());
    }
    return query.watch().map((data) => data.map(_mapEntry).toList());
  }

  Future<Profile?> getProfile(String id) async {
    final query = _db.select(_db.profiles)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapEntry(row) : null;
  }

  Future<void> updateProfile(Profile profile) async {
    await _db.update(_db.profiles).replace(
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
  }

  Future<void> addProfile(Profile profile) async {
    await _db.into(_db.profiles).insert(
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
  }

  Future<void> archiveProfile(String id) async {
    await (_db.update(_db.profiles)..where((tbl) => tbl.id.equals(id)))
        .write(ProfilesCompanion(
      isArchived: const Value(true),
      archivedAt: Value(DateTime.now()),
    ));
  }

  Future<void> restoreProfile(String id) async {
    await (_db.update(_db.profiles)..where((tbl) => tbl.id.equals(id)))
        .write(const ProfilesCompanion(
      isArchived: Value(false),
      archivedAt: Value(null),
    ));
  }

  Future<void> deleteProfile(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.profiles)..where((tbl) => tbl.id.equals(id))).go();
      // SQLite foreign key CASCADE automatically cleans up child tables,
      // but explicit delete ensures compatibility across all environments.
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

  Future<void> deleteProfilePermanently(String id) => deleteProfile(id);
}

final profilesRepositoryProvider = Provider<ProfilesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProfilesRepository(db);
});
