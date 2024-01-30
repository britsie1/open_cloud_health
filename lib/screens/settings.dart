import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/screens/auth.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double databaseSize = 0;

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

  @override
  void initState() {
    super.initState();

    getDatabaseSize().then((value) => { setState(() => databaseSize = value / 1024) });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: resetDB,
              child: const Text('Reset Database'),
            ),
            Text('Database Size: ${databaseSize}kb')
          ],
        ),
      ),
    );
  }
}
