import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/providers/weight_preferences_provider.dart';
import 'package:open_cloud_health/utils/bmi_calculator.dart';

class SetGoalDialog extends ConsumerStatefulWidget {
  const SetGoalDialog({
    super.key,
    required this.profileId,
    this.initialTargetKg,
    this.currentWeightKg,
  });

  final String profileId;
  final double? initialTargetKg;
  final double? currentWeightKg;

  @override
  ConsumerState<SetGoalDialog> createState() => _SetGoalDialogState();
}

class _SetGoalDialogState extends ConsumerState<SetGoalDialog> {
  int _selectedUnitIndex = 0; // 0 for kg, 1 for lbs
  final _goalController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialTargetKg != null && widget.initialTargetKg! > 0) {
      _goalController.text = widget.initialTargetKg!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final val = double.tryParse(_goalController.text);
    if (val != null && val > 0) {
      final targetKg = _selectedUnitIndex == 0 ? val : BmiCalculator.lbsToKg(val);
      ref.read(weightPreferencesProvider(widget.profileId).notifier).setTargetWeight(targetKg);
    }
    Navigator.of(context).pop();
  }

  void _clearGoal() {
    ref.read(weightPreferencesProvider(widget.profileId).notifier).setTargetWeight(null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Target Weight'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Metric (kg)')),
                  ButtonSegment(value: 1, label: Text('Imperial (lbs)')),
                ],
                selected: {_selectedUnitIndex},
                onSelectionChanged: (selection) {
                  final newIdx = selection.first;
                  if (newIdx != _selectedUnitIndex) {
                    final currentVal = double.tryParse(_goalController.text);
                    if (currentVal != null) {
                      if (newIdx == 1) {
                        _goalController.text = BmiCalculator.kgToLbs(currentVal).toStringAsFixed(1);
                      } else {
                        _goalController.text = BmiCalculator.lbsToKg(currentVal).toStringAsFixed(1);
                      }
                    }
                    setState(() {
                      _selectedUnitIndex = newIdx;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _goalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Target Goal',
                  suffixText: _selectedUnitIndex == 0 ? 'kg' : 'lbs',
                  hintText: _selectedUnitIndex == 0 ? 'e.g. 70.0' : 'e.g. 154.0',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a target weight';
                  }
                  final val = double.tryParse(value);
                  if (val == null || val <= 10 || val > 500) {
                    return 'Please enter a valid weight';
                  }
                  return null;
                },
              ),
              if (widget.currentWeightKg != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Current weight: ${widget.currentWeightKg!.toStringAsFixed(1)} kg',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (widget.initialTargetKg != null)
          TextButton(
            onPressed: _clearGoal,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Goal'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save Goal'),
        ),
      ],
    );
  }
}
