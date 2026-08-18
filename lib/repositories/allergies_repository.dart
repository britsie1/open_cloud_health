import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/allergy.dart';

class AllergiesRepository {
  final AppDatabase _db;
  AllergiesRepository(this._db);

  Allergy _mapEntry(AllergyEntry row) {
    return Allergy(
      id: row.id,
      profileId: row.profileId,
      name: row.name,
      note: row.note,
    );
  }

  Future<List<Allergy>> getAllergies(String profileId) async {
    final query = _db.select(_db.allergy)..where((tbl) => tbl.profileId.equals(profileId));
    final data = await query.get();
    return data.map(_mapEntry).toList();
  }

  Stream<List<Allergy>> watchAllergies(String profileId) {
    final query = _db.select(_db.allergy)..where((tbl) => tbl.profileId.equals(profileId));
    return query.watch().map((data) => data.map(_mapEntry).toList());
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
}

final allergiesRepositoryProvider = Provider<AllergiesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AllergiesRepository(db);
});
