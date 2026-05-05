import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/attachment.dart';
import 'package:open_cloud_health/repositories/attachment_repository.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AttachmentNotifier extends AsyncNotifier<List<Attachment>> {
  AttachmentRepository get _repository => ref.read(attachmentRepositoryProvider);

  @override
  Future<List<Attachment>> build() async {
    return const [];
  }

  Future<void> addAttachments(Iterable<Attachment> attachments) async {
    if (attachments.isNotEmpty) {
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
        await _repository.insertAttachment(attachments.elementAt(i));

        if (attachments.elementAt(i).tempPath.isNotEmpty) {
           final filePath =
               path.join(dir.path, attachments.elementAt(i).filename);
          File copiedFile = await File(attachments.elementAt(i).tempPath).copy(filePath);
          debugPrint(copiedFile.path);
        }
      }
    }
  }

  Future<List<Attachment>> getAttachments(String historyId) async {
    return await _repository.getAttachments(historyId);
  }

  Future<void> removeAttachments(Iterable<Attachment> attachments) async {
    if (attachments.isNotEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      Directory? dir;
      
      List<String> ids = attachments.map((attachment) => attachment.id).toList();
      await _repository.deleteAttachments(ids);

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
    return await _repository.getAttachment(id);
  }
}

final attachmentProvider =
    AsyncNotifierProvider<AttachmentNotifier, List<Attachment>>(AttachmentNotifier.new);
