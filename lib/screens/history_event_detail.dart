import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/models/attachment.dart';
import 'package:open_cloud_health/models/history_event.dart' as history;
import 'package:open_cloud_health/providers/attachment_provider.dart';
import 'package:open_cloud_health/providers/history_provider.dart';
import 'package:open_cloud_health/utils/icon_utils.dart';
import 'package:open_cloud_health/utils/result.dart';
import 'package:open_cloud_health/widgets/attachment_item.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

class HistoryEventDetailScreen extends ConsumerStatefulWidget {
  const HistoryEventDetailScreen(
      {super.key, required this.profileId, this.historyEvent});
  final String profileId;
  final history.HistoryEvent? historyEvent;

  @override
  ConsumerState<HistoryEventDetailScreen> createState() =>
      _HistoryEventDetailScreenState();
}

class _HistoryEventDetailScreenState
    extends ConsumerState<HistoryEventDetailScreen> {
  final _form = GlobalKey<FormState>();
  late String _enteredTitle = '';
  late String _enteredDescription = '';
  late history.EventType _selectedEventType;
  late bool _hasTime;
  late DateTime _selectedDate;
  late TimeOfDay? _selectedTime;
  
  final _providerController = TextEditingController();
  final _facilityController = TextEditingController();
  List<Attachment> selectedFiles = [];

  @override
  void dispose() {
    _providerController.dispose();
    _facilityController.dispose();
    super.dispose();
  }

  Future<List<Attachment>> fetchAttachments(String historyId) async {
    return await ref
        .read(attachmentProvider.notifier)
        .getAttachments(historyId);
  }

  @override
  void initState() {
    super.initState();

    if (widget.historyEvent != null) {
      final ev = widget.historyEvent!;
      _enteredTitle = ev.title;
      _enteredDescription = ev.description;
      _selectedEventType = ev.eventType;
      _hasTime = ev.hasTime;
      _selectedDate = ev.date;
      _selectedTime = ev.hasTime ? TimeOfDay.fromDateTime(ev.date) : null;
      _providerController.text = ev.provider ?? '';
      _facilityController.text = ev.facility ?? '';

      fetchAttachments(ev.id).then((value) {
        setState(() {
          selectedFiles = value;
        });
      });
    } else {
      _selectedEventType = history.EventType.other;
      _hasTime = true;
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  void _attachFiles() async {
    await [Permission.photos, Permission.videos, Permission.audio].request();

    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      final newFiles = result.paths
          .map(
            (path) => Attachment(
                historyId:
                    widget.historyEvent != null ? widget.historyEvent!.id : '',
                filename: basename(path!),
                uploadDate: DateTime.now(),
                byteLength: File(path).readAsBytesSync().length,
                tempPath: path),
          )
          .toList();

      setState(() {
        selectedFiles.addAll(newFiles);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter out period and checkup as they are auto-logged, not manually selectable
    final allowedEventTypes = history.EventType.values
        .where((type) =>
            type != history.EventType.period &&
            type != history.EventType.checkup)
        .toList();

    void saveEvent() async {
      final isValid = _form.currentState!.validate();
      if (!isValid) {
        return;
      }
      _form.currentState!.save();

      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);

      DateTime finalDateTime;
      if (_hasTime) {
        finalDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime?.hour ?? 0,
          _selectedTime?.minute ?? 0,
        );
      } else {
        finalDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
      }

      final result = await ref
          .read(historyProvider(widget.profileId).notifier)
          .saveEventWithAttachments(
            id: widget.historyEvent?.id,
            profileId: widget.profileId,
            title: _enteredTitle,
            description: _enteredDescription,
            date: finalDateTime,
            eventType: _selectedEventType,
            hasTime: _hasTime,
            provider: _providerController.text.trim().isEmpty
                ? null
                : _providerController.text.trim(),
            facility: _facilityController.text.trim().isEmpty
                ? null
                : _facilityController.text.trim(),
            attachments: selectedFiles,
          );

      if (!mounted) return;

      if (result is Success<String, Exception>) {
        router.pop();
      } else if (result is Failure<String, Exception>) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to save event: ${result.exception}')),
        );
      }
    }

    void removeAttachment(Attachment attachment) {
      setState(() {
        selectedFiles.remove(attachment);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.historyEvent == null ? 'Create Medical Event' : 'Edit Medical Event'),
        elevation: 0,
        actions: [
          if (widget.historyEvent != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Delete Event'),
                    content:
                        const Text('Are you sure you want to delete this event?'),
                    actions: [
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            )),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final router = GoRouter.of(context);

                          final result = await ref
                              .read(historyProvider(widget.profileId).notifier)
                              .deleteEvent(widget.historyEvent!.id);
                          
                          if (!mounted) return;
                          
                          router.pop(); // Close dialog

                          if (result is Success<void, Exception>) {
                            router.pop(); // Close detail screen
                          } else if (result is Failure<void, Exception>) {
                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Failed to delete event: ${result.exception}')),
                            );
                          }
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            onPressed: saveEvent,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event details card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Event Details',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                        const SizedBox(height: 16),
                        // Event Type Dropdown
                        DropdownButtonFormField<history.EventType>(
                          value: _selectedEventType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Event Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: getHistoryEventIcon(
                                  _selectedEventType,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                          items: allowedEventTypes.map((type) {
                            return DropdownMenuItem<history.EventType>(
                              value: type,
                              child: Text(type.displayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedEventType = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select an event type';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Title
                        TextFormField(
                          initialValue: _enteredTitle,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            hintText: 'e.g. Annual Blood Panel, Knee Surgery',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.title),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an event title';
                            }
                            return null;
                          },
                          onSaved: (newValue) {
                            _enteredTitle = newValue!;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Include Time toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Include Time'),
                          subtitle: const Text('Specify the exact time of the event'),
                          value: _hasTime,
                          onChanged: (val) {
                            setState(() {
                              _hasTime = val;
                              if (val && _selectedTime == null) {
                                _selectedTime = TimeOfDay.now();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        // Date & Time pickers
                        InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _selectedDate = pickedDate;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              DateFormat('yyyy-MM-dd').format(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        if (_hasTime) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime ?? TimeOfDay.now(),
                              );
                              if (pickedTime != null) {
                                setState(() {
                                  _selectedTime = pickedTime;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Time',
                                prefixIcon: const Icon(Icons.access_time),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _selectedTime != null
                                    ? _selectedTime!.format(context)
                                    : 'Select Time',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Provider & Facility Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Care Provider & Facility',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                        const SizedBox(height: 16),
                        // Healthcare Provider
                        TextFormField(
                          controller: _providerController,
                          decoration: InputDecoration(
                            labelText: 'Healthcare Provider',
                            hintText: 'e.g. Dr. Jane Smith, Therapist',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Facility / Clinic
                        TextFormField(
                          controller: _facilityController,
                          decoration: InputDecoration(
                            labelText: 'Facility / Clinic',
                            hintText: 'e.g. City General Hospital, Dental Care',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.local_hospital_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Description Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Additional Notes',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _enteredDescription,
                          maxLines: 4,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Detail the diagnosis, findings, or instructions...',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.notes),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an event description';
                            }
                            return null;
                          },
                          onSaved: (newValue) {
                            _enteredDescription = newValue!;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Attachments Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Attachments',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed: _attachFiles,
                              icon: const Icon(Icons.add_photo_alternate_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (selectedFiles.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Text(
                                'No attachments for this event.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        if (selectedFiles.isNotEmpty)
                          Column(
                            children: selectedFiles.map((item) {
                              return AttachmentItem(
                                attachment: item,
                                onRemoveAttachment: removeAttachment,
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
