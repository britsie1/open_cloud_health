import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/providers/checkups_provider.dart';
import 'package:open_cloud_health/utils/icon_utils.dart';
import 'package:open_cloud_health/utils/result.dart';

class LogCheckupDialog extends ConsumerStatefulWidget {
  const LogCheckupDialog({
    super.key,
    required this.profileId,
    required this.checkupId,
    required this.checkupName,
  });

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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Checkup'),
        content: const Text(
            'Are you sure you want to delete this checkup? This will also delete all its logs. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close confirm dialog
              setState(() {
                _isLoading = true;
              });
              final result = await ref
                  .read(checkupsProvider(widget.profileId).notifier)
                  .deleteCheckup(widget.checkupId);
              if (!mounted) return;
              if (result is Success) {
                Navigator.of(context).pop(); // Close log dialog
              } else {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We need to find the checkup icon from the provider
    final checkupsAsync = ref.watch(checkupsProvider(widget.profileId));
    final checkup = checkupsAsync.maybeWhen(
      data: (data) => data.firstWhere((c) => c.checkup.id == widget.checkupId),
      orElse: () => null,
    );

    return AlertDialog(
      title: Row(
        children: [
          if (checkup != null) ...[
            getCheckupIconWidget(
              checkup.checkup.iconName,
              checkupName: widget.checkupName,
              color: Colors.blue,
              size: 32,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              widget.checkupName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('When did you complete this checkup?'),
          const SizedBox(height: 16),
          InkWell(
            onTap: _presentDatePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _selectedDate == null
                          ? Colors.grey.shade600
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            IconButton(
              onPressed: _isLoading ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              tooltip: 'Delete Checkup',
            ),
            const Spacer(),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitLog,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
