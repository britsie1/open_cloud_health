import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/attachment.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_file_plus/open_file_plus.dart';

class AttachmentItem extends ConsumerWidget {
  const AttachmentItem(
      {super.key, required this.attachment, required this.onRemoveAttachment});

  final Attachment attachment;
  final void Function(Attachment attachment) onRemoveAttachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openFile(Attachment attachment) async {
      final fileService = ref.read(fileServiceProvider);
      final filePath = await fileService.getAttachmentPath(
          attachment.historyId, attachment.filename);

      if (await File(filePath).exists()) {
        OpenFile.open(filePath);
      } else if (attachment.tempPath.isNotEmpty) {
        OpenFile.open(attachment.tempPath);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File not found')),
          );
        }
      }
    }

    return Dismissible(
      key: ValueKey(attachment.id),
      onDismissed: (direction) {
        onRemoveAttachment(attachment);
      },
      child: ListTile(
        onTap: () {
          openFile(attachment);
        },
        leading: Icon(attachment.fileIcon),
        title: Text(attachment.filename),
        subtitle: Text(attachment.formattedDate),
        trailing: Text(attachment.fileSize),
      ),
    );
  }
}
