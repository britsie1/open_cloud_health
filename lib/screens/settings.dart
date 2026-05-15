import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late double databaseSize = 0;
  late double documentsFileSize = 0;
  String lastBackupDateTime = 'Not connected';
  bool isConnectedToGoogle = false;

  @override
  void initState() {
    super.initState();

    ref
        .read(databaseHelperProvider)
        .getDatabaseSize()
        .then((value) => {setState(() => databaseSize = value / 1024)});

    getApplicationDocumentsDirectory().then((appDir) {
      var files = appDir.listSync(recursive: true);
      var size = 0;

      if (files.isNotEmpty) {
        size = files
            .where((file) => basename(file.path) != 'opencloudhealth.db')
            .map((file) {
          if (file is File) {
            return File(file.path).lengthSync();
          }

          return 0;
        }).reduce((value, element) => value + element);
      }

      setState(() {
        documentsFileSize = size / 1024;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Future<void> connectToGoogle() async {
      setState(() {
        lastBackupDateTime = 'Connecting...';
      });
      final value =
          await ref.read(backupServiceProvider).getLastBackupDateTime();
      if (value.isEmpty || value == 'Error') {
        setState(() {
          lastBackupDateTime = 'Not connected';
          isConnectedToGoogle = false;
        });
      } else {
        setState(() {
          isConnectedToGoogle = true;
          lastBackupDateTime = value == 'Never' ? value : '$value UTC';
        });
      }
    }

    Future<void> resetDB() async {
      await ref.read(databaseHelperProvider).resetDatabase();

      Directory dir = await getTemporaryDirectory();
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
        dir.create();
      }

      if (!context.mounted) {
        return;
      }

      context.go(AppRoutes.auth);
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

        await ref.read(backupServiceProvider).backupToGoogleDrive();

        setState(() {
          lastBackupDateTime =
              '${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())} UTC';
        });
      } finally {
        if (context.mounted) {
          context.pop();
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
            if (!isConnectedToGoogle)
              ElevatedButton(
                onPressed: connectToGoogle,
                child: const Text('Connect to Google Drive'),
              )
            else ...[
              ElevatedButton(
                  onPressed: uploadBackup,
                  child: const Text('Backup to Google Drive')),
              Text('Last backup: $lastBackupDateTime'),
            ],
            ElevatedButton(
              onPressed: resetDB,
              child: const Text('Reset Database'),
            ),
            Text('Database Size: ${databaseSize}kb'),
            Text(
                'App Documents Size: ${documentsFileSize.toStringAsFixed(2)}kb'),
          ],
        ),
      ),
    );
  }
}
