import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/repositories/shared_profiles_repository.dart';

class HistoryRepository {
  final AppDatabase _db;
  final SharedProfilesRepository? _sharedRepo;
  HistoryRepository(this._db, [this._sharedRepo]);

  HistoryEvent _mapRow(TypedResult row, Expression<int> countExp) {
    final h = row.readTable(_db.history);
    final count = row.read(countExp) ?? 0;
    return HistoryEvent(
      id: h.id,
      profileId: h.profileId,
      title: h.title,
      description: h.description,
      date: h.date,
      eventType: h.eventType != null
          ? EventType.values.firstWhere(
              (e) => e.name == h.eventType,
              orElse: () => EventType.other,
            )
          : EventType.other,
      hasTime: h.hasTime ?? true,
      provider: h.provider,
      facility: h.facility,
      attachmentCount: count,
    );
  }

  Future<List<HistoryEvent>> fetchEvents(String profileId) async {
    if (_sharedRepo != null && await _sharedRepo.isSharedProfile(profileId)) {
      return _sharedRepo.getHistoryEvents(profileId);
    }
    final countExp = _db.attachments.id.count();
    final query = _db.select(_db.history).join([
      leftOuterJoin(_db.attachments, _db.attachments.historyId.equalsExp(_db.history.id)),
    ])
      ..where(_db.history.profileId.equals(profileId))
      ..groupBy([_db.history.id]);
    query.addColumns([countExp]);

    final rows = await query.get();
    return rows.map((r) => _mapRow(r, countExp)).toList();
  }

  Future<List<HistoryEvent>> fetchHistory(String profileId) => fetchEvents(profileId);

  Stream<List<HistoryEvent>> watchEvents(String profileId) {
    final countExp = _db.attachments.id.count();
    final query = _db.select(_db.history).join([
      leftOuterJoin(_db.attachments, _db.attachments.historyId.equalsExp(_db.history.id)),
    ])
      ..where(_db.history.profileId.equals(profileId))
      ..groupBy([_db.history.id]);
    query.addColumns([countExp]);

    return query.watch().map((rows) => rows.map((r) => _mapRow(r, countExp)).toList());
  }

  Future<void> addEvent(HistoryEvent event) async {
    await _db.into(_db.history).insert(
      HistoryEntry(
        id: event.id,
        profileId: event.profileId,
        title: event.title,
        description: event.description,
        date: event.date,
        eventType: event.eventType.name,
        hasTime: event.hasTime,
        provider: event.provider,
        facility: event.facility,
      ),
    );
  }

  Future<void> updateEvent(HistoryEvent event) async {
    await _db.update(_db.history).replace(
      HistoryEntry(
        id: event.id,
        profileId: event.profileId,
        title: event.title,
        description: event.description,
        date: event.date,
        eventType: event.eventType.name,
        hasTime: event.hasTime,
        provider: event.provider,
        facility: event.facility,
      ),
    );
  }

  Future<void> deleteEvent(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.history)..where((tbl) => tbl.id.equals(id))).go();
      await (_db.delete(_db.attachments)..where((tbl) => tbl.historyId.equals(id))).go();
    });
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sharedRepo = ref.watch(sharedProfilesRepositoryProvider);
  return HistoryRepository(db, sharedRepo);
});
