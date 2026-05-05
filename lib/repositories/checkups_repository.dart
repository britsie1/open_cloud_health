import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/checkup.dart';
import 'package:open_cloud_health/models/checkup_log.dart';

class CheckupsRepository {
  final DatabaseHelper _dbHelper;
  CheckupsRepository(this._dbHelper);

  Future<List<Checkup>> loadCheckups(String profileId) async {
    final db = await _dbHelper.getDatabase();
    final data = await db.query('checkups',
        where: 'profileId = ?', whereArgs: [profileId]);

    return data
        .map((row) => Checkup(
              id: row['id'] as String,
              profileId: row['profileId'] as String,
              name: row['name'] as String,
              frequencyInMonths: row['frequencyInMonths'] as int,
              iconName: row['iconName'] as String?,
            ))
        .toList();
  }

  Future<void> addCheckup(Checkup checkup) async {
    final db = await _dbHelper.getDatabase();
    await db.insert('checkups', {
      'id': checkup.id,
      'profileId': checkup.profileId,
      'name': checkup.name,
      'frequencyInMonths': checkup.frequencyInMonths,
      'iconName': checkup.iconName,
    });
  }

  Future<void> updateCheckup(Checkup checkup) async {
    final db = await _dbHelper.getDatabase();
    await db.update(
        'checkups',
        {
          'name': checkup.name,
          'frequencyInMonths': checkup.frequencyInMonths,
          'iconName': checkup.iconName,
        },
        where: 'id = ?',
        whereArgs: [checkup.id]);
  }

  Future<void> deleteCheckup(String id) async {
    final db = await _dbHelper.getDatabase();
    await db.delete('checkups', where: 'id = ?', whereArgs: [id]);
    await db.delete('checkup_logs', where: 'checkupId = ?', whereArgs: [id]);
  }

  Future<CheckupLog?> getLatestLogForCheckup(String checkupId) async {
    final db = await _dbHelper.getDatabase();
    final data = await db.query(
      'checkup_logs',
      where: 'checkupId = ?',
      whereArgs: [checkupId],
      orderBy: 'dateCompleted DESC',
      limit: 1,
    );

    if (data.isEmpty) return null;

    final row = data.first;
    return CheckupLog(
      id: row['id'] as String,
      checkupId: row['checkupId'] as String,
      dateCompleted: DateTime.parse(row['dateCompleted'] as String),
    );
  }

  Future<void> addCheckupLog(CheckupLog log) async {
    final db = await _dbHelper.getDatabase();
    await db.insert('checkup_logs', {
      'id': log.id,
      'checkupId': log.checkupId,
      'dateCompleted': log.dateCompleted.toIso8601String(),
    });
  }
}

final checkupsRepositoryProvider = Provider<CheckupsRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return CheckupsRepository(dbHelper);
});
