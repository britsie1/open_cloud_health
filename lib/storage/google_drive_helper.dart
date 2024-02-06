import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/cloudresourcemanager/v2.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/intl.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/storage/google_auth_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

final _googleSignIn = GoogleSignIn.standard(scopes: [
  drive.DriveApi.driveAppdataScope,
]);

Future<drive.DriveApi?> _getDriveApi() async {
  final googleUser = await _googleSignIn.signIn();
  final headers = await googleUser?.authHeaders;
  if (headers == null) {
    return null;
  }

  final client = GoogleAuthClient(headers);
  final driveApi = drive.DriveApi(client);
  return driveApi;
}

Future<void> _uploadFile(
    File file, String parentDirId, drive.DriveApi driveApi) async {
  try {
    final Stream<List<int>> mediaStream = file.openRead().asBroadcastStream();
    final media = drive.Media(mediaStream, file.lengthSync());
    final driveFile = drive.File();
    driveFile.name = path.basename(file.path);
    driveFile.modifiedTime = DateTime.now().toUtc();
    driveFile.parents = [parentDirId];

    String? oldFileId;
    final fileList = await driveApi.files
        .list(spaces: parentDirId, $fields: 'files(id, name)');

    if (fileList.files != null) {
      final oldFile = fileList.files!
          .where((file) => file.name == driveFile.name)
          .firstOrNull;
      if (oldFile != null) {
        oldFileId = oldFile.id;
      }
    }

    //create the backup file
    await driveApi.files.create(driveFile, uploadMedia: media);

    //delete the old file
    if (oldFileId != null) {
      driveApi.files.delete(oldFileId);
    }
  } on PlatformException catch (exception) {
    return;
  }
}

Future<String?> _createBackupFolder (
    String name, String parentId, drive.DriveApi driveApi) async {
  final folder = drive.File();
  folder.name = name;
  folder.mimeType = 'application/vnd.google-apps.folder';
  if (parentId.isNotEmpty) {
    folder.parents = [parentId];
  }

  final file = await driveApi.files.create(folder);
  return file.id;
}

Future<String> backupToGoogleDrive() async {
  final driveApi = await _getDriveApi();
  if (driveApi == null) {
    return '';
  }
  Directory appDir = await getApplicationDocumentsDirectory();
  
  final attachmentDir = Directory(path.join(appDir.path, 'attachments'));
  final profileImagesDir = Directory(path.join(appDir.path, 'profileImages'));

  if (attachmentDir.existsSync()){
    final attachmentFiles = attachmentDir.listSync(recursive: true);
    List<Map<String, String>> folders = [];
    final attachmentsFolderId = await _createBackupFolder('attachments', '', driveApi);
    for (int i = 0; i < attachmentFiles.length; i++) {
      final file = attachmentFiles[i];
      //final parentname = path.basename(file.parent.path);
      final filename = path.basename(file.path);
      if (file is Directory) {
          final folderId = await _createBackupFolder(filename, attachmentsFolderId!, driveApi);
          if (folderId != null){
            Map<String, String> folder = {'name': filename, 'id': folderId};
            folders.add(folder);
          }
        } else if (file is File) {
          final folder = folders.where((folder) => folder['name'] == path.basename(file.parent.path)).firstOrNull;
          if (folder != null){
            await _uploadFile(File(file.path), folder['id']!, driveApi);
          }
        }
    }
  }
  
  // if (profileImagesDir.existsSync()){
  //   final profileImageFiles = profileImagesDir.listSync();
  //   for (int i = 0; i < profileImageFiles.length; i++) {
  //     final file = profileImageFiles[i];
  //     await _uploadFile(File(file.path), file.parent, driveApi);
  //   }
  // }

  // final dbPath = await sql.getDatabasesPath();
  // final dbFilePath = path.join(dbPath, 'opencloudhealth.db');
  // final dbFile = File(dbFilePath);

  // await _uploadFile(dbFile, dbFile.parent, driveApi);

  return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
}

Future<String> getLastBackupDateTime() async {
  final driveApi = await _getDriveApi();
  if (driveApi == null) {
    return '';
  }

  final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      $fields: 'files(id, name, modifiedTime, createdTime)');
  final files = fileList.files;
  if (files == null) {
    return '';
  } else {
    if (files.isNotEmpty) {
      final databaseFile = files
          .where(
            (file) => file.name == 'opencloudhealth.db',
          )
          .firstOrNull;
      if (databaseFile != null) {
        return DateFormat('yyyy-MM-dd HH:mm')
            .format(databaseFile.modifiedTime ?? DateTime.now());
      }
    }

    return 'Never';
  }
}

Future<void> _downloadFromGoogleDrive(
    String fileId, String fileName, String restorePath) async {
  if (fileId.isNotEmpty) {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      return;
    }

    List<int> dataStore = [];
    drive.Media media = await driveApi.files.get(fileId,
        downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    media.stream.listen((data) {
      dataStore.insertAll(dataStore.length, data);
    }, onDone: () async {
      final filePath = path.join(restorePath, fileName);
      final fileLocation = await File(filePath).create();
      await fileLocation.writeAsBytes(dataStore);
    }, onError: (error) {
      print("Some Error");
    });
  }
}

Future<void> restoreFromBackup(WidgetRef ref) async {
  final driveApi = await _getDriveApi();
  if (driveApi == null) {
    return;
  }

  final fileList = await driveApi.files
      .list(spaces: 'appDataFolder', $fields: 'files(id, name)');

  if (fileList.files != null) {
    Directory appDir = await getApplicationDocumentsDirectory();

    for (int i = 0; i < fileList.files!.length; i++) {
      final file = fileList.files![i];
      if (file.name != 'opencloudhealth.db') {
        await _downloadFromGoogleDrive(file.id!, file.name!, appDir.path);
      }
    }

    String? databaseFileId;
    final databaseFile = fileList.files!
        .where((file) => file.name == 'opencloudhealth.db')
        .firstOrNull;
    if (databaseFile != null) {
      databaseFileId = databaseFile.id;
    }

    if (databaseFileId != null) {
      final dbPath = await sql.getDatabasesPath();
      await _downloadFromGoogleDrive(
          databaseFileId, 'opencloudhealth.db', dbPath);
      await ref.read(profilesProvider.notifier).loadProfiles();
    }
  }
}
