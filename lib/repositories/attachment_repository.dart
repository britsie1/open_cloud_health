import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/attachment.dart';

class AttachmentRepository {
  Future<void> insertAttachment(Attachment attachment) async {
    final db = await getDatabase();
    await db.insert('attachments', {
      'id': attachment.id,
      'historyId': attachment.historyId,
      'filename': attachment.filename,
      'uploadDate': formatter.format(attachment.uploadDate),
      'byteLength': attachment.byteLength,
    });
  }

  Future<List<Attachment>> getAttachments(String historyId) async {
    final db = await getDatabase();
    final data = await db.query('attachments',
        distinct: true, where: 'historyId = ?', whereArgs: [historyId]);

    if (data.isNotEmpty) {
      return data.map((row) => Attachment(
        id: row['id'] as String,
        historyId: row['historyId'] as String,
        filename: row['filename'] as String,
        uploadDate: DateTime.parse(row['uploadDate'] as String),
        byteLength: row['byteLength'] as int,
      )).toList();
    } else {
      return [];
    }
  }

  Future<void> deleteAttachments(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await getDatabase();
    String idList = ids.join(',');
    await db.delete('attachments', where: 'id in (?)', whereArgs: [idList]);
  }

  Future<Attachment?> getAttachment(String id) async {
    final db = await getDatabase();
    final data = await db
        .query('attachments', distinct: true, where: 'id = ?', whereArgs: [id]);

    return data.map((row) => Attachment(
        historyId: row['historyId'] as String,
        filename: row['filename'] as String,
        uploadDate: DateTime.parse(row['uploadDate'] as String),
        byteLength: row['byteLength'] as int),
    ).firstOrNull;
  }
}

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  return AttachmentRepository();
});
