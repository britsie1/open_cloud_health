import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/screens/auth.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_cloud_health/storage/google_drive_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double databaseSize = 0;
  late double documentsFileSize = 0;
  String lastBackupDateTime = 'Loading...';

  @override
  void initState() {
    super.initState();

    getLastBackupDateTime().then(
      (value) {
        setState(() {
          lastBackupDateTime = '$value UTC';
        });
      },
    );

    getDatabaseSize()
        .then((value) => {setState(() => databaseSize = value / 1024)});

    getApplicationDocumentsDirectory().then((appDir) {
      var files = appDir.listSync();
      var size = files
          .where((file) => basename(file.path) != 'opencloudhealth.db')
          .map((file) {
        if (file is File) {
          return File(file.path).lengthSync();
        }

        return 0;
      }).reduce((value, element) => value + element);

      setState(() {
        documentsFileSize = size / 1024;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Future<void> resetDB() async {
      await resetDatabase();

      Directory dir = await getTemporaryDirectory();
      dir.deleteSync(recursive: true);
      dir.create();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => const AuthScreen(),
        ),
      );
    }

    Future<void> uploadBackup() async {
      try {
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          transitionDuration: const Duration(seconds: 1),
          barrierColor: Colors.black.withOpacity(0.5),
          pageBuilder: (context, animation, secondaryAnimation) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        await backupToGoogleDrive();

        setState(() {
          lastBackupDateTime =
              '${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())} UTC';
        });
      } finally {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
                onPressed: uploadBackup,
                child: const Text('Backup to Google Drive')),
            ElevatedButton(
              onPressed: resetDB,
              child: const Text('Reset Database'),
            ),
            Text('Database Size: ${databaseSize}kb'),
            Text('App Documents Size: ${documentsFileSize.toStringAsFixed(2)}kb'),
            Text('Last backup: $lastBackupDateTime'),
          ],
        ),
      ),
    );
  }
}
