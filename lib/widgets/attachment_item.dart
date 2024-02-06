import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_cloud_health/models/attachment.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AttachmentItem extends StatelessWidget {
  const AttachmentItem(
      {super.key, required this.attachment, required this.onRemoveAttachment});

  final Attachment attachment;
  final void Function(Attachment attachment) onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    Future<void> openFile(Attachment attachment) async {
      var appDir = await getApplicationDocumentsDirectory();
      final attachmentDir = 'attachments/${attachment.historyId}';
      final filePath = path.join(appDir.path,attachmentDir,attachment.filename);

      if (File(filePath).existsSync()){
        OpenFile.open(filePath);
      }
      else if (attachment.tempPath.isNotEmpty){
        OpenFile.open(attachment.tempPath);
      }
      //TODO: else, show snackbar, file not found
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
