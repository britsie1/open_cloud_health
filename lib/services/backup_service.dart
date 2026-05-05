import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/intl.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/storage/google_auth_client.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;

class BackupService {
  final Ref _ref;
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(scopes: [
    drive.DriveApi.driveAppdataScope,
  ]);

  BackupService(this._ref);

  FileService get _fileService => _ref.read(fileServiceProvider);

  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      final headers = await googleUser?.authHeaders;
      if (headers == null) {
        return null;
      }

      final client = GoogleAuthClient(headers);
      return drive.DriveApi(client);
    } catch (e) {
      debugPrint('Error getting Drive API: $e');
      return null;
    }
  }

  Future<void> _uploadFile(
      File file, String parentDirId, drive.DriveApi driveApi) async {
    try {
      final fileName = path.basename(file.path);
      debugPrint('Uploading file: $fileName to folder: $parentDirId');
      
      final media = drive.Media(file.openRead(), await file.length());
      final driveFile = drive.File();
      driveFile.name = fileName;
      driveFile.modifiedTime = DateTime.now().toUtc();
      driveFile.parents = [parentDirId];

      // Check if file already exists in this folder to replace it
      String? oldFileId;
      final query =
          "name = '$fileName' and '$parentDirId' in parents and trashed = false";
      final fileList = await driveApi.files.list(
        q: query,
        spaces: 'appDataFolder',
        $fields: 'files(id, name)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        oldFileId = fileList.files!.first.id;
        debugPrint('Found existing file $fileName (ID: $oldFileId), will replace.');
      }

      final uploadedFile = await driveApi.files.create(driveFile, uploadMedia: media);
      debugPrint('Successfully uploaded $fileName (ID: ${uploadedFile.id})');

      if (oldFileId != null) {
        await driveApi.files.delete(oldFileId);
        debugPrint('Deleted old version of $fileName');
      }
    } catch (e) {
      debugPrint('Error uploading file ${file.path}: $e');
    }
  }

  Future<String?> _getOrCreateFolder(
      String name, String parentId, drive.DriveApi driveApi) async {
    try {
      debugPrint('Checking for folder: $name in parent: $parentId');
      final query =
          "name = '$name' and '$parentId' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final fileList = await driveApi.files.list(
        q: query,
        spaces: 'appDataFolder',
        $fields: 'files(id, name)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final folderId = fileList.files!.first.id;
        debugPrint('Found existing folder $name (ID: $folderId)');
        return folderId;
      }

      debugPrint('Folder $name not found, creating...');
      final folder = drive.File();
      folder.name = name;
      folder.mimeType = 'application/vnd.google-apps.folder';
      folder.parents = [parentId];

      final createdFolder = await driveApi.files.create(folder);
      debugPrint('Created folder $name (ID: ${createdFolder.id})');
      return createdFolder.id;
    } catch (e) {
      debugPrint('Error getting/creating folder $name: $e');
      return null;
    }
  }

  Future<String> backupToGoogleDrive() async {
    debugPrint('Starting backup to Google Drive...');
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      debugPrint('Failed to get Drive API');
      return '';
    }

    // 1. Backup Database
    final dbPath = await sql.getDatabasesPath();
    final dbFile = File(path.join(dbPath, 'opencloudhealth.db'));
    if (await dbFile.exists()) {
      await _uploadFile(dbFile, 'appDataFolder', driveApi);
    } else {
      debugPrint('Database file not found at ${dbFile.path}');
    }

    // 2. Backup Profile Images
    final profileImagesDir = await _fileService.getProfileImagesDirectory();
    if (await profileImagesDir.exists()) {
      final entities = profileImagesDir.listSync();
      if (entities.isNotEmpty) {
        final profileImagesFolderId = await _getOrCreateFolder(
            'profileImages', 'appDataFolder', driveApi);
        if (profileImagesFolderId != null) {
          for (var entity in entities) {
            if (entity is File) {
              await _uploadFile(entity, profileImagesFolderId, driveApi);
            }
          }
        }
      } else {
        debugPrint('No profile images to backup.');
      }
    }

    // 3. Backup Attachments
    final attachmentDir = await _fileService.getAttachmentsDirectory();
    if (await attachmentDir.exists()) {
      final historyDirs = attachmentDir.listSync();
      if (historyDirs.isNotEmpty) {
        final attachmentsFolderId = await _getOrCreateFolder(
            'attachments', 'appDataFolder', driveApi);
        if (attachmentsFolderId != null) {
          for (var historyEntity in historyDirs) {
            if (historyEntity is Directory) {
              final historyId = path.basename(historyEntity.path);
              final historyFolderId = await _getOrCreateFolder(
                  historyId, attachmentsFolderId, driveApi);
              if (historyFolderId != null) {
                final files = historyEntity.listSync();
                for (var fileEntity in files) {
                  if (fileEntity is File) {
                    await _uploadFile(fileEntity, historyFolderId, driveApi);
                  }
                }
              }
            }
          }
        }
      } else {
        debugPrint('No attachments to backup.');
      }
    }

    debugPrint('Backup completed successfully.');
    return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  }

  Future<String> getLastBackupDateTime() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      return '';
    }

    try {
      final fileList = await driveApi.files.list(
        q: "name = 'opencloudhealth.db' and 'appDataFolder' in parents and trashed = false",
        spaces: 'appDataFolder',
        $fields: 'files(id, name, modifiedTime)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return 'Never';
      }

      final databaseFile = fileList.files!.first;
      return DateFormat('yyyy-MM-dd HH:mm').format(databaseFile.modifiedTime!.toLocal());
    } catch (e) {
      debugPrint('Error getting last backup date: $e');
      return 'Error';
    }
  }

  Future<void> _downloadFile(String fileId, String fileName, String restorePath,
      drive.DriveApi driveApi) async {
    try {
      debugPrint('Downloading file: $fileName (ID: $fileId) to $restorePath');
      final media = await driveApi.files.get(fileId,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      final file = File(path.join(restorePath, fileName));
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      final IOSink sink = file.openWrite();
      await sink.addStream(media.stream);
      await sink.close();
      
      debugPrint('Successfully downloaded $fileName');
    } catch (e) {
      debugPrint('Error downloading file $fileName: $e');
    }
  }

  Future<void> _restoreFolder(
      String folderId, String localPath, drive.DriveApi driveApi) async {
    debugPrint('Restoring folder: $folderId to $localPath');
    final fileList = await driveApi.files.list(
      q: "'$folderId' in parents and trashed = false",
      spaces: 'appDataFolder',
      $fields: 'files(id, name, mimeType)',
    );

    if (fileList.files == null || fileList.files!.isEmpty) {
      debugPrint('Folder (ID: $folderId) is empty or not found.');
      return;
    }

    for (var file in fileList.files!) {
      if (file.mimeType == 'application/vnd.google-apps.folder') {
        await _restoreFolder(
            file.id!, path.join(localPath, file.name!), driveApi);
      } else {
        await _downloadFile(file.id!, file.name!, localPath, driveApi);
      }
    }
  }

  Future<void> restoreFromBackup() async {
    debugPrint('Starting restore from backup...');
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      debugPrint('Failed to get Drive API');
      return;
    }

    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "'appDataFolder' in parents and trashed = false",
      $fields: 'files(id, name, mimeType)',
    );

    if (fileList.files == null || fileList.files!.isEmpty) {
      debugPrint('No backup files found in App Data folder.');
      return;
    }

    final localBaseDir = await _fileService.localPath;

    for (var file in fileList.files!) {
      debugPrint('Processing backup item: ${file.name} (${file.mimeType})');
      if (file.name == 'opencloudhealth.db') {
        final dbPath = await sql.getDatabasesPath();
        await _downloadFile(file.id!, file.name!, dbPath, driveApi);
      } else if (file.name == 'profileImages' || file.name == 'attachments') {
        await _restoreFolder(
            file.id!, path.join(localBaseDir, file.name!), driveApi);
      }
    }

    // Reload profiles after database restore
    await _ref.read(profilesProvider.notifier).loadProfiles();
    debugPrint('Restore completed successfully.');
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref);
});
