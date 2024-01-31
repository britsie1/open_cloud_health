import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/storage/google_auth_client.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

final googleSignIn = GoogleSignIn.standard(scopes: [
  drive.DriveApi.driveAppdataScope,
]);

Future<drive.DriveApi?> _getDriveApi() async {
  final googleUser = await googleSignIn.signIn();
  final headers = await googleUser?.authHeaders;
  if (headers == null) {
    return null;
  }

  final client = GoogleAuthClient(headers);
  final driveApi = drive.DriveApi(client);
  return driveApi;
}

Future<String> backupToGoogleDrive() async {
  try {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      return 'Error';
    }

    final dbPath = await sql.getDatabasesPath();
    final dbFilePath = path.join(dbPath, 'opencloudhealth.db');

    final dbFile = File(dbFilePath);
    final Stream<List<int>> mediaStream = dbFile.openRead().asBroadcastStream();
    var media = drive.Media(mediaStream, dbFile.lengthSync());

    var driveFile = drive.File();
    driveFile.name = "opencloudhealth.db";
    driveFile.modifiedTime = DateTime.now().toUtc();
    driveFile.parents = ["appDataFolder"];

    //get existing backup file to delete after new backup has been created.
    String? databaseFileId;
    final fileList = await driveApi.files
        .list(spaces: 'appDataFolder', $fields: 'files(id, name)');

    if (fileList.files != null) {
      final databaseFile = fileList.files!
          .where((file) => file.name == 'opencloudhealth.db')
          .firstOrNull;
      if (databaseFile != null) {
        databaseFileId = databaseFile.id;
      }
    }

    //create the backup file
    await driveApi.files.create(driveFile, uploadMedia: media);

    if (databaseFileId != null) {
      driveApi.files.delete(databaseFileId);
    }

    return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  } on PlatformException catch (exception) {
    return exception.message ?? 'Error';
  }
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

Future<void> restoreFromBackup(WidgetRef ref) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      return;
    }

    String? databaseFileId;
    final fileList = await driveApi.files
        .list(spaces: 'appDataFolder', $fields: 'files(id, name)');

    if (fileList.files != null) {
      final databaseFile = fileList.files!
          .where((file) => file.name == 'opencloudhealth.db')
          .firstOrNull;
      if (databaseFile != null) {
        databaseFileId = databaseFile.id;
      }
    }

    if (databaseFileId != null) {
      List<int> dataStore = [];
      drive.Media media = await driveApi.files.get(databaseFileId,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      media.stream.listen((data) {
        dataStore.insertAll(dataStore.length, data);
      }, onDone: () async {
        final dbPath = await sql.getDatabasesPath();
        final dbFilePath = path.join(dbPath, 'opencloudhealth.db');
        final fileLocation = await File(dbFilePath).create();
        await fileLocation.writeAsBytes(dataStore);
        await ref.read(profilesProvider.notifier).loadProfiles();
      }, onError: (error) {
        print("Some Error");
      });
    }
  }