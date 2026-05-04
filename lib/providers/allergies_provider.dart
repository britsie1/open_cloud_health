import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/allergy.dart';

class AllergiesNotifier extends StateNotifier<List<Allergy>> {
  AllergiesNotifier() : super(const []);

  Future<void> loadAllergies(String profileId) async {
    final db = await getDatabase();
    final data = await db.query(
      'allergy',
      where: 'profileId = ?',
      whereArgs: [profileId],
    );

    final allergies = data.map((row) {
      return Allergy(
        id: row['id'] as String,
        profileId: row['profileId'] as String,
        name: row['name'] as String,
        note: row['note'] as String,
      );
    }).toList();

    state = allergies;
  }

  Future<void> addAllergy(Allergy allergy) async {
    final db = await getDatabase();
    await db.insert('allergy', {
      'id': allergy.id,
      'profileId': allergy.profileId,
      'name': allergy.name,
      'note': allergy.note,
    });

    state = [...state, allergy];
  }

  Future<void> deleteAllergy(String id) async {
    final db = await getDatabase();
    await db.delete('allergy', where: 'id = ?', whereArgs: [id]);
    state = state.where((a) => a.id != id).toList();
  }
}

final allergiesProvider = StateNotifierProvider<AllergiesNotifier, List<Allergy>>((ref) {
  return AllergiesNotifier();
});
