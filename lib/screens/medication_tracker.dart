import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';
import 'package:open_cloud_health/widgets/main_drawer.dart';

class MedicationTrackerScreen extends ConsumerStatefulWidget {
  const MedicationTrackerScreen({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<MedicationTrackerScreen> createState() => _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends ConsumerState<MedicationTrackerScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _openAddMedicationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddMedicationDialog(profileId: widget.profileId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          actions: const [AccountAppBarActions()],
          title: const Text('Medication Tracker'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.today), text: 'Today'),
              Tab(icon: Icon(Icons.list), text: 'All Medications'),
            ],
          ),
        ),
        drawer: MainDrawer(
            profileId: widget.profileId,
            currentRouteName: 'medication_tracker'),
        body: TabBarView(
          children: [
            _TodayTab(profileId: widget.profileId),
            _AllMedicationsTab(profileId: widget.profileId),
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

class _TodayTab extends ConsumerWidget {
  const _TodayTab({required this.profileId});
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsProvider(profileId));
    final logsAsync = ref.watch(medicationLogsProvider(profileId));

    return medicationsAsync.when(
      data: (medications) {
        final activeMedications =
            medications.where((m) => m.isActive).toList();
        if (activeMedications.isEmpty) {
          return const Center(child: Text("No active medications for today."));
        }

        return logsAsync.when(
          data: (logs) {
            return ListView.builder(
              itemCount: activeMedications.length,
              itemBuilder: (ctx, index) {
                final med = activeMedications[index];
                final isTaken = logs.any((log) => log.medicationId == med.id);

                return CheckboxListTile(
                  title: Text(med.name),
                  subtitle: Text('${med.dosage} at ${med.timeFormatted}'),
                  value: isTaken,
                  onChanged: (val) {
                    if (val == true) {
                      ref.read(medicationLogsProvider(profileId).notifier).addLog(
                            MedicationLog(
                              medicationId: med.id,
                              timestamp: DateTime.now(),
                            ),
                          );
                    } else if (val == false) {
                      ref.read(medicationLogsProvider(profileId).notifier).removeLog(
                            med.id,
                            DateTime.now(),
                          );
                    }
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _AllMedicationsTab extends ConsumerWidget {
  const _AllMedicationsTab({required this.profileId});
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsProvider(profileId));

    return medicationsAsync.when(
      data: (medications) {
        if (medications.isEmpty) {
          return const Center(child: Text("No medications added yet."));
        }

        return ListView.builder(
          itemCount: medications.length,
          itemBuilder: (ctx, index) {
            final med = medications[index];
            return ListTile(
              title: Text(med.name),
              subtitle: Text('${med.dosage} - ${med.timeFormatted}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: med.isActive,
                    onChanged: (val) {
                      ref
                          .read(medicationsProvider(profileId).notifier)
                          .toggleIsActive(med);
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        showDialog(
                          context: context,
                          builder: (ctx) =>
                              _EditMedicationDialog(medication: med),
                        );
                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Medication'),
                            content: const Text(
                                'Are you sure you want to delete this medication? This will also remove its daily logs.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white),
                                onPressed: () {
                                  ref
                                      .read(medicationsProvider(profileId)
                                          .notifier)
                                      .deleteMedication(med.id);
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _AddMedicationDialog extends ConsumerStatefulWidget {
  const _AddMedicationDialog({required this.profileId});
  final String profileId;

  @override
  ConsumerState<_AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends ConsumerState<_AddMedicationDialog> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty || _dosageController.text.trim().isEmpty) {
      return;
    }

    final newMed = Medication(
      profileId: widget.profileId,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      timeOfDay: _selectedTime,
    );

    ref
        .read(medicationsProvider(widget.profileId).notifier)
        .addMedication(newMed);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Medication'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Medication Name'),
            ),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: 'Dosage (e.g., 200mg)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Time: ${_selectedTime.format(context)}'),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        _selectedTime = time;
                      });
                    }
                  },
                  child: const Text('Select Time'),
                )
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _EditMedicationDialog extends ConsumerStatefulWidget {
  const _EditMedicationDialog({required this.medication});
  final Medication medication;

  @override
  ConsumerState<_EditMedicationDialog> createState() => _EditMedicationDialogState();
}

class _EditMedicationDialogState extends ConsumerState<_EditMedicationDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication.name);
    _dosageController = TextEditingController(text: widget.medication.dosage);
    _selectedTime = widget.medication.timeOfDay;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty || _dosageController.text.trim().isEmpty) {
      return;
    }

    final updatedMed = Medication(
      id: widget.medication.id,
      profileId: widget.medication.profileId,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      timeOfDay: _selectedTime,
      isActive: widget.medication.isActive,
    );

    ref
        .read(medicationsProvider(widget.medication.profileId).notifier)
        .updateMedication(updatedMed);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Medication'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Medication Name'),
            ),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: 'Dosage (e.g., 200mg)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Time: ${_selectedTime.format(context)}'),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        _selectedTime = time;
                      });
                    }
                  },
                  child: const Text('Select Time'),
                )
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
