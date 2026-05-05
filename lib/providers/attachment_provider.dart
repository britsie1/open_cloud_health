import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/attachment.dart';
import 'package:open_cloud_health/repositories/attachment_repository.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/utils/result.dart';

class AttachmentNotifier extends AsyncNotifier<List<Attachment>> {
  AttachmentRepository get _repository => ref.read(attachmentRepositoryProvider);
  FileService get _fileService => ref.read(fileServiceProvider);

  @override
  Future<List<Attachment>> build() async {
    return const [];
  }

  Future<Result<void, Exception>> addAttachments(Iterable<Attachment> attachments) async {
    try {
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
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<List<Attachment>> getAttachments(String historyId) async {
    return await _repository.getAttachments(historyId);
  }

  Future<Result<void, Exception>> removeAttachments(Iterable<Attachment> attachments) async {
    try {
      if (attachments.isNotEmpty) {
        List<String> ids = attachments.map((attachment) => attachment.id).toList();
        await _repository.deleteAttachments(ids);

        for (int i = 0; i < attachments.length; i++) {
          final attachment = attachments.elementAt(i);
          await _fileService.deleteAttachment(attachment.historyId, attachment.filename);
        }
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Attachment?> getAttachment(String id) async {
    return await _repository.getAttachment(id);
  }
}

final attachmentProvider =
    AsyncNotifierProvider<AttachmentNotifier, List<Attachment>>(AttachmentNotifier.new);
