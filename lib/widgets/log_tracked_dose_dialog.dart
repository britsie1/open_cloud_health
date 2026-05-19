import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';
import 'package:open_cloud_health/utils/result.dart';

class LogTrackedDoseDialog extends ConsumerStatefulWidget {
  final String profileId;
  final Medication medication;

  const LogTrackedDoseDialog({
    super.key,
    required this.profileId,
    required this.medication,
  });

  @override
  ConsumerState<LogTrackedDoseDialog> createState() => _LogTrackedDoseDialogState();
}

class _LogTrackedDoseDialogState extends ConsumerState<LogTrackedDoseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dosageController;
  late DateTime _selectedTime;

  @override
  void initState() {
    super.initState();
    _dosageController = TextEditingController(text: widget.medication.dosage);
    _selectedTime = DateTime.now();
  }

  @override
  void dispose() {
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );
    if (time != null) {
      setState(() {
        final now = DateTime.now();
        _selectedTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dosage = _dosageController.text.trim();
    final log = MedicationLog(
      medicationId: widget.medication.id,
      timestamp: _selectedTime,
      isTaken: true,
      dosage: dosage,
    );

    final result = await ref
        .read(medicationLogsProvider(widget.profileId).notifier)
        .addLog(log);

    if (!mounted) return;

    if (result is Success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged dose for ${widget.medication.name} ($dosage)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (result is Failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log dose: ${result.exception}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.medication, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Log Medication Dose'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.medication.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: 'Logged Dosage',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.scale),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter dosage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Time Taken'),
                subtitle: Text(
                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: TextButton(
                  onPressed: _selectTime,
                  child: const Text('Change'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Log Dose'),
        ),
      ],
    );
  }
}
