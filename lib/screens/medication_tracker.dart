import 'package:flutter/material.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';
import 'package:open_cloud_health/widgets/main_drawer.dart';

class MedicationTrackerScreen extends StatefulWidget {
  const MedicationTrackerScreen({super.key, required this.profileId});

  final String profileId;

  @override
  State<MedicationTrackerScreen> createState() =>
      _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends State<MedicationTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [AccountAppBarActions()],
        title: const Text('Medication Tracker'),
      ),
      drawer: MainDrawer(profileId: widget.profileId, currentRouteName: 'medication_tracker'),
      body: const Center(
        child: Text('Medication tracker screen'),
      ),
    );
  }
}
