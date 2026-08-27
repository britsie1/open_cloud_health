import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileService {
  FileService({this.baseDirectory});

  final Directory? baseDirectory;
  static const String profileImagesSubdir = 'profileImages';
  static const String attachmentsSubdir = 'attachments';
  static const String insuranceCardsSubdir = 'insuranceCards';

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

  Future<Directory> getInsuranceCardsDirectory() async {
    return _getDirectory(insuranceCardsSubdir);
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

  Future<String> getInsuranceCardPath(String profileId, String side) async {
    final dir = await _getDirectory(insuranceCardsSubdir);
    final filePath = path.join(dir.path, '${profileId}_$side.jpg');
    final file = File(filePath);
    if (await file.exists() && await file.length() > 0) {
      return filePath;
    }
    return '';
  }

  Future<String> saveInsuranceCardImage(String profileId, String side, File imageFile) async {
    final dir = await _getDirectory(insuranceCardsSubdir);
    final filePath = path.join(dir.path, '${profileId}_$side.jpg');
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
    await file.writeAsBytes(await imageFile.readAsBytes());
    return filePath;
  }

  Future<void> deleteInsuranceCardImages(String profileId) async {
    final dir = await _getDirectory(insuranceCardsSubdir);
    final front = File(path.join(dir.path, '${profileId}_front.jpg'));
    if (await front.exists()) await front.delete();
    final back = File(path.join(dir.path, '${profileId}_back.jpg'));
    if (await back.exists()) await back.delete();
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

  Future<void> deleteHistoryAttachmentsDirectory(String historyId) async {
    final dir = await _getDirectory(attachmentsSubdir, nestedSubdir: historyId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> deleteProfileFiles(String profileId, List<String> historyIds) async {
    await deleteProfileImage(profileId);
    await deleteInsuranceCardImages(profileId);
    for (final historyId in historyIds) {
      await deleteHistoryAttachmentsDirectory(historyId);
    }
  }

  Future<void> deleteAllLocalFiles() async {
    try {
      final profileDir = await getProfileImagesDirectory();
      if (await profileDir.exists()) {
        await profileDir.delete(recursive: true);
      }
    } catch (_) {}
    try {
      final attachmentsDir = await getAttachmentsDirectory();
      if (await attachmentsDir.exists()) {
        await attachmentsDir.delete(recursive: true);
      }
    } catch (_) {}
    try {
      final insuranceDir = await getInsuranceCardsDirectory();
      if (await insuranceDir.exists()) {
        await insuranceDir.delete(recursive: true);
      }
    } catch (_) {}
  }
}

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});
