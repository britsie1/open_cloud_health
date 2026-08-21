import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/repositories/shared_profiles_repository.dart';

class AllergiesRepository {
  final AppDatabase _db;
  final SharedProfilesRepository? _sharedRepo;
  AllergiesRepository(this._db, [this._sharedRepo]);

  Allergy _mapEntry(AllergyEntry row) {
    return Allergy(
      id: row.id,
      profileId: row.profileId,
      name: row.name,
      note: row.note,
    );
  }

  Future<List<Allergy>> getAllergies(String profileId) async {
    if (_sharedRepo != null && await _sharedRepo.isSharedProfile(profileId)) {
      return _sharedRepo.getAllergies(profileId);
    }
    final query = _db.select(_db.allergy)..where((tbl) => tbl.profileId.equals(profileId));
    final data = await query.get();
    return data.map(_mapEntry).toList();
  }

  Future<List<Allergy>> fetchAllergies(String profileId) => getAllergies(profileId);

  Stream<List<Allergy>> watchAllergies(String profileId) async* {
    if (_sharedRepo != null && await _sharedRepo.isSharedProfile(profileId)) {
      yield await _sharedRepo.getAllergies(profileId);
      return;
    }
    final query = _db.select(_db.allergy)..where((tbl) => tbl.profileId.equals(profileId));
    yield* query.watch().map((data) => data.map(_mapEntry).toList());
  }

  Future<void> addAllergy(Allergy allergy) async {
    await _db.into(_db.allergy).insert(
      AllergyEntry(
        id: allergy.id,
        profileId: allergy.profileId,
        name: allergy.name,
        note: allergy.note,
      ),
    );
  }

  Future<void> deleteAllergy(String id) async {
    await (_db.delete(_db.allergy)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> setAllergies(String profileId, List<Allergy> allergies) async {
    await _db.transaction(() async {
      await (_db.delete(_db.allergy)..where((tbl) => tbl.profileId.equals(profileId))).go();
      for (final allergy in allergies) {
        await _db.into(_db.allergy).insert(
          AllergyEntry(
            id: allergy.id,
            profileId: profileId,
            name: allergy.name,
            note: allergy.note,
          ),
        );
      }
    });
  }
}

final allergiesRepositoryProvider = Provider<AllergiesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sharedRepo = ref.watch(sharedProfilesRepositoryProvider);
  return AllergiesRepository(db, sharedRepo);
});
