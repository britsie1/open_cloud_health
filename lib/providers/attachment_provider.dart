import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/attachment.dart';

class AttachmentNotifier extends StateNotifier<List<Attachment>> {
  AttachmentNotifier() : super(const []);

  Future<void> addAttachments(Iterable<Attachment> attachments) async {
    final db = await getDatabase();

    for (int i = 0; i < attachments.length; i++) {
      db.insert('attachments', {
        'id': attachments.elementAt(i).id,
        'historyId': attachments.elementAt(i).historyId,
        'filename': attachments.elementAt(i).filename,
        'uploadDate': formatter.format(attachments.elementAt(i).uploadDate),
        'content': attachments.elementAt(i).content,
      });
    }
  }

  Future<List<Attachment>> getAttachments(String historyId) async {
    final db = await getDatabase();
    final data = await db.query('attachments',
        distinct: true, where: 'historyId = ?', whereArgs: [historyId]);

    if (data.isNotEmpty) {
      final attachments = data
          .map(
            (row) => Attachment(
              id: row['id'] as String,
              historyId: row['historyId'] as String,
              filename: row['filename'] as String,
              uploadDate: DateTime.parse(row['uploadDate'] as String),
              content: row['content'] as Uint8List,
            ),
          )
          .toList();

      return attachments;
    } else {
      return [];
    }
  }

  Future<void> removeAttachments(Iterable<Attachment> attachments) async {
    final db = await getDatabase();
    String idList = attachments.map((attachment) => attachment.id).toList().join(',');
    db.delete('attachments', where: 'id in (?)', whereArgs: [idList]);
  }

  Future<Attachment?> getAttachment(String id) async {
    final db = await getDatabase();
    final data = await db
        .query('attachments', distinct: true, where: 'id = ?', whereArgs: [id]);

    final attachment = data
        .map(
          (row) => Attachment(
              historyId: row['historyId'] as String,
              filename: row['filename'] as String,
              uploadDate: DateTime.parse(row['uploadDate'] as String),
              content: row['content'] as Uint8List),
        )
        .firstOrNull;

    return attachment;
  }
}

final attachmentProvider =
    StateNotifierProvider<AttachmentNotifier, List<Attachment>>((ref) {
  return AttachmentNotifier();
});
