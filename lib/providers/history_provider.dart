import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/history_event.dart';

class HistoryNotifier extends StateNotifier<List<HistoryEvent>> {
  HistoryNotifier() : super(const []);

  Future<String> addEvent(
      String profileId, String title, String description, DateTime date, int attachmentCount) async {
    final newEvent = HistoryEvent(
        profileId: profileId,
        title: title,
        description: description,
        date: date,
        attachmentCount: attachmentCount);

    final db = await getDatabase();

    db.insert('history', {
      'id': newEvent.id,
      'profileId': newEvent.profileId,
      'title': newEvent.title,
      'description': newEvent.description,
      'date': newEvent.formattedDate,
    });

    state = [...state, newEvent];
    state.sort((a, b) => b.date.compareTo(a.date));

    return newEvent.id;
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

    final updatedEvents = state.map((oldEvent) {
      if (oldEvent.id == event.id) {
        return event;
      } else {
        return oldEvent;
      }
    }).toList();

    state = updatedEvents;
  }

  Future<List<HistoryEvent>> _fetchEvents() async {
    final db = await getDatabase();
    //final data = await db.query('history');

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
      GROUP BY
        attachments.historyId
    ''');

    try {
      final historyEvents = data
          .map(
            (row) => HistoryEvent(
                id: row['id'] as String,
                profileId: row['profileId'] as String,
                title: row['title'] as String,
                description: row['description'] as String,
                date: DateTime.parse(row['date'] as String),
                attachmentCount: row['attachmentCount'] as int),
          )
          .toList();

      historyEvents.sort((a, b) => b.date.compareTo(a.date));

      return historyEvents;
    } catch (error) {
      print('Error: $error');
      return [];
    }
  }

  Future<void> loadEvents() async {
    final events = await _fetchEvents();
    state = events;
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryEvent>>((ref) {
  return HistoryNotifier();
});
