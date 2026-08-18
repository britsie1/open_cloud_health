import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/intl.dart';
import 'package:open_cloud_health/models/storage_info.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/services/backup_encryption_service.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/storage/google_auth_client.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sql;

class BackupService {
  final Ref _ref;
  final GoogleSignIn _googleSignIn;

  BackupService(this._ref, {GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn.standard(scopes: [
              drive.DriveApi.driveAppdataScope,
            ]);

  FileService get _fileService => _ref.read(fileServiceProvider);
  SecureStorage get _secureStorage => _ref.read(secureStorageProvider);

  Future<drive.DriveApi?> _getDriveApi({bool interactive = true}) async {
    try {
      GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
      if (googleUser == null) {
        if (interactive) {
          googleUser = await _googleSignIn.signIn();
        } else {
          googleUser = await _googleSignIn.signInSilently();
        }
      }
      if (googleUser == null) {
        return null;
      }

      final headers = await googleUser.authHeaders;
      final client = GoogleAuthClient(headers);
      return drive.DriveApi(client);
    } catch (e) {
      debugPrint('Error getting Drive API: $e');
      return null;
    }
  }

  Future<GoogleSignInAccount?> getConnectedUser() async {
    try {
      return _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Error checking Google user: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Future<GoogleStorageInfo?> getGoogleStorageInfo({bool interactive = false}) async {
    final driveApi = await _getDriveApi(interactive: interactive);
    if (driveApi == null) {
      return null;
    }

    try {
      final about = await driveApi.about.get($fields: 'storageQuota, user');
      final currentUser = _googleSignIn.currentUser;

      final totalBytes = int.tryParse(about.storageQuota?.limit ?? '') ?? -1;
      final usedBytes = int.tryParse(about.storageQuota?.usage ?? '') ?? 0;
      final driveUsedBytes =
          int.tryParse(about.storageQuota?.usageInDrive ?? '') ?? 0;
      final trashUsedBytes =
          int.tryParse(about.storageQuota?.usageInDriveTrash ?? '') ?? 0;

      int appBackupBytes = 0;
      String? lastBackupTime;
      bool isEncryptedBackupPresent = false;

      try {
        final fileList = await driveApi.files.list(
          spaces: 'appDataFolder',
          $fields: 'files(id, name, size, modifiedTime)',
          pageSize: 1000,
        );

        if (fileList.files != null) {
          for (var f in fileList.files!) {
            if (f.size != null) {
              appBackupBytes += int.tryParse(f.size!) ?? 0;
            }
            if (f.name == 'opencloudhealth_encrypted_backup.enc') {
              isEncryptedBackupPresent = true;
              if (f.modifiedTime != null) {
                lastBackupTime = DateFormat('yyyy-MM-dd HH:mm')
                    .format(f.modifiedTime!.toLocal());
              }
            } else if (f.name == 'opencloudhealth.db' && lastBackupTime == null) {
              if (f.modifiedTime != null) {
                lastBackupTime = DateFormat('yyyy-MM-dd HH:mm')
                    .format(f.modifiedTime!.toLocal());
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error getting appData files list: $e');
      }

      final isLocalE2eEnabled = await _secureStorage.isE2eBackupEnabled();

      return GoogleStorageInfo(
        totalBytes: totalBytes,
        usedBytes: usedBytes,
        driveUsedBytes: driveUsedBytes,
        trashUsedBytes: trashUsedBytes,
        appBackupBytes: appBackupBytes,
        userEmail: currentUser?.email ?? about.user?.emailAddress,
        displayName: currentUser?.displayName ?? about.user?.displayName,
        photoUrl: currentUser?.photoUrl ?? about.user?.photoLink,
        lastBackupDateTime: lastBackupTime ?? 'Never',
        isE2eEncrypted: isEncryptedBackupPresent || isLocalE2eEnabled,
      );
    } catch (e) {
      debugPrint('Error getting Google storage info: $e');
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

      final uploadedFile =
          await driveApi.files.create(driveFile, uploadMedia: media);
      debugPrint('Successfully uploaded $fileName (ID: ${uploadedFile.id})');

      if (oldFileId != null) {
        await driveApi.files.delete(oldFileId);
        debugPrint('Deleted old version of $fileName');
      }
    } catch (e) {
      debugPrint('Error uploading file ${file.path}: $e');
    }
  }

  Future<void> _deleteDriveItem(
      String name, String parentId, drive.DriveApi driveApi) async {
    try {
      final query =
          "name = '$name' and '$parentId' in parents and trashed = false";
      final fileList = await driveApi.files.list(
        q: query,
        spaces: 'appDataFolder',
        $fields: 'files(id, name)',
      );
      if (fileList.files != null) {
        for (var file in fileList.files!) {
          if (file.id != null) {
            await driveApi.files.delete(file.id!);
            debugPrint('Deleted old item from Drive: ${file.name}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting item $name from Drive: $e');
    }
  }


  Future<String> backupToGoogleDrive({
    String? overridePassword,
    bool interactive = true,
  }) async {
    debugPrint('Starting backup to Google Drive (interactive: $interactive)...');
    final driveApi = await _getDriveApi(interactive: interactive);
    if (driveApi == null) {
      debugPrint('Failed to get Drive API');
      return '';
    }

    final isCustomE2e = await _secureStorage.isE2eBackupEnabled();
    final customPassword = overridePassword ??
        await _secureStorage.getE2eCachedPassword() ??
        await _secureStorage.getE2eRecoveryKey();
    final localMasterKey = await _secureStorage.getOrCreateLocalMasterKey();

    final effectiveEncryptionKey =
        (isCustomE2e && customPassword != null && customPassword.isNotEmpty)
            ? customPassword
            : localMasterKey;

    debugPrint(
        'Executing Encrypted Cloud Backup (mode: ${isCustomE2e ? "custom_password" : "account_bound"})...');

    // 1. Collect local database & directories
    final dbPath = await sql.getDatabasesPath();
    final dbFile = File(path.join(dbPath, 'opencloudhealth.db'));
    final profileImagesDir = await _fileService.getProfileImagesDirectory();
    final attachmentsDir = await _fileService.getAttachmentsDirectory();

    // 2. Create in-memory ZIP containing database, photos, and attachments
    final zipBytes = BackupEncryptionService.createZipArchive(
      dbFile: dbFile,
      profileImagesDir: profileImagesDir,
      attachmentsDir: attachmentsDir,
    );

    // 3. Encrypt ZIP bundle with AES-256
    final encryptedBytes = BackupEncryptionService.encryptBundle(
        zipBytes, effectiveEncryptionKey);

    // 4. Save to temporary file and upload
    final tempDir = await getTemporaryDirectory();
    final tempEncFile =
        File(path.join(tempDir.path, 'opencloudhealth_encrypted_backup.enc'));
    await tempEncFile.writeAsBytes(encryptedBytes, flush: true);

    await _uploadFile(tempEncFile, 'appDataFolder', driveApi);

    // 5. Clean up temporary file
    if (await tempEncFile.exists()) {
      await tempEncFile.delete();
    }

    // 6. Account-Bound Keyring Management
    if (!isCustomE2e) {
      // Escrow local master key in private appDataFolder for zero-lockout cross-device restore
      final keyringFile =
          File(path.join(tempDir.path, 'och_keyring.dat'));
      await keyringFile.writeAsString(localMasterKey, flush: true);
      await _uploadFile(keyringFile, 'appDataFolder', driveApi);
      if (await keyringFile.exists()) {
        await keyringFile.delete();
      }
    } else {
      // Custom E2E password active: delete escrowed keyring so only user password can decrypt
      await _deleteDriveItem('och_keyring.dat', 'appDataFolder', driveApi);
    }

    // 7. Delete legacy unencrypted files from Drive if any exist
    await _deleteDriveItem('opencloudhealth.db', 'appDataFolder', driveApi);
    await _deleteDriveItem('profileImages', 'appDataFolder', driveApi);
    await _deleteDriveItem('attachments', 'appDataFolder', driveApi);

    debugPrint('Encrypted cloud backup completed successfully.');
    return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  }

  /// Evaluates whether an automated backup should run based on user's chosen frequency,
  /// idle window constraints (2:00 AM - 5:00 AM), and elapsed time.
  /// If due, silently executes the cloud backup and records the timestamp.
  Future<bool> performScheduledBackupIfDue({
    DateTime? now,
    bool enforceIdleHours = true,
  }) async {
    try {
      final connectedUser = await getConnectedUser();
      if (connectedUser == null) {
        debugPrint('Auto-backup check: User is not connected to Google Drive.');
        return false;
      }

      final frequency = await _secureStorage.getBackupFrequency();
      if (!frequency.isAutomated) {
        debugPrint('Auto-backup check: Frequency is ${frequency.name}, skipping.');
        return false;
      }

      final lastBackup = await _secureStorage.getLastAutoBackupTime();
      final isDue = frequency.isDue(
        lastBackup: lastBackup,
        now: now,
        enforceIdleHours: enforceIdleHours,
      );

      if (!isDue) {
        debugPrint('Auto-backup check: Not due yet for frequency ${frequency.name}.');
        return false;
      }

      debugPrint('Auto-backup is DUE for frequency ${frequency.name}! Starting background backup...');
      final timestamp = await backupToGoogleDrive(interactive: false);
      if (timestamp.isNotEmpty) {
        await _secureStorage.setLastAutoBackupTime(now ?? DateTime.now());
        debugPrint('Auto-backup succeeded at $timestamp');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error performing scheduled backup: $e');
      return false;
    }
  }

  Future<String> getLastBackupDateTime() async {
    final driveApi = await _getDriveApi(interactive: true);
    if (driveApi == null) {
      return '';
    }

    try {
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        $fields: 'files(id, name, modifiedTime)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return 'Never';
      }

      // Check encrypted first, then unencrypted db
      final encFile = fileList.files!.firstWhere(
        (f) => f.name == 'opencloudhealth_encrypted_backup.enc',
        orElse: () => drive.File(),
      );

      if (encFile.modifiedTime != null) {
        return DateFormat('yyyy-MM-dd HH:mm')
            .format(encFile.modifiedTime!.toLocal());
      }

      final dbFile = fileList.files!.firstWhere(
        (f) => f.name == 'opencloudhealth.db',
        orElse: () => drive.File(),
      );

      if (dbFile.modifiedTime != null) {
        return DateFormat('yyyy-MM-dd HH:mm')
            .format(dbFile.modifiedTime!.toLocal());
      }

      return 'Never';
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

  Future<void> restoreFromBackup({String? password}) async {
    debugPrint('Starting restore from backup...');
    final driveApi = await _getDriveApi(interactive: true);
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

    final encryptedFile = fileList.files!.firstWhere(
      (f) => f.name == 'opencloudhealth_encrypted_backup.enc',
      orElse: () => drive.File(),
    );

    final keyringFile = fileList.files!.firstWhere(
      (f) => f.name == 'och_keyring.dat',
      orElse: () => drive.File(),
    );

    if (encryptedFile.id != null) {
      debugPrint('Found encrypted backup on Google Drive. Decrypting...');
      String? effectivePassword = password ??
          await _secureStorage.getE2eCachedPassword() ??
          await _secureStorage.getE2eRecoveryKey();

      // If no custom password/recovery key, check if account-bound keyring exists in Drive
      if (effectivePassword == null || effectivePassword.isEmpty) {
        if (keyringFile.id != null) {
          debugPrint('Found account-bound keyring on Google Drive. Fetching escrowed key...');
          try {
            final keyringMedia = await driveApi.files.get(
              keyringFile.id!,
              downloadOptions: drive.DownloadOptions.fullMedia,
            ) as drive.Media;
            final keyBytesBuilder = BytesBuilder();
            await for (var chunk in keyringMedia.stream) {
              keyBytesBuilder.add(chunk);
            }
            final escrowedKey = utf8.decode(keyBytesBuilder.toBytes()).trim();
            if (escrowedKey.isNotEmpty) {
              effectivePassword = escrowedKey;
              // Store master key in device hardware keystore (Apple Keychain / Android Keystore)
              await _secureStorage.setLocalMasterKey(escrowedKey);
            }
          } catch (e) {
            debugPrint('Failed to fetch keyring: $e');
          }
        }
      }

      // If still not available, check local hardware master key
      effectivePassword ??= await _secureStorage.getLocalMasterKey();

      if (effectivePassword == null || effectivePassword.isEmpty) {
        throw const FormatException(
            'This cloud backup is protected with a custom encryption password or recovery key. Please enter your password to restore.');
      }

      final media = await driveApi.files.get(
        encryptedFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytesBuilder = BytesBuilder();
      await for (var chunk in media.stream) {
        bytesBuilder.add(chunk);
      }
      final encryptedBytes = bytesBuilder.toBytes();

      // Decrypt bundle
      final zipBytes = BackupEncryptionService.decryptBundle(
          encryptedBytes, effectivePassword);

      // Unpack into db and document directories
      final dbPath = await sql.getDatabasesPath();
      final localBaseDir = await _fileService.localPath;
      BackupEncryptionService.unpackZipArchive(
        zipBytes: zipBytes,
        dbDirectoryPath: dbPath,
        localBasePath: localBaseDir,
      );
    } else {
      debugPrint('Found standard legacy unencrypted backup. Restoring files...');
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
    }

    // Reload profiles after database restore
    await _ref.read(profilesProvider.notifier).loadProfiles();
    debugPrint('Restore completed successfully.');
  }

  /// Exports all local health records (database + profile photos + attachments)
  /// to an encrypted .ochbackup file. If [customPassword] is provided, encrypts
  /// with that password; otherwise uses the hardware-backed master key.
  Future<File> exportLocalBackup({String? customPassword}) async {
    final dbPath = await sql.getDatabasesPath();
    final dbFile = File(path.join(dbPath, 'opencloudhealth.db'));
    final profileImagesDir = await _fileService.getProfileImagesDirectory();
    final attachmentsDir = await _fileService.getAttachmentsDirectory();

    final localMasterKey = await _secureStorage.getOrCreateLocalMasterKey();
    final effectiveKey =
        (customPassword != null && customPassword.isNotEmpty)
            ? customPassword
            : localMasterKey;

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final exportFilePath =
        path.join(tempDir.path, 'opencloudhealth_backup_$timestamp.ochbackup');

    final exportedFile = await BackupEncryptionService.exportLocalBackupToFile(
      dbFile: dbFile,
      targetFilePath: exportFilePath,
      profileImagesDir: profileImagesDir,
      attachmentsDir: attachmentsDir,
      encryptionPasswordOrKey: effectiveKey,
    );

    return exportedFile;
  }

  /// Imports and restores an encrypted .ochbackup file.
  /// First attempts decryption with [customPassword] if provided,
  /// then falls back to the device's hardware master key.
  Future<void> importLocalBackup(File backupFile, {String? customPassword}) async {
    final dbPath = await sql.getDatabasesPath();
    final localBaseDir = await _fileService.localPath;

    final localMasterKey = await _secureStorage.getOrCreateLocalMasterKey();
    final effectiveKey =
        (customPassword != null && customPassword.isNotEmpty)
            ? customPassword
            : localMasterKey;

    await BackupEncryptionService.importLocalBackupFromFile(
      backupFile: backupFile,
      dbDirectoryPath: dbPath,
      localBasePath: localBaseDir,
      encryptionPasswordOrKey: effectiveKey,
    );

    // Reload profiles and active state
    await _ref.read(profilesProvider.notifier).loadProfiles();
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref);
});
