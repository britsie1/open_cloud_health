import 'package:flutter/material.dart';
import 'package:open_cloud_health/pages/drawer.dart';
import 'package:open_cloud_health/pages/shared_app_bar.dart';

class MedicalInformationPage extends StatefulWidget {
  const MedicalInformationPage({super.key});

  @override
  State<MedicalInformationPage> createState() => _MedicalInformationPageState();
}

class _MedicalInformationPageState extends State<MedicalInformationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerPage(),
      appBar: const SharedAppBar(),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate back to first route when tapped.
          },
          child: const Text('Go back!'),
        ),
      ),
    );
  }
}