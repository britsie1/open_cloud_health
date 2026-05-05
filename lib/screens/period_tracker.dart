import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/providers/period_provider.dart';
import 'package:open_cloud_health/widgets/cycle_donut_chart.dart';
import 'package:open_cloud_health/widgets/symptom_button.dart';

class PeriodTrackerScreen extends ConsumerStatefulWidget {
  const PeriodTrackerScreen({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends ConsumerState<PeriodTrackerScreen> {
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  void _changeDate(int offsetDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offsetDays));
    });
  }

  @override
  Widget build(BuildContext context) {
    final periodStateAsync = ref.watch(periodProvider(widget.profileId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Period Tracker'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.track_changes), text: 'Current Cycle'),
              Tab(icon: Icon(Icons.history), text: 'History'),
            ],
          ),
        ),
        body: periodStateAsync.when(
          data: (state) {
            return TabBarView(
              children: [
                _CurrentCycleTab(
                  profileId: widget.profileId,
                  state: state,
                  selectedDate: _selectedDate,
                  onDateChanged: _changeDate,
                ),
                _HistoryTab(state: state),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _CurrentCycleTab extends ConsumerWidget {
  const _CurrentCycleTab({
    required this.profileId,
    required this.state,
    required this.selectedDate,
    required this.onDateChanged,
  });

  final String profileId;
  final PeriodState state;
  final DateTime selectedDate;
  final Function(int) onDateChanged;

  void _startNewCycle(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month - 2, now.day);
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: now,
      helpText: 'SELECT START DATE OF NEW CYCLE',
    );

    if (pickedDate != null) {
      await ref.read(periodProvider(profileId).notifier).startNewCycle(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Find log for the selected date
    final logForDate = state.currentCycleLogs.cast<PeriodLog?>().firstWhere(
      (log) => log?.date.year == selectedDate.year && log?.date.month == selectedDate.month && log?.date.day == selectedDate.day,
      orElse: () => null,
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          CycleDonutChart(periodState: state),
          
          if (state.currentCycle == null) ...[
             const SizedBox(height: 24),
             ElevatedButton(
                onPressed: () => _startNewCycle(context, ref),
                child: const Text('Start New Cycle'),
             ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Text(
                'Disclaimer: Predictions are estimates and should not be used as a contraceptive method.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            if (state.expectedNextPeriodDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Next cycle expected: ${DateFormat.yMMMd().format(state.expectedNextPeriodDate!)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            
            const Divider(),
            
            // Date Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => onDateChanged(-1),
                ),
                Text(
                  DateFormat.yMMMd().format(selectedDate),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: selectedDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)) 
                      ? () => onDateChanged(1) 
                      : null,
                ),
              ],
            ),

            // Symptoms Logging
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flow', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: FlowLevel.values.map((flow) {
                      final isSelected = logForDate?.flowLevel == flow;
                      return SymptomButton(
                        icon: Icons.water_drop,
                        label: flow.name.capitalize(),
                        isSelected: isSelected,
                        onTap: () {
                          final newLog = PeriodLog(
                            id: logForDate?.id,
                            cycleId: state.currentCycle!.id,
                            date: selectedDate,
                            flowLevel: isSelected ? null : flow, // Toggle off if already selected
                            moods: logForDate?.moods ?? [],
                            physicalSymptoms: logForDate?.physicalSymptoms ?? [],
                          );
                          ref.read(periodProvider(profileId).notifier).logSymptom(newLog);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  Text('Physical', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PhysicalSymptom.values.map((symptom) {
                      final isSelected = logForDate?.physicalSymptoms.contains(symptom) ?? false;
                      return SymptomButton(
                        icon: _getPhysicalIcon(symptom),
                        label: _formatSymptomName(symptom.name),
                        isSelected: isSelected,
                        onTap: () {
                          List<PhysicalSymptom> updated = List.from(logForDate?.physicalSymptoms ?? []);
                          if (isSelected) {
                            updated.remove(symptom);
                          } else {
                            updated.add(symptom);
                          }
                          
                          final newLog = PeriodLog(
                            id: logForDate?.id,
                            cycleId: state.currentCycle!.id,
                            date: selectedDate,
                            flowLevel: logForDate?.flowLevel,
                            moods: logForDate?.moods ?? [],
                            physicalSymptoms: updated,
                          );
                          ref.read(periodProvider(profileId).notifier).logSymptom(newLog);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  Text('Mood', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: Mood.values.map((mood) {
                      final isSelected = logForDate?.moods.contains(mood) ?? false;
                      return SymptomButton(
                        icon: _getMoodIcon(mood),
                        label: mood.name.capitalize(),
                        isSelected: isSelected,
                        onTap: () {
                          List<Mood> updated = List.from(logForDate?.moods ?? []);
                          if (isSelected) {
                            updated.remove(mood);
                          } else {
                            updated.add(mood);
                          }
                          
                          final newLog = PeriodLog(
                            id: logForDate?.id,
                            cycleId: state.currentCycle!.id,
                            date: selectedDate,
                            flowLevel: logForDate?.flowLevel,
                            moods: updated,
                            physicalSymptoms: logForDate?.physicalSymptoms ?? [],
                          );
                          ref.read(periodProvider(profileId).notifier).logSymptom(newLog);
                        },
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  Center(
                    child: OutlinedButton(
                      onPressed: () => _startNewCycle(context, ref),
                      child: const Text('Start New Cycle Today'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  IconData _getPhysicalIcon(PhysicalSymptom s) {
    switch(s) {
      case PhysicalSymptom.cramps: return Icons.bolt;
      case PhysicalSymptom.headache: return Icons.sentiment_dissatisfied;
      case PhysicalSymptom.bloating: return Icons.air;
      case PhysicalSymptom.breastTenderness: return Icons.favorite_border;
    }
  }

  IconData _getMoodIcon(Mood m) {
     switch(m) {
      case Mood.happy: return Icons.sentiment_very_satisfied;
      case Mood.calm: return Icons.spa;
      case Mood.irritable: return Icons.volcano;
      case Mood.sad: return Icons.water_drop_outlined;
      case Mood.anxious: return Icons.waves;
    }
  }

  String _formatSymptomName(String name) {
    if (name == 'breastTenderness') return 'Tender\nBreasts';
    return name.capitalize();
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.state});
  final PeriodState state;

  @override
  Widget build(BuildContext context) {
    if (state.pastCycles.isEmpty) {
      return const Center(child: Text('No past cycles recorded.'));
    }

    return ListView.builder(
      itemCount: state.pastCycles.length,
      itemBuilder: (ctx, index) {
        final cycle = state.pastCycles[index];
        return _HistoryCycleTile(cycle: cycle);
      },
    );
  }
}

class _HistoryCycleTile extends ConsumerWidget {
  const _HistoryCycleTile({required this.cycle});
  final PeriodCycle cycle;

  String _formatSymptomName(String name) {
    if (name == 'breastTenderness') return 'Tender Breasts';
    return name.capitalize();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startDate = DateFormat.yMMMd().format(cycle.startDate);
    final endDate = cycle.endDate != null ? DateFormat.yMMMd().format(cycle.endDate!) : 'Ongoing';
    
    final logsAsync = ref.watch(cycleLogsProvider(cycle.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      child: ExpansionTile(
        leading: const Icon(Icons.calendar_month),
        title: Text('$startDate - $endDate'),
        subtitle: Text('Cycle Length: ${cycle.cycleLength ?? "?"} days'),
        children: [
          logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No symptoms logged for this cycle.'),
                );
              }
              return Column(
                children: logs.map((log) {
                  final date = DateFormat.MMMd().format(log.date);
                  final flow = log.flowLevel?.name.capitalize() ?? '';
                  final phys = log.physicalSymptoms.map((s) => _formatSymptomName(s.name)).join(', ');
                  final mood = log.moods.map((m) => m.name.capitalize()).join(', ');
                  
                  final parts = [
                    if (flow.isNotEmpty) 'Flow: $flow',
                    if (phys.isNotEmpty) 'Physical: $phys',
                    if (mood.isNotEmpty) 'Mood: $mood',
                  ];
                  
                  return ListTile(
                    dense: true,
                    title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(parts.isEmpty ? 'No details' : parts.join('\n')),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading logs: $err'),
            ),
          )
        ],
      ),
    );
  }
}

extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
}
