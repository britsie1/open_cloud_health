import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_datetime_picker/flutter_cupertino_datetime_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/attachment.dart';
import 'package:open_cloud_health/models/history_event.dart' as history;
import 'package:open_cloud_health/providers/attachment_provider.dart';
import 'package:open_cloud_health/providers/history_provider.dart';
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
  final _selectedDateController = TextEditingController();
  late var _enteredTitle = '';
  var _enteredDescription = '';
  List<Attachment> selectedFiles = [];

  @override
  void dispose() {
    _selectedDateController.dispose();
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
      _enteredTitle = widget.historyEvent!.title;
      _enteredDescription = widget.historyEvent!.description;
      _selectedDateController.text = widget.historyEvent!.formattedDate;

      fetchAttachments(widget.historyEvent!.id).then((value) {
        setState(() {
          selectedFiles = value;
        });
      });
    }
  }

  void _attachFiles() async {
    await [Permission.photos, Permission.videos, Permission.audio].request();

    //TODO: show snackbar if permission is not granted.

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

      //TODO: remove attachments with the same name

      setState(() {
        selectedFiles.addAll(newFiles);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    void saveEvent() async {
      final isValid = _form.currentState!.validate();
      if (!isValid) {
        return;
      }
      _form.currentState!.save();

      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);

      final result = await ref
          .read(historyProvider(widget.profileId).notifier)
          .saveEventWithAttachments(
            id: widget.historyEvent?.id,
            profileId: widget.profileId,
            title: _enteredTitle,
            description: _enteredDescription,
            date: DateTime.parse(_selectedDateController.text),
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
        title: Text(widget.historyEvent == null ? 'New Event' : 'Edit Event'),
        actions: [
          if (widget.historyEvent != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
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
                            foregroundColor: Colors.white),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _form,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: _enteredTitle,
                      decoration: const InputDecoration(labelText: 'Title'),
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
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Event Date'),
                      readOnly: true,
                      controller: _selectedDateController,
                      onTap: () {
                        DatePicker.showDatePicker(
                          context,
                          dateFormat: 'yyyy-MMM-dd HH:mm',
                          maxDateTime: DateTime.now(),
                          initialDateTime: _selectedDateController.text.isEmpty
                              ? DateTime.now()
                              : DateTime.parse(_selectedDateController.text),
                          onConfirm: (dateTime, selectedIndex) {
                            _selectedDateController.text =
                                history.formatter.format(dateTime);
                          },
                        );
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please select a date for the event';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      initialValue: _enteredDescription,
                      maxLines: 5,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                          labelText: 'Description', alignLabelWithHint: true),
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
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton.icon(
                      onPressed: _attachFiles,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Attach Files'),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Attachments',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.left,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (selectedFiles.isEmpty)
              const SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text('There are no attachments for this event.'),
                ),
              ),
            if (selectedFiles.isNotEmpty)
              Column(
                children: selectedFiles.map((item) {
                  return AttachmentItem(
                      attachment: item, onRemoveAttachment: removeAttachment);
                }).toList(),
              )
          ],
        ),
      ),
    );
  }
}
