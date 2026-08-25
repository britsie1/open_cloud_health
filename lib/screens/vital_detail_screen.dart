import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/providers/vitals_provider.dart';
import 'package:open_cloud_health/providers/weight_preferences_provider.dart';
import 'package:open_cloud_health/utils/result.dart';
import 'package:open_cloud_health/widgets/weight/bmi_summary_card.dart';
import 'package:open_cloud_health/widgets/weight/set_goal_dialog.dart';
import 'package:open_cloud_health/widgets/weight/set_height_dialog.dart';
import 'package:open_cloud_health/widgets/weight/weight_chart_widget.dart';
import 'package:open_cloud_health/widgets/weight/weight_goal_card.dart';
import 'package:open_cloud_health/widgets/weight/weight_history_list.dart';

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
      case VitalType.weight:
        return 'Weight Tracker';
      case VitalType.bloodSugar:
        return 'Blood Sugar';
    }
  }

  String get _unit {
    switch (widget.vitalType) {
      case VitalType.bloodPressure:
        return 'mmHg';
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

  void _openHeightDialog(double? currentHeight) {
    showDialog(
      context: context,
      builder: (ctx) => SetHeightDialog(
        profileId: widget.profileId,
        initialHeightCm: currentHeight,
      ),
    );
  }

  void _openGoalDialog(double? currentTarget, double? currentWeight) {
    showDialog(
      context: context,
      builder: (ctx) => SetGoalDialog(
        profileId: widget.profileId,
        initialTargetKg: currentTarget,
        currentWeightKg: currentWeight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vitalsArgs = (profileId: widget.profileId, type: widget.vitalType);
    final vitalsAsync = ref.watch(vitalsProvider(vitalsArgs));
    final isWeight = widget.vitalType == VitalType.weight;
    final weightPrefsAsync = isWeight
        ? ref.watch(weightPreferencesProvider(widget.profileId))
        : null;
    final profilesAsync = isWeight ? ref.watch(profilesProvider) : null;
    final profile = profilesAsync?.value?.where((p) => p.id == widget.profileId).firstOrNull;

    if (isWeight) {
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(_title),
            actions: [
              if (weightPrefsAsync != null)
                IconButton(
                  icon: const Icon(Icons.straighten),
                  tooltip: 'Set Height for BMI',
                  onPressed: () {
                    final height = weightPrefsAsync.value?.heightCm;
                    _openHeightDialog(height);
                  },
                ),
              if (weightPrefsAsync != null)
                IconButton(
                  icon: const Icon(Icons.flag_outlined),
                  tooltip: 'Set Goal Weight',
                  onPressed: () {
                    final target = weightPrefsAsync.value?.targetWeightKg;
                    final currentWeight = vitalsAsync.value?.isNotEmpty == true
                        ? vitalsAsync.value!.last.value1
                        : null;
                    _openGoalDialog(target, currentWeight);
                  },
                ),
            ],
            bottom: const TabBar(
              indicatorColor: Colors.white,
              tabs: [
                Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
                Tab(icon: Icon(Icons.show_chart), text: 'Trends'),
                Tab(icon: Icon(Icons.history), text: 'History'),
              ],
            ),
          ),
          body: vitalsAsync.when(
            data: (logs) {
              final prefs = weightPrefsAsync?.value ?? const WeightPreferences();
              final sortedAsc = List<VitalLog>.from(logs)..sort((a, b) => a.date.compareTo(b.date));
              final latestWeight = sortedAsc.isNotEmpty ? sortedAsc.last.value1 : null;
              final startWeight = sortedAsc.isNotEmpty ? sortedAsc.first.value1 : null;

              return TabBarView(
                children: [
                  // Tab 1: Overview & Insights
                  _WeightOverviewTab(
                    profileId: widget.profileId,
                    logs: logs,
                    heightCm: prefs.heightCm,
                    targetWeightKg: prefs.targetWeightKg,
                    currentWeightKg: latestWeight,
                    startWeightKg: startWeight,
                    unit: _unit,
                    age: profile?.age,
                    gender: profile?.gender,
                    onOpenAddLog: _openAddVitalDialog,
                  ),

                  // Tab 2: Trends Chart
                  WeightChartWidget(
                    logs: logs,
                    unit: _unit,
                    heightCm: prefs.heightCm,
                    targetWeightKg: prefs.targetWeightKg,
                    onOpenAddLog: _openAddVitalDialog,
                  ),

                  // Tab 3: History List
                  WeightHistoryList(
                    logs: logs,
                    unit: _unit,
                    vitalsArgs: vitalsArgs,
                    heightCm: prefs.heightCm,
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'vital_add_fab_weight',
            onPressed: _openAddVitalDialog,
            icon: const Icon(Icons.add),
            label: const Text('Log Weight'),
            tooltip: 'Log weight entry',
          ),
        ),
      );
    }

    // Standard 2-tab view for other vitals (Blood Pressure, Blood Sugar)
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
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'vital_add_fab_${widget.vitalType.name}',
          onPressed: _openAddVitalDialog,
          icon: const Icon(Icons.add),
          label: const Text('Log Entry'),
          tooltip: 'Log measurement entry',
        ),
      ),
    );
  }
}

class _WeightOverviewTab extends StatelessWidget {
  const _WeightOverviewTab({
    required this.profileId,
    required this.logs,
    required this.heightCm,
    required this.targetWeightKg,
    required this.currentWeightKg,
    required this.startWeightKg,
    required this.unit,
    this.age,
    this.gender,
    required this.onOpenAddLog,
  });

  final String profileId;
  final List<VitalLog> logs;
  final double? heightCm;
  final double? targetWeightKg;
  final double? currentWeightKg;
  final double? startWeightKg;
  final String unit;
  final int? age;
  final Gender? gender;
  final VoidCallback onOpenAddLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withOpacity(0.6);

    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.scale_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              const Text(
                'No Weight Entries',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Log your first entry to track BMI and trends.',
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onOpenAddLog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Weight'),
              ),
            ],
          ),
        ),
      );
    }

    final latestLog = logs.last;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Latest Weight Measurement
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.monitor_weight_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Current Weight',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                DateFormat('MMM d, y').format(latestLog.date),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${latestLog.value1.toStringAsFixed(1)} $unit',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 12),
              if (logs.length > 1) _buildRecentDelta(logs),
            ],
          ),
          if (latestLog.note != null && latestLog.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              latestLog.note!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Section 2: BMI & Body Composition
          BmiSummaryCard(
            profileId: profileId,
            currentWeightKg: currentWeightKg,
            heightCm: heightCm,
            age: age,
            gender: gender,
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Section 3: Goal Progress
          WeightGoalCard(
            profileId: profileId,
            targetWeightKg: targetWeightKg,
            currentWeightKg: currentWeightKg,
            startWeightKg: startWeightKg,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRecentDelta(List<VitalLog> logs) {
    final sorted = List<VitalLog>.from(logs)..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.length < 2) return const SizedBox.shrink();
    final latest = sorted.last.value1;
    final previous = sorted[sorted.length - 2].value1;
    final diff = latest - previous;

    final isPositive = diff > 0;
    final color = diff == 0
        ? Colors.grey.shade700
        : (isPositive ? Colors.amber.shade900 : Colors.teal.shade700);
    final bgColor = color.withOpacity(0.08);
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            diff == 0 ? Icons.remove : (isPositive ? Icons.arrow_upward : Icons.arrow_downward),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '$sign${diff.toStringAsFixed(1)} $unit',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
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
      initialDate: _selectedDate,
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
    final isWeight = widget.vitalType == VitalType.weight;

    return AlertDialog(
      title: Text(isWeight ? 'Log Weight' : 'Log Measurement'),
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
                  decoration: InputDecoration(
                    labelText: isWeight ? 'Weight' : 'Value',
                    suffixText: widget.unit,
                    hintText: isWeight ? 'e.g. 74.5' : null,
                  ),
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
