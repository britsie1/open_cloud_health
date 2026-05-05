import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/attachment.dart';
import 'package:open_cloud_health/repositories/attachment_repository.dart';
import 'package:open_cloud_health/services/file_service.dart';

class AttachmentNotifier extends AsyncNotifier<List<Attachment>> {
  AttachmentRepository get _repository => ref.read(attachmentRepositoryProvider);
  FileService get _fileService => ref.read(fileServiceProvider);

  @override
  Future<List<Attachment>> build() async {
    return const [];
  }

  Future<void> addAttachments(Iterable<Attachment> attachments) async {
    if (attachments.isNotEmpty) {
      for (int i = 0; i < attachments.length; i++) {
        final attachment = attachments.elementAt(i);
        await _repository.insertAttachment(attachment);

        if (attachment.tempPath.isNotEmpty) {
          await _fileService.saveAttachment(
            attachment.historyId,
            File(attachment.tempPath),
            attachment.filename,
          );
        }
      }
    }
  }

  Future<List<Attachment>> getAttachments(String historyId) async {
    return await _repository.getAttachments(historyId);
  }

  Future<void> removeAttachments(Iterable<Attachment> attachments) async {
    if (attachments.isNotEmpty) {
      List<String> ids = attachments.map((attachment) => attachment.id).toList();
      await _repository.deleteAttachments(ids);

      for (int i = 0; i < attachments.length; i++) {
        final attachment = attachments.elementAt(i);
        await _fileService.deleteAttachment(attachment.historyId, attachment.filename);
      }
    }
  }

  Future<Attachment?> getAttachment(String id) async {
    return await _repository.getAttachment(id);
  }
}

final attachmentProvider =
    AsyncNotifierProvider<AttachmentNotifier, List<Attachment>>(AttachmentNotifier.new);
