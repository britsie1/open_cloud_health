import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthicons_flutter/healthicons_flutter.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';
import 'package:open_cloud_health/utils/result.dart';
import 'package:open_cloud_health/widgets/medication_adherence_card.dart';
import 'package:open_cloud_health/widgets/log_tracked_dose_dialog.dart';

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
    final theme = Theme.of(context);

    return medicationsAsync.when(
      data: (medications) {
        final todayWeekday = DateTime.now().weekday;
        
        // Active scheduled medications today
        final activeScheduled = medications
            .where((m) => m.isActive && !m.isAsNeeded && m.daysOfWeek.contains(todayWeekday))
            .toList();

        final List<TodayMedicationTask> tasks = [];
        for (final med in activeScheduled) {
          for (final time in med.timesOfDay) {
            tasks.add(TodayMedicationTask(medication: med, time: time));
          }
        }

        // Sort chronologically
        tasks.sort((a, b) {
          if (a.time.hour != b.time.hour) return a.time.hour.compareTo(b.time.hour);
          return a.time.minute.compareTo(b.time.minute);
        });

        // PRN / As Needed active medications
        final prnMedications = medications
            .where((m) => m.isActive && m.isAsNeeded)
            .toList();

        return logsAsync.when(
          data: (logs) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Adherence Dial Card
                  MedicationAdherenceCard(profileId: profileId),
                  const SizedBox(height: 24),

                  // 2. Scheduled Section
                  Row(
                    children: [
                      Icon(Icons.schedule, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Scheduled Today',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (tasks.isEmpty)
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No scheduled medications for today.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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

                        final isLowStock = med.trackInventory &&
                            med.stockQuantity <= med.lowStockThreshold;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isLowStock
                                  ? theme.colorScheme.error.withOpacity(0.4)
                                  : theme.colorScheme.outline.withOpacity(0.1),
                              width: isLowStock ? 1.5 : 1,
                            ),
                          ),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            secondary: SizedBox(
                              height: 36,
                              width: 36,
                              child: _getMedicationIcon(med.type),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    med.name,
                                    style: TextStyle(
                                      decoration: isTaken ? TextDecoration.lineThrough : null,
                                      color: isTaken ? Colors.grey : null,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isLowStock)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.warning, size: 10, color: theme.colorScheme.onErrorContainer),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Low Stock: ${med.stockQuantityFormatted}',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onErrorContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text('${med.dosage} at $timeFormatted'),
                            value: isTaken,
                            onChanged: (val) async {
                              final now = DateTime.now();
                              final targetTimestamp =
                                  DateTime(now.year, now.month, now.day, taskTime.hour, taskTime.minute);

                              if (val == true) {
                                if (med.dosage.trim().isEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => LogTrackedDoseDialog(
                                      profileId: profileId,
                                      medication: med,
                                      initialTimestamp: targetTimestamp,
                                    ),
                                  );
                                } else {
                                  final result = await ref
                                      .read(medicationLogsProvider(profileId).notifier)
                                      .addLog(
                                        MedicationLog(
                                          medicationId: med.id,
                                          timestamp: targetTimestamp,
                                          dosage: med.dosage,
                                        ),
                                      );
                                  if (result is Failure && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to update log: ${result.exception}')),
                                    );
                                  }
                                }
                              } else {
                                final result = await ref
                                    .read(medicationLogsProvider(profileId).notifier)
                                    .removeLog(
                                      med.id,
                                      targetTimestamp,
                                      time: taskTime,
                                    );
                                if (result is Failure && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update log: ${result.exception}')),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 28),

                  // 3. PRN Section
                  Row(
                    children: [
                      Icon(Icons.healing, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'As-Needed & Tracked',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (prnMedications.isEmpty)
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No tracked as-needed medications added.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: prnMedications.length,
                      itemBuilder: (ctx, index) {
                        final med = prnMedications[index];
                        final isLowStock = med.trackInventory &&
                            med.stockQuantity <= med.lowStockThreshold;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isLowStock
                                  ? theme.colorScheme.error.withOpacity(0.4)
                                  : theme.colorScheme.outline.withOpacity(0.1),
                              width: isLowStock ? 1.5 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 36,
                                  width: 36,
                                  child: _getMedicationIcon(med.type),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              med.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          if (isLowStock)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.errorContainer,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.warning, size: 10, color: theme.colorScheme.onErrorContainer),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'Low Stock: ${med.stockQuantityFormatted}',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: theme.colorScheme.onErrorContainer,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        med.trackInventory
                                            ? '${med.dosage} • Stock: ${med.stockQuantityFormatted} left'
                                            : med.dosage,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => LogTrackedDoseDialog(
                                        profileId: profileId,
                                        medication: med,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Log'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
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
