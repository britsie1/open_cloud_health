import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/attachment.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AttachmentNotifier extends StateNotifier<List<Attachment>> {
  AttachmentNotifier() : super(const []);

  Future<void> addAttachments(Iterable<Attachment> attachments) async {
    if (attachments.isNotEmpty) {
      final db = await getDatabase();
      final appDir = await getApplicationDocumentsDirectory();
      
      Directory attachmentsDir = Directory(path.join(appDir.path, 'attachments'));
      if (!attachmentsDir.existsSync()){
        attachmentsDir.createSync();
      }

      Directory? dir;
      dir = Directory(path.join(appDir.path, 'attachments/${attachments.elementAt(0).historyId}'));
      if (!dir.existsSync()) {
        dir.createSync();
      }

      for (int i = 0; i < attachments.length; i++) {
        db.insert('attachments', {
          'id': attachments.elementAt(i).id,
          'historyId': attachments.elementAt(i).historyId,
          'filename': attachments.elementAt(i).filename,
          'uploadDate': formatter.format(attachments.elementAt(i).uploadDate),
          'byteLength': attachments.elementAt(i).byteLength,
        });

        if (attachments.elementAt(i).tempPath.isNotEmpty) {
           final filePath =
               path.join(dir.path, attachments.elementAt(i).filename);
          File copiedFile = await File(attachments.elementAt(i).tempPath).copy(filePath);
          print(copiedFile.path);
        }
      }
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
              byteLength: row['byteLength'] as int,
            ),
          )
          .toList();

      return attachments;
    } else {
      return [];
    }
  }

  Future<void> removeAttachments(Iterable<Attachment> attachments) async {
    if (attachments.isNotEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      Directory? dir;
      final db = await getDatabase();
      String idList =
          attachments.map((attachment) => attachment.id).toList().join(',');
      db.delete('attachments', where: 'id in (?)', whereArgs: [idList]);

      dir = Directory(path.join(appDir.path, 'attachments/${attachments.elementAt(0).historyId}'));
      if (dir.existsSync()) {
        for (int i = 0; i < attachments.length; i++) {
          final filePath =
              path.join(dir.path, attachments.elementAt(i).filename);
          if (File(filePath).existsSync()) {
            File(filePath).delete();
          }
        }

        if (dir.listSync().isEmpty) {
          dir.delete();
        }
      }
    }
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
              byteLength: row['byteLength'] as int),
        )
        .firstOrNull;

    return attachment;
  }
}

final attachmentProvider =
    StateNotifierProvider<AttachmentNotifier, List<Attachment>>((ref) {
  return AttachmentNotifier();
});
