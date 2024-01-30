import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/history_event.dart';

class HistoryNotifier extends StateNotifier<List<HistoryEvent>> {
  HistoryNotifier() : super(const []);

  Future<String> addEvent(
      String profileId, String title, String description, DateTime date) async {
    final newEvent = HistoryEvent(
        profileId: profileId,
        title: title,
        description: description,
        date: date);

    final db = await getDatabase();

    db.insert('history', {
      'id': newEvent.id,
      'profileId': newEvent.profileId,
      'title': newEvent.title,
      'description': newEvent.description,
      'date': newEvent.formattedDate,
    });

    state = [...state, newEvent];

    return newEvent.id;
  }

  Future<void> updateEvent(HistoryEvent event) async {
    final db = await getDatabase();
    await db.update('history', {
      'title': event.title,
      'date': event.formattedDate,
      'description': event.description
    },
    where: 'id = ? AND profileId = ?',
    whereArgs: [event.id, event.profileId]);

    final updatedEvents = state.map((oldEvent) {
      if (oldEvent.id == event.id)
      {
        return event;
      }
      else {
        return oldEvent;
      }
    }).toList();

    state = updatedEvents;
  }

  Future<List<HistoryEvent>> _fetchEvents() async {
    final db = await getDatabase();
    final data = await db.query('history');

    try {
      final historyEvents = data
          .map(
            (row) => HistoryEvent(
                id: row['id'] as String,
                profileId: row['profileId'] as String,
                title: row['title'] as String,
                description: row['description'] as String,
                date: DateTime.parse(row['date'] as String)),
          )
          .toList();

      historyEvents.sort((a,b) => b.date.compareTo(a.date));

      return historyEvents;
    } catch (error) {
      print('Error: $error');
      return [];
    }
  }

  Future<HistoryEvent?> _fetchEvent(String id) async {
    final db = await getDatabase();
    final data = await db.query('history', where: 'id = ?', whereArgs: [id]);
    return data.map((row) => HistoryEvent(
      id: row['id'] as String,
      profileId: row['profileId'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      date: DateTime.parse(row['date'] as String))).firstOrNull;
  }

  Future<void> loadEvents() async {
    final events = await _fetchEvents();
    state = events;
  }

  Future<HistoryEvent?> loadEvent(String id) async {
    final event = await _fetchEvent(id);
    return event;
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryEvent>>((ref) {
  return HistoryNotifier();
});
