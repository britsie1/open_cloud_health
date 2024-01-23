import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/history_event.dart';

class HistoryNotifier extends StateNotifier<List<HistoryEvent>> {
  HistoryNotifier() : super(const []);

  void addEvent(String userId, String title, String description, DateTime date) async {
    final newEvent = HistoryEvent(userId: userId, title: title, description: description, date: date);

    final db = await getDatabase();

    db.insert('history', {
      'id': newEvent.id,
      'userId': newEvent.userId,
      'title': newEvent.title,
      'description': newEvent.description,
      'date': newEvent.date,
    });

    state = [...state, newEvent];
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryEvent>>((ref) {
  return HistoryNotifier();
});
