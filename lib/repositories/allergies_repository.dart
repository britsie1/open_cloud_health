import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/allergy.dart';

class AllergiesRepository {
  final DatabaseHelper _dbHelper;
  AllergiesRepository(this._dbHelper);

  Future<List<Allergy>> getAllergies(String profileId) async {
    final db = await _dbHelper.getDatabase();
    final data = await db.query('allergy',
        where: 'profileId = ?', whereArgs: [profileId]);

    return data
        .map((row) => Allergy(
              id: row['id'] as String,
              profileId: row['profileId'] as String,
              name: row['name'] as String,
              note: row['note'] as String,
            ))
        .toList();
  }

  Future<void> addAllergy(Allergy allergy) async {
    final db = await _dbHelper.getDatabase();
    await db.insert('allergy', {
      'id': allergy.id,
      'profileId': allergy.profileId,
      'name': allergy.name,
      'note': allergy.note,
    });
  }

  Future<void> deleteAllergy(String id) async {
    final db = await _dbHelper.getDatabase();
    await db.delete('allergy', where: 'id = ?', whereArgs: [id]);
  }
}

final allergiesRepositoryProvider = Provider<AllergiesRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return AllergiesRepository(dbHelper);
});
