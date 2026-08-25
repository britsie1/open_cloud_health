import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/providers/weight_preferences_provider.dart';
import 'package:open_cloud_health/utils/bmi_calculator.dart';

class SetHeightDialog extends ConsumerStatefulWidget {
  const SetHeightDialog({
    super.key,
    required this.profileId,
    this.initialHeightCm,
  });

  final String profileId;
  final double? initialHeightCm;

  @override
  ConsumerState<SetHeightDialog> createState() => _SetHeightDialogState();
}

class _SetHeightDialogState extends ConsumerState<SetHeightDialog> {
  int _selectedUnitIndex = 0; // 0 for cm, 1 for ft/in
  final _cmController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialHeightCm != null && widget.initialHeightCm! > 0) {
      _cmController.text = widget.initialHeightCm!.toStringAsFixed(0);
      final ftIn = BmiCalculator.cmToFeetInches(widget.initialHeightCm!);
      _feetController.text = ftIn.feet.toString();
      _inchesController.text = ftIn.inches.toString();
    }
  }

  @override
  void dispose() {
    _cmController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    double? heightCm;
    if (_selectedUnitIndex == 0) {
      heightCm = double.tryParse(_cmController.text);
    } else {
      final feet = int.tryParse(_feetController.text) ?? 0;
      final inches = int.tryParse(_inchesController.text) ?? 0;
      if (feet > 0 || inches > 0) {
        heightCm = BmiCalculator.feetInchesToCm(feet, inches);
      }
    }

    if (heightCm != null && heightCm > 0) {
      ref.read(weightPreferencesProvider(widget.profileId).notifier).setHeight(heightCm);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Height for BMI'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Metric (cm)')),
                  ButtonSegment(value: 1, label: Text('Imperial (ft/in)')),
                ],
                selected: {_selectedUnitIndex},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedUnitIndex = selection.first;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (_selectedUnitIndex == 0) ...[
                TextFormField(
                  controller: _cmController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    suffixText: 'cm',
                    hintText: 'e.g. 175',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter height';
                    }
                    final val = double.tryParse(value);
                    if (val == null || val < 50 || val > 260) {
                      return 'Enter a valid height (50 - 260 cm)';
                    }
                    return null;
                  },
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _feetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Feet',
                          suffixText: 'ft',
                          hintText: '5',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final val = int.tryParse(value);
                          if (val == null || val < 1 || val > 8) {
                            return '1 - 8 ft';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _inchesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Inches',
                          suffixText: 'in',
                          hintText: '9',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          final val = int.tryParse(value);
                          if (val == null || val < 0 || val >= 12) {
                            return '0 - 11 in';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
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
          onPressed: _save,
          child: const Text('Save Height'),
        ),
      ],
    );
  }
}
