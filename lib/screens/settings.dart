import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
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
            ElevatedButton.icon(
              onPressed: () {
                context.push(AppRoutes.securitySetup);
              },
              icon: const Icon(Icons.security),
              label: const Text('App Lock & Security'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final lastProfileId = await ref.read(secureStorageProvider).getLastProfileId();
                final profiles = ref.read(profilesProvider).value ?? [];
                if (profiles.isNotEmpty) {
                  final activeProfileId = lastProfileId ?? profiles.first.id;
                  if (context.mounted) {
                    context.push('${AppRoutes.emergencySettings}/$activeProfileId');
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please create a profile first.')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.emergency, color: Colors.red),
              label: const Text('Emergency Lock Screen Info'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.red.shade900,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: resetDB,
              child: const Text('Reset Database'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Row(
                      children: [
                        Icon(Icons.privacy_tip_outlined, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Privacy & Disclaimer'),
                      ],
                    ),
                    content: const SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medical Disclaimer',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Open Cloud Health is an informational logbook application for tracking personal medical histories, medication times, checkup schedules, and cycles. It does not provide professional medical advice, diagnosis, or treatment. Always consult a qualified physician or healthcare provider with any questions you have regarding a medical condition or treatment.',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Privacy Policy',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Local Storage: All medical histories, symptoms, medication logs, and biometrics are stored strictly on your local device. The developer has zero access to your information.\n\n'
                            '• Cloud Backup: If you manually connect Google Drive, the database and attachments are stored directly in your personal Google Drive\'s secure App Data folder, accessible only by you. No data is shared with or sold to third parties.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('Privacy & Disclaimers'),
            ),
            const SizedBox(height: 16),
            Text('Database Size: ${databaseSize}kb'),
            Text(
                'App Documents Size: ${documentsFileSize.toStringAsFixed(2)}kb'),
          ],
        ),
      ),
    );
  }
}
