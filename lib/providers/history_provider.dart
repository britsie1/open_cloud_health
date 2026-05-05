import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/repositories/history_repository.dart';

class HistoryNotifier extends FamilyAsyncNotifier<List<HistoryEvent>, String> {
  HistoryRepository get _repository => ref.read(historyRepositoryProvider);

  @override
  Future<List<HistoryEvent>> build(String arg) async {
    return _fetchEvents(arg);
  }

  Future<String> addEvent(
      String profileId, String title, String description, DateTime date, int attachmentCount) async {
    final newEvent = HistoryEvent(
        profileId: profileId,
        title: title,
        description: description,
        date: date,
        attachmentCount: attachmentCount);

    await _repository.addEvent(newEvent);

    if (state.hasValue) {
      final updatedList = [...state.value!, newEvent];
      updatedList.sort((a, b) => b.date.compareTo(a.date));
      state = AsyncValue.data(updatedList);
    }

    return newEvent.id;
  }

  Future<void> updateEvent(HistoryEvent event) async {
    await _repository.updateEvent(event);

    if (state.hasValue) {
      final updatedEvents = state.value!.map((oldEvent) {
        if (oldEvent.id == event.id) {
          return event;
        } else {
          return oldEvent;
        }
      }).toList();

      state = AsyncValue.data(updatedEvents);
    }
  }

  Future<List<HistoryEvent>> _fetchEvents(String profileId) async {
    try {
      final historyEvents = await _repository.fetchEvents(profileId);
      historyEvents.sort((a, b) => b.date.compareTo(a.date));
      return historyEvents;
    } catch (error) {
      debugPrint('Error: $error');
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    await _repository.deleteEvent(id);
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.where((event) => event.id != id).toList());
    }
  }

  Future<void> refreshEvents() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchEvents(arg));
  }
}

final historyProvider =
    AsyncNotifierProvider.family<HistoryNotifier, List<HistoryEvent>, String>(
        HistoryNotifier.new);
