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
              isCustomInterval: row['isCustomInterval'] == 'true',
              isActive: row['isActive'] != 'false',
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
      'isCustomInterval': checkup.isCustomInterval ? 'true' : 'false',
      'isActive': checkup.isActive ? 'true' : 'false',
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
          'isCustomInterval': checkup.isCustomInterval ? 'true' : 'false',
          'isActive': checkup.isActive ? 'true' : 'false',
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
      location: row['location'] as String?,
      doctorName: row['doctorName'] as String?,
      notes: row['notes'] as String?,
    );
  }

  Future<void> addCheckupLog(CheckupLog log) async {
    final db = await _dbHelper.getDatabase();
    await db.insert('checkup_logs', {
      'id': log.id,
      'checkupId': log.checkupId,
      'dateCompleted': log.dateCompleted.toIso8601String(),
      'location': log.location,
      'doctorName': log.doctorName,
      'notes': log.notes,
    });
  }

  Future<List<CheckupLog>> loadAllLogsForProfile(String profileId) async {
    final db = await _dbHelper.getDatabase();
    final data = await db.rawQuery('''
      SELECT cl.* FROM checkup_logs cl
      JOIN checkups c ON cl.checkupId = c.id
      WHERE c.profileId = ?
    ''', [profileId]);

    return data.map((row) => CheckupLog(
      id: row['id'] as String,
      checkupId: row['checkupId'] as String,
      dateCompleted: DateTime.parse(row['dateCompleted'] as String),
      location: row['location'] as String?,
      doctorName: row['doctorName'] as String?,
      notes: row['notes'] as String?,
    )).toList();
  }

  Future<List<CheckupLog>> loadLogsForCheckup(String checkupId) async {
    final db = await _dbHelper.getDatabase();
    final data = await db.query(
      'checkup_logs',
      where: 'checkupId = ?',
      orderBy: 'dateCompleted DESC',
    );

    return data.map((row) => CheckupLog(
      id: row['id'] as String,
      checkupId: row['checkupId'] as String,
      dateCompleted: DateTime.parse(row['dateCompleted'] as String),
      location: row['location'] as String?,
      doctorName: row['doctorName'] as String?,
      notes: row['notes'] as String?,
    )).toList();
  }

  Future<void> deleteCheckupLog(String logId) async {
    final db = await _dbHelper.getDatabase();
    await db.delete('checkup_logs', where: 'id = ?', whereArgs: [logId]);
  }
}

final checkupsRepositoryProvider = Provider<CheckupsRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return CheckupsRepository(dbHelper);
});
