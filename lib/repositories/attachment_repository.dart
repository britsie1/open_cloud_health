import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/attachment.dart';

class AttachmentRepository {
  final AppDatabase _db;
  AttachmentRepository(this._db);

  Attachment _mapEntry(AttachmentEntry row) {
    return Attachment(
      id: row.id,
      historyId: row.historyId,
      filename: row.filename,
      uploadDate: DateTime.parse(row.uploadDate),
      byteLength: row.byteLength,
    );
  }

  Future<void> insertAttachment(Attachment attachment) async {
    await _db.into(_db.attachments).insert(
      AttachmentEntry(
        id: attachment.id,
        historyId: attachment.historyId,
        filename: attachment.filename,
        uploadDate: attachment.formattedDate,
        byteLength: attachment.byteLength,
      ),
    );
  }

  Future<List<Attachment>> getAttachments(String historyId) async {
    final query = _db.select(_db.attachments)
      ..where((tbl) => tbl.historyId.equals(historyId));
    final data = await query.get();
    return data.map(_mapEntry).toList();
  }

  Stream<List<Attachment>> watchAttachments(String historyId) {
    final query = _db.select(_db.attachments)
      ..where((tbl) => tbl.historyId.equals(historyId));
    return query.watch().map((data) => data.map(_mapEntry).toList());
  }

  Future<void> deleteAttachments(List<String> ids) async {
    if (ids.isEmpty) return;
    await (_db.delete(_db.attachments)..where((tbl) => tbl.id.isIn(ids))).go();
  }

  Future<Attachment?> getAttachment(String id) async {
    final query = _db.select(_db.attachments)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapEntry(row) : null;
  }
}

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AttachmentRepository(db);
});
