import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/repositories/history_repository.dart';

class HistoryNotifier extends StateNotifier<List<HistoryEvent>> {
  final HistoryRepository _repository;

  HistoryNotifier(this._repository) : super(const []);

  Future<String> addEvent(
      String profileId, String title, String description, DateTime date, int attachmentCount) async {
    final newEvent = HistoryEvent(
        profileId: profileId,
        title: title,
        description: description,
        date: date,
        attachmentCount: attachmentCount);

    await _repository.addEvent(newEvent);

    state = [...state, newEvent];
    state.sort((a, b) => b.date.compareTo(a.date));

    return newEvent.id;
  }

  Future<void> updateEvent(HistoryEvent event) async {
    await _repository.updateEvent(event);

    final updatedEvents = state.map((oldEvent) {
      if (oldEvent.id == event.id) {
        return event;
      } else {
        return oldEvent;
      }
    }).toList();

    state = updatedEvents;
  }

  Future<List<HistoryEvent>> _fetchEvents(String profileId) async {
    try {
      final historyEvents = await _repository.fetchEvents(profileId);
      historyEvents.sort((a, b) => b.date.compareTo(a.date));
      return historyEvents;
    } catch (error) {
      debugPrint('Error: $error');
      return [];
    }
  }

  Future<void> deleteEvent(String id) async {
    await _repository.deleteEvent(id);
    state = state.where((event) => event.id != id).toList();
  }

  Future<void> loadEvents(String profileId) async {
    final events = await _fetchEvents(profileId);
    state = events;
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryEvent>>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return HistoryNotifier(repository);
});
