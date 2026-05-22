import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/history_event.dart';

class HistoryRepository {
  final DatabaseHelper _dbHelper;
  HistoryRepository(this._dbHelper);

  Future<void> addEvent(HistoryEvent event) async {
    final db = await _dbHelper.getDatabase();
    await db.insert('history', {
      'id': event.id,
      'profileId': event.profileId,
      'title': event.title,
      'description': event.description,
      'date': event.formattedDate,
      'eventType': event.eventType.name,
      'hasTime': event.hasTime ? 'true' : 'false',
      'provider': event.provider,
      'facility': event.facility,
    });
  }

  Future<void> updateEvent(HistoryEvent event) async {
    final db = await _dbHelper.getDatabase();
    await db.update(
        'history',
        {
          'title': event.title,
          'description': event.description,
          'date': event.formattedDate,
          'eventType': event.eventType.name,
          'hasTime': event.hasTime ? 'true' : 'false',
          'provider': event.provider,
          'facility': event.facility,
        },
        where: 'id = ?',
        whereArgs: [event.id]);
  }

  Future<List<HistoryEvent>> fetchEvents(String profileId) async {
    final db = await _dbHelper.getDatabase();
    final data = await db.rawQuery('''
      SELECT h.*, COUNT(a.id) AS attachmentCount
      FROM history h
      LEFT JOIN attachments a ON h.id = a.historyId
      WHERE h.profileId = ?
      GROUP BY h.id
    ''', [profileId]);

    return data
        .map((row) => HistoryEvent(
              id: row['id'] as String,
              profileId: row['profileId'] as String,
              title: row['title'] as String,
              description: row['description'] as String,
              date: DateTime.parse(row['date'] as String),
              eventType: row['eventType'] != null
                  ? EventType.values.firstWhere(
                      (e) => e.name == row['eventType'] as String,
                      orElse: () => EventType.other,
                    )
                  : EventType.other,
              hasTime: row['hasTime'] == 'false' ? false : true,
              provider: row['provider'] as String?,
              facility: row['facility'] as String?,
              attachmentCount: row['attachmentCount'] as int,
            ))
        .toList();
  }

  Future<void> deleteEvent(String id) async {
    final db = await _dbHelper.getDatabase();
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return HistoryRepository(dbHelper);
});
