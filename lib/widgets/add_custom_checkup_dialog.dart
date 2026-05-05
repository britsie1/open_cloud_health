import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/providers/checkups_provider.dart';
import 'package:open_cloud_health/utils/result.dart';

class AddCustomCheckupDialog extends ConsumerStatefulWidget {
  const AddCustomCheckupDialog({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<AddCustomCheckupDialog> createState() => _AddCustomCheckupDialogState();
}

class _AddCustomCheckupDialogState extends ConsumerState<AddCustomCheckupDialog> {
  final _formKey = GlobalKey<FormState>();
  String _enteredName = '';
  int _enteredFrequency = 12;
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    final result = await ref
        .read(checkupsProvider(widget.profileId).notifier)
        .addCustomCheckup(_enteredName, _enteredFrequency);

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
      title: const Text('Add Custom Checkup'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Checkup Name'),
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a valid name.';
                }
                return null;
              },
              onSaved: (value) {
                _enteredName = value!;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Frequency (in months)',
                suffixText: 'months',
              ),
              keyboardType: TextInputType.number,
              initialValue: _enteredFrequency.toString(),
              validator: (value) {
                if (value == null || value.isEmpty || int.tryParse(value) == null || int.tryParse(value)! <= 0) {
                  return 'Must be a valid positive number.';
                }
                return null;
              },
              onSaved: (value) {
                _enteredFrequency = int.parse(value!);
              },
            ),
          ],
        ),
      ),
      actions: [
         TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add'),
        ),
      ],
    );
  }
}
