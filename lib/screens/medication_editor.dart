import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';
import 'package:open_cloud_health/utils/result.dart';
import 'package:permission_handler/permission_handler.dart';

class MedicationEditorScreen extends ConsumerStatefulWidget {
  const MedicationEditorScreen({
    super.key,
    required this.profileId,
    this.medication,
  });

  final String profileId;
  final Medication? medication;

  @override
  ConsumerState<MedicationEditorScreen> createState() => _MedicationEditorScreenState();
}

class _MedicationEditorScreenState extends ConsumerState<MedicationEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _stockQuantityController;
  late final TextEditingController _lowStockThresholdController;
  late List<TimeOfDay> _selectedTimes;
  late List<int> _selectedDays;
  late String _selectedType;
  late bool _notificationEnabled;
  late bool _alarmEnabled;
  late bool _isAsNeeded;
  late bool _trackInventory;

  static const List<String> _medicationTypes = [
    'Tablet',
    'Liquid',
    'Capsule',
    'Injection',
    'Drops',
    'Inhaler',
    'Other',
  ];

  final List<Map<String, dynamic>> _weekdays = [
    {'day': 1, 'label': 'M'},
    {'day': 2, 'label': 'T'},
    {'day': 3, 'label': 'W'},
    {'day': 4, 'label': 'T'},
    {'day': 5, 'label': 'F'},
    {'day': 6, 'label': 'S'},
    {'day': 7, 'label': 'S'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication?.name ?? '');
    _dosageController = TextEditingController(text: widget.medication?.dosage ?? '');
    _isAsNeeded = widget.medication?.isAsNeeded ?? false;
    _trackInventory = widget.medication?.trackInventory ?? false;
    _stockQuantityController = TextEditingController(text: widget.medication?.stockQuantity.toString() ?? '0.0');
    _lowStockThresholdController = TextEditingController(text: widget.medication?.lowStockThreshold.toString() ?? '0.0');
    
    _selectedTimes = widget.medication?.timesOfDay != null 
        ? List<TimeOfDay>.from(widget.medication!.timesOfDay) 
        : [TimeOfDay.now()];
    _selectedDays = widget.medication?.daysOfWeek != null
        ? List<int>.from(widget.medication!.daysOfWeek)
        : [1, 2, 3, 4, 5, 6, 7];
    _selectedType = widget.medication?.type ?? 'Tablet';
    _notificationEnabled = widget.medication?.notificationEnabled ?? false;
    _alarmEnabled = widget.medication?.alarmEnabled ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _stockQuantityController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _selectPreset(String preset) {
    setState(() {
      if (preset == 'everyday') {
        _selectedDays = [1, 2, 3, 4, 5, 6, 7];
      } else if (preset == 'weekdays') {
        _selectedDays = [1, 2, 3, 4, 5];
      } else if (preset == 'weekends') {
        _selectedDays = [6, 7];
      } else if (preset == 'clear') {
        _selectedDays = [];
      }
    });
  }

  Future<void> _addTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      if (!_selectedTimes.any((t) => t.hour == time.hour && t.minute == time.minute)) {
        setState(() {
          _selectedTimes.add(time);
          _selectedTimes.sort((a, b) {
            if (a.hour != b.hour) return a.hour.compareTo(b.hour);
            return a.minute.compareTo(b.minute);
          });
        });
      }
    }
  }

  Future<void> _editTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );
    if (time != null) {
      if (!_selectedTimes.any((t) => t.hour == time.hour && t.minute == time.minute)) {
        setState(() {
          _selectedTimes[index] = time;
          _selectedTimes.sort((a, b) {
            if (a.hour != b.hour) return a.hour.compareTo(b.hour);
            return a.minute.compareTo(b.minute);
          });
        });
      }
    }
  }

  void _removeTime(int index) {
    if (_selectedTimes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A medication requires at least one dosage time.')),
      );
      return;
    }
    setState(() {
      _selectedTimes.removeAt(index);
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final dosage = _dosageController.text.trim();
    final stockQuantity = _trackInventory ? (double.tryParse(_stockQuantityController.text.trim()) ?? 0.0) : 0.0;
    final lowStockThreshold = _trackInventory ? (double.tryParse(_lowStockThresholdController.text.trim()) ?? 0.0) : 0.0;

    if (!_isAsNeeded) {
      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one day of the week.')),
        );
        return;
      }

      if (_selectedTimes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one dosage time.')),
        );
        return;
      }
    }

    Result<void, Exception> result;

    if (widget.medication == null) {
      final newMed = Medication(
        profileId: widget.profileId,
        name: name,
        dosage: dosage,
        type: _selectedType,
        notificationEnabled: _isAsNeeded ? false : _notificationEnabled,
        alarmEnabled: _isAsNeeded ? false : _alarmEnabled,
        daysOfWeek: _isAsNeeded ? const [1, 2, 3, 4, 5, 6, 7] : _selectedDays,
        timesOfDay: _isAsNeeded ? const [] : _selectedTimes,
        isAsNeeded: _isAsNeeded,
        trackInventory: _trackInventory,
        stockQuantity: stockQuantity,
        lowStockThreshold: lowStockThreshold,
      );

      result = await ref
          .read(medicationsProvider(widget.profileId).notifier)
          .addMedication(newMed);
    } else {
      final updatedMed = Medication(
        id: widget.medication!.id,
        profileId: widget.medication!.profileId,
        name: name,
        dosage: dosage,
        type: _selectedType,
        notificationEnabled: _isAsNeeded ? false : _notificationEnabled,
        alarmEnabled: _isAsNeeded ? false : _alarmEnabled,
        daysOfWeek: _isAsNeeded ? const [1, 2, 3, 4, 5, 6, 7] : _selectedDays,
        timesOfDay: _isAsNeeded ? const [] : _selectedTimes,
        isActive: widget.medication!.isActive,
        isAsNeeded: _isAsNeeded,
        trackInventory: _trackInventory,
        stockQuantity: stockQuantity,
        lowStockThreshold: lowStockThreshold,
      );

      result = await ref
          .read(medicationsProvider(widget.profileId).notifier)
          .updateMedication(updatedMed);
    }

    if (!mounted) return;

    if (result is Success) {
      context.pop();
    } else if (result is Failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save medication: ${result.exception}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNew = widget.medication == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Medication' : 'Edit Medication'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.1),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medication Info',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Medication Name',
                            prefixIcon: const Icon(Icons.medication),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter medication name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dosageController,
                          decoration: InputDecoration(
                            labelText: 'Dosage (Optional)',
                            prefixIcon: const Icon(Icons.scale),
                            hintText: 'e.g., 200mg, 1 tablet',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (val) {
                            return null;
                          },
                        ),
                        const Divider(height: 32),
                        SwitchListTile(
                          title: const Text('Track As-Needed (PRN)'),
                          subtitle: const Text('For ad-hoc medications like insulin logged dynamically without a scheduled time'),
                          contentPadding: EdgeInsets.zero,
                          value: _isAsNeeded,
                          onChanged: (val) {
                            setState(() {
                              _isAsNeeded = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Type selector card
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medication Type',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _medicationTypes.map((type) {
                              final isSelected = _selectedType == type;
                              return ChoiceChip(
                                label: Text(type),
                                selected: isSelected,
                                selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: isSelected 
                                      ? theme.colorScheme.primary 
                                      : theme.colorScheme.onSurface,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedType = type;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Inventory Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inventory Tracking',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Track Stock Level'),
                          subtitle: const Text('Automatically monitor remaining quantity and alert when low'),
                          contentPadding: EdgeInsets.zero,
                          value: _trackInventory,
                          onChanged: (val) {
                            setState(() {
                              _trackInventory = val;
                            });
                          },
                        ),
                        if (_trackInventory) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _stockQuantityController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Current Stock',
                                    prefixIcon: const Icon(Icons.inventory),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (_trackInventory) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(val) == null) {
                                        return 'Invalid';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _lowStockThresholdController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Low Stock Alert',
                                    prefixIcon: const Icon(Icons.warning_amber),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (_trackInventory) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(val) == null) {
                                        return 'Invalid';
                                      }
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
                const SizedBox(height: 20),

                // Show timing and reminders only if not As-Needed (PRN)
                if (!_isAsNeeded) ...[
                  // Schedule card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Frequency & Timing',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Repeat On',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _weekdays.map((item) {
                              final dayNum = item['day'] as int;
                              final label = item['label'] as String;
                              final isSelected = _selectedDays.contains(dayNum);

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                  child: InkWell(
                                    onTap: () => _toggleDay(dayNum),
                                    borderRadius: BorderRadius.circular(24),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected 
                                            ? theme.colorScheme.primary 
                                            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                                        border: Border.all(
                                          color: isSelected 
                                              ? theme.colorScheme.primary 
                                              : theme.colorScheme.outline.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                        boxShadow: isSelected 
                                            ? [
                                                BoxShadow(
                                                  color: theme.colorScheme.primary.withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected 
                                                ? theme.colorScheme.onPrimary 
                                                : theme.colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          // Quick Presets
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _presetButton('Everyday', () => _selectPreset('everyday')),
                              _presetButton('Weekdays', () => _selectPreset('weekdays')),
                              _presetButton('Weekends', () => _selectPreset('weekends')),
                              _presetButton('Clear', () => _selectPreset('clear')),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Dosage Times',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _addTime,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Time'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Times List
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedTimes.length,
                            itemBuilder: (context, index) {
                              final time = _selectedTimes[index];
                              return Card(
                                elevation: 0,
                                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(Icons.access_time, color: theme.colorScheme.primary),
                                  title: Text(
                                    time.format(context),
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () => _editTime(index),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: theme.colorScheme.error, size: 20),
                                        onPressed: () => _removeTime(index),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reminders Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications & Alarms',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: const Text('Enable Notifications'),
                            subtitle: const Text('Get push notifications at scheduled times'),
                            contentPadding: EdgeInsets.zero,
                            value: _notificationEnabled,
                            onChanged: (val) async {
                              if (val) {
                                final status = await Permission.notification.request();
                                if (!status.isGranted) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Notifications permission is required.')),
                                    );
                                  }
                                  return;
                                }
                              }
                              setState(() {
                                _notificationEnabled = val;
                              });
                            },
                          ),
                          const Divider(),
                          SwitchListTile(
                            title: const Text('Set System Alarm'),
                            subtitle: const Text('Set standard system clock alarms (Android only)'),
                            contentPadding: EdgeInsets.zero,
                            value: _alarmEnabled,
                            onChanged: (val) async {
                              if (val) {
                                if (Platform.isAndroid) {
                                  final status = await Permission.scheduleExactAlarm.request();
                                  if (!status.isGranted) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Exact alarm permission is required.')),
                                      );
                                    }
                                    return;
                                  }
                                } else if (Platform.isIOS) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('System alarms are not supported on iOS.')),
                                    );
                                  }
                                  return;
                                }
                              }
                              setState(() {
                                _alarmEnabled = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                    child: Text(
                      isNew ? 'Add Medication' : 'Save Changes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _presetButton(String label, VoidCallback onPressed) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
