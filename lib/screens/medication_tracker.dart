import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';
import 'package:open_cloud_health/widgets/medication_all_tab.dart';
import 'package:open_cloud_health/widgets/medication_dialog.dart';
import 'package:open_cloud_health/widgets/medication_log_tab.dart';
import 'package:open_cloud_health/widgets/medication_today_tab.dart';

class MedicationTrackerScreen extends ConsumerStatefulWidget {
  const MedicationTrackerScreen({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<MedicationTrackerScreen> createState() =>
      _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState
    extends ConsumerState<MedicationTrackerScreen> {
  void _openAddMedicationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => MedicationDialog(profileId: widget.profileId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          actions: const [AccountAppBarActions()],
          title: const Text('Medication Tracker'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.today), text: 'Today'),
              Tab(icon: Icon(Icons.list), text: 'All Medications'),
              Tab(icon: Icon(Icons.history), text: 'Log'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MedicationTodayTab(profileId: widget.profileId),
            MedicationAllTab(profileId: widget.profileId),
            MedicationLogTab(profileId: widget.profileId),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddMedicationDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
