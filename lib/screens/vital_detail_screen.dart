import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/providers/vitals_provider.dart';
import 'package:open_cloud_health/utils/result.dart';

class VitalDetailScreen extends ConsumerStatefulWidget {
  const VitalDetailScreen({
    super.key,
    required this.profileId,
    required this.vitalType,
  });

  final String profileId;
  final VitalType vitalType;

  @override
  ConsumerState<VitalDetailScreen> createState() => _VitalDetailScreenState();
}

class _VitalDetailScreenState extends ConsumerState<VitalDetailScreen> {
  String get _title {
    switch (widget.vitalType) {
      case VitalType.bloodPressure:
        return 'Blood Pressure';
      case VitalType.heartRate:
        return 'Heart Rate';
      case VitalType.weight:
        return 'Weight';
      case VitalType.bloodSugar:
        return 'Blood Sugar';
    }
  }

  String get _unit {
    switch (widget.vitalType) {
      case VitalType.bloodPressure:
        return 'mmHg';
      case VitalType.heartRate:
        return 'bpm';
      case VitalType.weight:
        return 'kg';
      case VitalType.bloodSugar:
        return 'mg/dL';
    }
  }

  void _openAddVitalDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddVitalDialog(
        profileId: widget.profileId,
        vitalType: widget.vitalType,
        unit: _unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vitalsArgs = (profileId: widget.profileId, type: widget.vitalType);
    final vitalsAsync = ref.watch(vitalsProvider(vitalsArgs));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.show_chart), text: 'Chart'),
              Tab(icon: Icon(Icons.history), text: 'History'),
            ],
          ),
        ),
        body: vitalsAsync.when(
          data: (logs) {
            return TabBarView(
              children: [
                _ChartTab(logs: logs, vitalType: widget.vitalType, unit: _unit),
                _HistoryTab(logs: logs, vitalType: widget.vitalType, unit: _unit, vitalsArgs: vitalsArgs),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddVitalDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _ChartTab extends StatelessWidget {
  const _ChartTab({required this.logs, required this.vitalType, required this.unit});

  final List<VitalLog> logs;
  final VitalType vitalType;
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(child: Text('No data recorded yet.'));
    }

    // Sort logs chronologically for the chart
    final sortedLogs = List<VitalLog>.from(logs)..sort((a, b) => a.date.compareTo(b.date));

    // Convert dates to days since first log for the X axis
    final firstDate = sortedLogs.first.date;
    
    final spots1 = <FlSpot>[];
    final spots2 = <FlSpot>[]; // Used for Diastolic if BP

    double minY1 = double.infinity;
    double maxY1 = double.negativeInfinity;
    double minY2 = double.infinity;
    double maxY2 = double.negativeInfinity;

    for (var log in sortedLogs) {
      final daysSince = log.date.difference(firstDate).inDays.toDouble();
      spots1.add(FlSpot(daysSince, log.value1));
      
      if (log.value1 < minY1) minY1 = log.value1;
      if (log.value1 > maxY1) maxY1 = log.value1;

      if (vitalType == VitalType.bloodPressure && log.value2 != null) {
        spots2.add(FlSpot(daysSince, log.value2!));
        if (log.value2! < minY2) minY2 = log.value2!;
        if (log.value2! > maxY2) maxY2 = log.value2!;
      }
    }

    // Add some padding to Y axis
    final overallMinY = vitalType == VitalType.bloodPressure ? [minY1, minY2].reduce((a, b) => a < b ? a : b) : minY1;
    final overallMaxY = vitalType == VitalType.bloodPressure ? [maxY1, maxY2].reduce((a, b) => a > b ? a : b) : maxY1;
    
    final yPadding = (overallMaxY - overallMinY) * 0.2;
    final finalMinY = (overallMinY - yPadding).clamp(0.0, double.infinity);
    final finalMaxY = overallMaxY + yPadding;


    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: LineChart(
        LineChartData(
          minY: finalMinY,
          maxY: finalMaxY == finalMinY ? finalMaxY + 10 : finalMaxY,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // Only show a few labels on the X axis to prevent crowding
                  if (value % 5 != 0 && value != spots1.last.x) return const SizedBox.shrink();
                  final date = firstDate.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(DateFormat.Md().format(date), style: const TextStyle(fontSize: 10)),
                  );
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
          lineBarsData: [
            LineChartBarData(
              spots: spots1,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              ),
            ),
            if (vitalType == VitalType.bloodPressure)
              LineChartBarData(
                spots: spots2,
                isCurved: true,
                color: Theme.of(context).colorScheme.secondary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.logs, required this.vitalType, required this.unit, required this.vitalsArgs});

  final List<VitalLog> logs;
  final VitalType vitalType;
  final String unit;
  final VitalsArgs vitalsArgs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (logs.isEmpty) {
      return const Center(child: Text('No data recorded yet.'));
    }

    // Sort descending for history
    final sortedLogs = List<VitalLog>.from(logs)..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      itemCount: sortedLogs.length,
      itemBuilder: (ctx, index) {
        final log = sortedLogs[index];
        
        String title;
        if (vitalType == VitalType.bloodPressure) {
          title = '${log.value1.toInt()}/${log.value2?.toInt() ?? '?'} $unit';
        } else {
          title = '${log.value1} $unit';
        }

        return Dismissible(
          key: ValueKey(log.id),
          background: Container(
            color: Theme.of(context).colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            ref.read(vitalsProvider(vitalsArgs).notifier).deleteLog(log.id);
          },
          child: ListTile(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('MMM d, y - h:mm a').format(log.date)),
                if (log.note != null && log.note!.isNotEmpty)
                  Text(log.note!, style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _AddVitalDialog extends ConsumerStatefulWidget {
  const _AddVitalDialog({
    required this.profileId,
    required this.vitalType,
    required this.unit,
  });

  final String profileId;
  final VitalType vitalType;
  final String unit;

  @override
  ConsumerState<_AddVitalDialog> createState() => _AddVitalDialogState();
}

class _AddVitalDialogState extends ConsumerState<_AddVitalDialog> {
  final _formKey = GlobalKey<FormState>();
  double? _enteredValue1;
  double? _enteredValue2;
  String? _enteredNote;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() { _isLoading = true; });

    final log = VitalLog(
      profileId: widget.profileId,
      type: widget.vitalType,
      date: _selectedDate,
      value1: _enteredValue1!,
      value2: _enteredValue2,
      unit: widget.unit,
      note: _enteredNote,
    );

    final vitalsArgs = (profileId: widget.profileId, type: widget.vitalType);
    final result = await ref.read(vitalsProvider(vitalsArgs).notifier).addLog(log);

    if (!mounted) return;

    if (result is Success) {
      Navigator.of(context).pop();
    } else {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving.')));
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (pickedDate != null) {
      setState(() { _selectedDate = pickedDate; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBP = widget.vitalType == VitalType.bloodPressure;

    return AlertDialog(
      title: const Text('Log Measurement'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat.yMMMd().format(_selectedDate)),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Change Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isBP) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Systolic'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid' : null,
                        onSaved: (value) => _enteredValue1 = double.parse(value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Diastolic'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid' : null,
                        onSaved: (value) => _enteredValue2 = double.parse(value!),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextFormField(
                  decoration: InputDecoration(labelText: 'Value', suffixText: widget.unit),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid number' : null,
                  onSaved: (value) => _enteredValue1 = double.parse(value!),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                onSaved: (value) => _enteredNote = value,
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
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator()) : const Text('Save'),
        ),
      ],
    );
  }
}
