import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/providers/checkups_provider.dart';
import 'package:open_cloud_health/repositories/checkups_repository.dart';
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

  final _doctorController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  List<String> _doctorSuggestions = [];
  List<String> _locationSuggestions = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadSuggestions() async {
    try {
      final repo = ref.read(checkupsRepositoryProvider);
      final logs = await repo.loadAllLogsForProfile(widget.profileId);
      final doctors = logs
          .map((l) => l.doctorName)
          .whereType<String>()
          .where((d) => d.trim().isNotEmpty)
          .toSet()
          .toList();
      final locations = logs
          .map((l) => l.location)
          .whereType<String>()
          .where((loc) => loc.trim().isNotEmpty)
          .toSet()
          .toList();
      if (mounted) {
        setState(() {
          _doctorSuggestions = doctors;
          _locationSuggestions = locations;
        });
      }
    } catch (_) {
      // Ignore silently
    }
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
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
        .logCheckup(
          widget.checkupId,
          _selectedDate!,
          doctorName: _doctorController.text.trim().isEmpty
              ? null
              : _doctorController.text.trim(),
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

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
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'When did you complete this checkup?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 16),
              const Text(
                'Doctor / Healthcare Provider',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _doctorSuggestions.where((String option) {
                    return option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _doctorController.text = selection;
                },
                fieldViewBuilder:
                    (context, textController, focusNode, onFieldSubmitted) {
                  if (_doctorController.text != textController.text) {
                    textController.text = _doctorController.text;
                  }
                  textController.addListener(() {
                    _doctorController.text = textController.text;
                  });
                  return TextField(
                    controller: textController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.person_outline, color: Colors.blue),
                      hintText: "Enter doctor's name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Facility / Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _locationSuggestions.where((String option) {
                    return option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _locationController.text = selection;
                },
                fieldViewBuilder:
                    (context, textController, focusNode, onFieldSubmitted) {
                  if (_locationController.text != textController.text) {
                    textController.text = _locationController.text;
                  }
                  textController.addListener(() {
                    _locationController.text = textController.text;
                  });
                  return TextField(
                    controller: textController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.local_hospital_outlined,
                          color: Colors.blue),
                      hintText: 'Enter place or clinic',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Notes (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add notes about your checkup...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
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
    );
  }
}
