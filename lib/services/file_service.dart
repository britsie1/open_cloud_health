import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileService {
  FileService({this.baseDirectory});

  final Directory? baseDirectory;
  static const String profileImagesSubdir = 'profileImages';
  static const String attachmentsSubdir = 'attachments';

  Future<String> get localPath async {
    if (baseDirectory != null) {
      return baseDirectory!.path;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } catch (_) {
      return Directory.systemTemp.path;
    }
  }

  Future<Directory> getProfileImagesDirectory() async {
    return _getDirectory(profileImagesSubdir);
  }

  Future<Directory> getAttachmentsDirectory() async {
    return _getDirectory(attachmentsSubdir);
  }

  Future<Directory> _getDirectory(String subdir, {String? nestedSubdir}) async {
    final basePath = await localPath;
    String fullPath = path.join(basePath, subdir);
    if (nestedSubdir != null) {
      fullPath = path.join(fullPath, nestedSubdir);
    }
    final directory = Directory(fullPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<String> getProfileImagePath(String profileId) async {
    final dir = await _getDirectory(profileImagesSubdir);
    final filePath = path.join(dir.path, '$profileId.jpg');
    final file = File(filePath);
    if (await file.exists() && await file.length() > 0) {
      return filePath;
    }
    return '';
  }

  Future<void> saveProfileImage(String profileId, File imageFile) async {
    final dir = await _getDirectory(profileImagesSubdir);
    final filePath = path.join(dir.path, '$profileId.jpg');
    final file = File(filePath);
    
    if (await file.exists()) {
      await file.delete();
    }
    
    await file.writeAsBytes(await imageFile.readAsBytes());
  }

  Future<void> deleteProfileImage(String profileId) async {
    final dir = await _getDirectory(profileImagesSubdir);
    final filePath = path.join(dir.path, '$profileId.jpg');
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> saveAttachment(String historyId, File file, String originalFileName) async {
    final dir = await _getDirectory(attachmentsSubdir, nestedSubdir: historyId);
    final filePath = path.join(dir.path, originalFileName);
    final newFile = File(filePath);
    await newFile.writeAsBytes(await file.readAsBytes());
    return filePath;
  }

  Future<String> getAttachmentPath(String historyId, String filename) async {
    final dir = await _getDirectory(attachmentsSubdir, nestedSubdir: historyId);
    return path.join(dir.path, filename);
  }

  Future<void> deleteAttachment(String historyId, String filename) async {
    final dir = await _getDirectory(attachmentsSubdir, nestedSubdir: historyId);
    final file = File(path.join(dir.path, filename));
    if (await file.exists()) {
      await file.delete();
    }
  }
}

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});
