import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_datetime_picker/flutter_cupertino_datetime_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/attachment.dart' as attachment;
import 'package:open_cloud_health/models/attachment.dart';
import 'package:open_cloud_health/models/history_event.dart' as history;
import 'package:open_cloud_health/providers/attachment_provider.dart';
import 'package:open_cloud_health/providers/history_provider.dart';
import 'package:open_cloud_health/widgets/attachment_item.dart';
import 'package:path/path.dart';

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
    }

    fetchAttachments(widget.historyEvent!.id).then((value) {
      setState(() {
        selectedFiles = value;
      });
    });
  }

  void _attachFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      final newFiles = result.paths
          .map(
            (path) => attachment.Attachment(
              historyId:
                  widget.historyEvent != null ? widget.historyEvent!.id : '',
              filename: basename(path!),
              uploadDate: DateTime.now(),
              content: File(path).readAsBytesSync(),
            ),
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
      if (widget.historyEvent == null) {
        var historyId = await ref.read(historyProvider.notifier).addEvent(
            widget.profileId,
            _enteredTitle,
            _enteredDescription,
            DateTime.parse(_selectedDateController.text));

        //update the historyId
        selectedFiles = selectedFiles
            .map((attachment) => Attachment(
                id: attachment.id,
                historyId: historyId,
                filename: attachment.filename,
                uploadDate: attachment.uploadDate,
                content: attachment.content))
            .toList();

        ref.read(attachmentProvider.notifier).addAttachments(selectedFiles);
      } else {
        await ref.read(historyProvider.notifier).updateEvent(
            history.HistoryEvent(
                id: widget.historyEvent!.id,
                profileId: widget.historyEvent!.profileId,
                title: _enteredTitle,
                description: _enteredDescription,
                date: DateTime.parse(_selectedDateController.text)));

        //get all missing attachments and delete them
        var dbAttachments = await fetchAttachments(widget.historyEvent!.id);
        var attachmentsToRemove = dbAttachments.where((attachment) =>
            selectedFiles.where((file) => file.id == attachment.id).isEmpty);
        var attachmentsToAdd = selectedFiles.where((file) => dbAttachments
            .where((attachment) => attachment.id == file.id)
            .isEmpty);

        if (attachmentsToRemove.isNotEmpty) {
          ref
              .read(attachmentProvider.notifier)
              .removeAttachments(attachmentsToRemove);
        }

        if (attachmentsToAdd.isNotEmpty) {
          ref
              .read(attachmentProvider.notifier)
              .addAttachments(attachmentsToAdd);
        }
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    }

    void removeAttachment(attachment.Attachment attachment) {
      final attachmentIndex = selectedFiles.indexOf(attachment);
      setState(() {
        selectedFiles.remove(attachment);
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: const Text('Attachment deleted'),
          action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  selectedFiles.insert(attachmentIndex, attachment);
                });
              }),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.historyEvent == null ? 'New Event' : 'Edit Event'),
        actions: [
          IconButton(
            onPressed: saveEvent,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Column(
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
                    decoration: const InputDecoration(labelText: 'Event Date'),
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
              child: Text('There are no attachments for this event.'),
            ),
          if (selectedFiles.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: selectedFiles.length,
                itemBuilder: ((context, index) => AttachmentItem(
                    attachment: selectedFiles[index],
                    onRemoveAttachment: removeAttachment)),
              ),
            ),
        ],
      ),
    );
  }
}
