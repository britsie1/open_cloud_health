import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

const uuid = Uuid();
final formatter = DateFormat('yyyy-MM-dd HH:mm');

class Attachment {
  Attachment(
      {required this.historyId,
      required this.filename,
      required this.uploadDate,
      required this.byteLength,
      String? id,
      String? tempPath})
      : id = id ?? uuid.v4(), tempPath = tempPath ?? '';

  final String id;
  final String historyId;
  final String filename;
  final DateTime uploadDate;
  final int byteLength;
  final String tempPath;

  String get formattedDate {
    return formatter.format(uploadDate);
  }

  String get fileSize {
    if (byteLength > 1024 * 1024)
    {
      return '${(byteLength / (1024 * 1024)).toStringAsFixed(2)}MB';
    }
    if (byteLength > 1024)
    {
      return '${(byteLength / 1024).toStringAsFixed(2)}kB';
    }

    return '${byteLength}bytes';
  }

  IconData get fileIcon {
    final extension = path.extension(filename);
    var icon = Icons.insert_drive_file_outlined;
    switch (extension){
      case '.jpg':
      case '.jpeg':
      case '.png':
        icon = Icons.image_outlined;
        break;
      case '.pdf':
        icon = Icons.picture_as_pdf;
        break;
    }

    return icon;
  }
}
