import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/history_event.dart';

class HistoryRepository {
  Future<void> addEvent(HistoryEvent event) async {
    final db = await getDatabase();
    await db.insert('history', {
      'id': event.id,
      'profileId': event.profileId,
      'title': event.title,
      'description': event.description,
      'date': event.formattedDate,
    });
  }

  Future<void> updateEvent(HistoryEvent event) async {
    final db = await getDatabase();
    await db.update(
        'history',
        {
          'title': event.title,
          'date': event.formattedDate,
          'description': event.description
        },
        where: 'id = ? AND profileId = ?',
        whereArgs: [event.id, event.profileId]);
  }

  Future<List<HistoryEvent>> fetchEvents(String profileId) async {
    final db = await getDatabase();
    final data = await db.rawQuery('''
      SELECT
        history.id,
        history.profileId,
        history.title,
        history.description,
        history.date,
        COUNT(attachments.id) as attachmentCount
      FROM
        history LEFT OUTER JOIN
        attachments ON (history.id = attachments.historyId)
      WHERE
        history.profileId = ?
      GROUP BY
        history.id
    ''', [profileId]);

    return data.map((row) => HistoryEvent(
      id: row['id'] as String,
      profileId: row['profileId'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      date: DateTime.parse(row['date'] as String),
      attachmentCount: row['attachmentCount'] as int
    )).toList();
  }

  Future<void> deleteEvent(String id) async {
    final db = await getDatabase();
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
    await db.delete('attachments', where: 'historyId = ?', whereArgs: [id]);
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});
