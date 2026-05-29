import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/models/checkup_log.dart';
import 'package:open_cloud_health/providers/checkups_provider.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/utils/result.dart';
import 'package:open_cloud_health/utils/standard_checkups.dart';

class EditCheckupDialog extends ConsumerStatefulWidget {
  const EditCheckupDialog({
    super.key,
    required this.profileId,
    required this.checkupId,
  });

  final String profileId;
  final String checkupId;

  @override
  ConsumerState<EditCheckupDialog> createState() => _EditCheckupDialogState();
}

class _EditCheckupDialogState extends ConsumerState<EditCheckupDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _frequencyController;
  late bool _isActive;
  bool _isLoading = false;
  late Future<List<CheckupLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _frequencyController = TextEditingController();
    _isActive = true;
    _logsFuture = ref
        .read(checkupsProvider(widget.profileId).notifier)
        .loadLogsForCheckup(widget.checkupId);
    
    // Initialize form fields once the checkup data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFields();
    });
  }

  void _initFields() {
    final checkupsAsync = ref.read(checkupsProvider(widget.profileId));
    checkupsAsync.whenData((data) {
      final item = data.firstWhere((c) => c.checkup.id == widget.checkupId);
      if (mounted) {
        setState(() {
          _frequencyController.text = item.checkup.frequencyInMonths.toString();
          _isActive = item.checkup.isActive;
        });
      }
    });
  }

  @override
  void dispose() {
    _frequencyController.dispose();
    super.dispose();
  }

  void _resetToDefault(int defaultFrequency) {
    setState(() {
      _frequencyController.text = defaultFrequency.toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Interval reset to default ($defaultFrequency months).')),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final newFrequency = int.parse(_frequencyController.text);
    
    // Read the current checkup to check if it matches default standard template frequency
    final currentCheckups = ref.read(checkupsProvider(widget.profileId)).value;
    bool isCustomInterval = true;
    
    if (currentCheckups != null) {
      final checkupWithStatus = currentCheckups.firstWhere((c) => c.checkup.id == widget.checkupId);
      final template = standardCheckups.firstWhere(
        (t) => t.name == checkupWithStatus.checkup.name,
        orElse: () => StandardCheckupTemplate(
          name: '',
          frequencyInMonths: 0,
          iconName: '',
          appliesTo: (_) => false,
        ),
      );
      
      if (template.name.isNotEmpty) {
        final profiles = ref.read(profilesProvider).value;
        final profile = profiles?.firstWhere((p) => p.id == widget.profileId);
        if (profile != null) {
          final defaultFrequency = template.getFrequency(profile);
          // If the new frequency is exactly the default, it's no longer customized
          if (newFrequency == defaultFrequency) {
            isCustomInterval = false;
          }
        }
      }
    }

    final result = await ref
        .read(checkupsProvider(widget.profileId).notifier)
        .updateCheckupSettings(
          checkupId: widget.checkupId,
          frequencyInMonths: newFrequency,
          isCustomInterval: isCustomInterval,
          isActive: _isActive,
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

  void _deleteLog(String logId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Completion Record'),
        content: const Text(
          'Are you sure you want to delete this checkup log? This event will also be removed from your medical history timeline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ref
          .read(checkupsProvider(widget.profileId).notifier)
          .deleteCheckupLog(logId);
      
      if (!mounted) return;
      
      if (result is Success) {
        setState(() {
          _logsFuture = ref
              .read(checkupsProvider(widget.profileId).notifier)
              .loadLogsForCheckup(widget.checkupId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completion record deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkupsAsync = ref.watch(checkupsProvider(widget.profileId));
    
    return checkupsAsync.when(
      data: (checkups) {
        final checkupWithStatus = checkups.firstWhere(
          (c) => c.checkup.id == widget.checkupId,
          orElse: () => throw Exception('Checkup not found'),
        );
        
        final checkup = checkupWithStatus.checkup;
        
        // Find if this checkup belongs to standard templates
        final template = standardCheckups.firstWhere(
          (t) => t.name == checkup.name,
          orElse: () => StandardCheckupTemplate(
            name: '',
            frequencyInMonths: 0,
            iconName: '',
            appliesTo: (_) => false,
          ),
        );
        
        int? defaultFrequency;
        if (template.name.isNotEmpty) {
          final profiles = ref.watch(profilesProvider).value;
          final profile = profiles?.firstWhere((p) => p.id == widget.profileId);
          if (profile != null) {
            defaultFrequency = template.getFrequency(profile);
          }
        }

        final hasDefault = defaultFrequency != null;
        final isDifferentFromDefault = hasDefault && 
            (int.tryParse(_frequencyController.text) ?? checkup.frequencyInMonths) != defaultFrequency;

        return AlertDialog(
          title: Text(
            checkup.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Interval settings
                    const Text(
                      'Checkup Interval',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _frequencyController,
                            decoration: InputDecoration(
                              labelText: 'Frequency',
                              suffixText: 'months',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter an interval.';
                              }
                              final val = int.tryParse(value);
                              if (val == null || val <= 0) {
                                return 'Must be a positive number.';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (isDifferentFromDefault) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _resetToDefault(defaultFrequency!),
                            icon: const Icon(Icons.undo, size: 16),
                            label: const Text('Reset'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.blue,
                              elevation: 0,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (hasDefault && !isDifferentFromDefault) ...[
                      const SizedBox(height: 6),
                      Text(
                        'This matches the standard medical recommendation.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    
                    // Active Status Switch
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Status',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Toggle off to collapse and hide it from the active list without affecting your history logs.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (val) {
                            setState(() {
                              _isActive = val;
                            });
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    
                    // Completion Logs History
                    const Text(
                      'Completions History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<CheckupLog>>(
                      future: _logsFuture,
                      builder: (ctx, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        final logs = snapshot.data ?? [];
                        if (logs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No completions logged yet.',
                              style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                            ),
                          );
                        }
                        
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: logs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final formattedDate = DateFormat.yMMMMd().format(log.dateCompleted);
                            
                            final details = [
                              if (log.doctorName != null && log.doctorName!.isNotEmpty) 'Dr. ${log.doctorName}',
                              if (log.location != null && log.location!.isNotEmpty) log.location,
                            ];
                            
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                formattedDate,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              subtitle: details.isNotEmpty
                                  ? Text(
                                      details.join(' at '),
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    )
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteLog(log.id),
                                tooltip: 'Delete Log',
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Settings'),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
