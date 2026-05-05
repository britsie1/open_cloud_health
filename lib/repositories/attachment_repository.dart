import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/attachment.dart';

class AttachmentRepository {
  final DatabaseHelper _dbHelper;
  AttachmentRepository(this._dbHelper);

  Future<void> insertAttachment(Attachment attachment) async {
    final db = await _dbHelper.getDatabase();
    await db.insert('attachments', {
      'id': attachment.id,
      'historyId': attachment.historyId,
      'filename': attachment.filename,
      'uploadDate': attachment.formattedDate,
      'byteLength': attachment.byteLength,
    });
  }

  Future<List<Attachment>> getAttachments(String historyId) async {
    final db = await _dbHelper.getDatabase();
    final data = await db.query('attachments',
        where: 'historyId = ?', whereArgs: [historyId]);

    return data
        .map((row) => Attachment(
              id: row['id'] as String,
              historyId: row['historyId'] as String,
              filename: row['filename'] as String,
              uploadDate: DateTime.parse(row['uploadDate'] as String),
              byteLength: row['byteLength'] as int,
            ))
        .toList();
  }

  Future<void> deleteAttachments(List<String> ids) async {
    final db = await _dbHelper.getDatabase();
    for (final id in ids) {
      await db.delete('attachments', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<Attachment?> getAttachment(String id) async {
    final db = await _dbHelper.getDatabase();
    final data =
        await db.query('attachments', where: 'id = ?', whereArgs: [id]);

    if (data.isEmpty) {
      return null;
    }

    final row = data.first;
    return Attachment(
      id: row['id'] as String,
      historyId: row['historyId'] as String,
      filename: row['filename'] as String,
      uploadDate: DateTime.parse(row['uploadDate'] as String),
      byteLength: row['byteLength'] as int,
    );
  }
}

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return AttachmentRepository(dbHelper);
});
