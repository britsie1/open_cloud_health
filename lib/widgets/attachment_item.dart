import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_cloud_health/models/attachment.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class AttachmentItem extends StatelessWidget {
  const AttachmentItem(
      {super.key, required this.attachment, required this.onRemoveAttachment});

  final Attachment attachment;
  final void Function(Attachment attachment) onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    Future<void> openFile(Attachment attachment) async {
      var tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${attachment.filename}';
      bool fileExists = await File(filePath).exists();
      if (!fileExists) {
        File file = await File(filePath).create();
        file.writeAsBytes(attachment.content);
      }

      OpenFile.open(filePath);
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
