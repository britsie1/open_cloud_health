import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/providers/checkups_provider.dart';
import 'package:open_cloud_health/utils/result.dart';

class LogCheckupDialog extends ConsumerStatefulWidget {
  const LogCheckupDialog({super.key, required this.profileId, required this.checkupId, required this.checkupName});

  final String profileId;
  final String checkupId;
  final String checkupName;

  @override
  ConsumerState<LogCheckupDialog> createState() => _LogCheckupDialogState();
}

class _LogCheckupDialogState extends ConsumerState<LogCheckupDialog> {
  DateTime? _selectedDate;
  bool _isLoading = false;

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: now,
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitLog() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ref
        .read(checkupsProvider(widget.profileId).notifier)
        .logCheckup(widget.checkupId, _selectedDate!);

    if (!mounted) return;

    if (result is Success) {
      Navigator.of(context).pop();
    } else if (result is Failure) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result.exception}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log ${widget.checkupName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('When did you complete this checkup?'),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                _selectedDate == null
                    ? 'No date selected'
                    : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
              ),
              const Spacer(),
              IconButton(
                onPressed: _presentDatePicker,
                icon: const Icon(Icons.calendar_month),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitLog,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}
