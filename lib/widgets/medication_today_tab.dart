import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthicons_flutter/healthicons_flutter.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';
import 'package:open_cloud_health/utils/result.dart';

Widget _getMedicationIcon(String type) {
  switch (type) {
    case 'Tablet':
      return const Pills2Outline();
    case 'Liquid':
      return const MedicineBottleOutline();
    case 'Capsule':
      return const MedicinesOutline();
    case 'Injection':
      return const SyringeOutline();
    case 'Drops':
      return const BloodDropOutline();
    case 'Inhaler':
      return const AsthmaInhalerOutline();
    default:
      return const MedicinesOutline();
  }
}

class TodayMedicationTask {
  final Medication medication;
  final TimeOfDay time;

  TodayMedicationTask({required this.medication, required this.time});
}

class MedicationTodayTab extends ConsumerWidget {
  const MedicationTodayTab({super.key, required this.profileId});
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsProvider(profileId));
    final logsAsync = ref.watch(medicationLogsProvider(profileId));

    return medicationsAsync.when(
      data: (medications) {
        final todayWeekday = DateTime.now().weekday;
        final activeMedications =
            medications.where((m) => m.isActive && m.daysOfWeek.contains(todayWeekday)).toList();

        final List<TodayMedicationTask> tasks = [];
        for (final med in activeMedications) {
          for (final time in med.timesOfDay) {
            tasks.add(TodayMedicationTask(medication: med, time: time));
          }
        }

        // Sort tasks chronologically
        tasks.sort((a, b) {
          if (a.time.hour != b.time.hour) return a.time.hour.compareTo(b.time.hour);
          return a.time.minute.compareTo(b.time.minute);
        });

        if (tasks.isEmpty) {
          return const Center(child: Text("No active medications for today."));
        }

        return logsAsync.when(
          data: (logs) {
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (ctx, index) {
                final task = tasks[index];
                final med = task.medication;
                final taskTime = task.time;

                final isTaken = logs.any((log) =>
                    log.medicationId == med.id &&
                    log.timestamp.hour == taskTime.hour &&
                    log.timestamp.minute == taskTime.minute);

                final hour = taskTime.hour.toString().padLeft(2, '0');
                final minute = taskTime.minute.toString().padLeft(2, '0');
                final timeFormatted = '$hour:$minute';

                return CheckboxListTile(
                  secondary: SizedBox(height: 32, width: 32, child: _getMedicationIcon(med.type)),
                  title: Text(
                    med.name,
                    style: TextStyle(
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                      color: isTaken ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text('${med.dosage} at $timeFormatted'),
                  value: isTaken,
                  onChanged: (val) async {
                    Result<void, Exception> result;
                    final now = DateTime.now();
                    final targetTimestamp = DateTime(now.year, now.month, now.day, taskTime.hour, taskTime.minute);
                    
                    if (val == true) {
                      result = await ref
                          .read(medicationLogsProvider(profileId).notifier)
                          .addLog(
                            MedicationLog(
                              medicationId: med.id,
                              timestamp: targetTimestamp,
                            ),
                          );
                    } else {
                      result = await ref
                          .read(medicationLogsProvider(profileId).notifier)
                          .removeLog(
                            med.id,
                            targetTimestamp,
                            time: taskTime,
                          );
                    }

                    if (result is Failure && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Failed to update log: ${result.exception}')),
                      );
                    }
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
