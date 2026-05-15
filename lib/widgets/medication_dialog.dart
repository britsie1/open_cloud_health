import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';
import 'package:open_cloud_health/utils/result.dart';
import 'package:permission_handler/permission_handler.dart';

class MedicationDialog extends ConsumerStatefulWidget {
  const MedicationDialog({
    super.key,
    required this.profileId,
    this.medication,
  });

  final String profileId;
  final Medication? medication;

  @override
  ConsumerState<MedicationDialog> createState() => _MedicationDialogState();
}

class _MedicationDialogState extends ConsumerState<MedicationDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late TimeOfDay _selectedTime;
  late String _selectedType;
  late bool _notificationEnabled;
  late bool _alarmEnabled;

  static const List<String> _medicationTypes = [
    'Tablet',
    'Liquid',
    'Capsule',
    'Injection',
    'Drops',
    'Inhaler',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication?.name ?? '');
    _dosageController =
        TextEditingController(text: widget.medication?.dosage ?? '');
    _selectedTime = widget.medication?.timeOfDay ?? TimeOfDay.now();
    _selectedType = widget.medication?.type ?? 'Tablet';
    _notificationEnabled = widget.medication?.notificationEnabled ?? false;
    _alarmEnabled = widget.medication?.alarmEnabled ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _dosageController.text.trim().isEmpty) {
      return;
    }

    Result<void, Exception> result;

    if (widget.medication == null) {
      final newMed = Medication(
        profileId: widget.profileId,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        type: _selectedType,
        notificationEnabled: _notificationEnabled,
        alarmEnabled: _alarmEnabled,
        timeOfDay: _selectedTime,
      );

      result = await ref
          .read(medicationsProvider(widget.profileId).notifier)
          .addMedication(newMed);
    } else {
      final updatedMed = Medication(
        id: widget.medication!.id,
        profileId: widget.medication!.profileId,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        type: _selectedType,
        notificationEnabled: _notificationEnabled,
        alarmEnabled: _alarmEnabled,
        timeOfDay: _selectedTime,
        isActive: widget.medication!.isActive,
      );

      result = await ref
          .read(medicationsProvider(widget.profileId).notifier)
          .updateMedication(updatedMed);
    }

    if (!mounted) return;
    context.pop();

    if (result is Failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to save medication: ${result.exception}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.medication == null ? 'Add Medication' : 'Edit Medication'),
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
              decoration:
                  const InputDecoration(labelText: 'Dosage (e.g., 200mg)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: _medicationTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
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
            SwitchListTile(
              title: const Text('Enable Notification'),
              contentPadding: EdgeInsets.zero,
              value: _notificationEnabled,
              onChanged: (val) async {
                if (val) {
                  bool hasPermission = true;
                  final status = await Permission.notification.request();
                  hasPermission = status.isGranted;

                  if (!hasPermission) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifications permission is required.'),
                        ),
                      );
                    }
                    return;
                  }
                }
                
                setState(() {
                  _notificationEnabled = val;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Set System Alarm'),
              contentPadding: EdgeInsets.zero,
              value: _alarmEnabled,
              onChanged: (val) async {
                if (val) {
                  if (Platform.isAndroid) {
                    // Request schedule exact alarm permission for Android 12+
                    // SET_ALARM is a normal permission and granted automatically,
                    // but newer Android versions may require exact alarm permission.
                    final status = await Permission.scheduleExactAlarm.request();
                    if (!status.isGranted) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Exact alarm permission is required to set alarms.'),
                          ),
                        );
                      }
                      return;
                    }
                  } else if (Platform.isIOS) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('System alarms are not supported on iOS.'),
                        ),
                      );
                    }
                    return;
                  }
                }
                
                setState(() {
                  _alarmEnabled = val;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.medication == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
