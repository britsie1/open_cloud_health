import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthicons_flutter/healthicons_flutter.dart';
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

class MedicationTodayTab extends ConsumerWidget {
  const MedicationTodayTab({super.key, required this.profileId});
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsProvider(profileId));
    final logsAsync = ref.watch(medicationLogsProvider(profileId));

    return medicationsAsync.when(
      data: (medications) {
        final activeMedications =
            medications.where((m) => m.isActive).toList();
        if (activeMedications.isEmpty) {
          return const Center(child: Text("No active medications for today."));
        }

        return logsAsync.when(
          data: (logs) {
            return ListView.builder(
              itemCount: activeMedications.length,
              itemBuilder: (ctx, index) {
                final med = activeMedications[index];
                final isTaken = logs.any((log) => log.medicationId == med.id);

                return CheckboxListTile(
                  secondary: SizedBox(height: 32, width: 32, child: _getMedicationIcon(med.type)),
                  title: Text(med.name),
                  subtitle: Text('${med.dosage} at ${med.timeFormatted}'),
                  value: isTaken,
                  onChanged: (val) async {
                    Result<void, Exception> result;
                    if (val == true) {
                      result = await ref
                          .read(medicationLogsProvider(profileId).notifier)
                          .addLog(
                            MedicationLog(
                              medicationId: med.id,
                              timestamp: DateTime.now(),
                            ),
                          );
                    } else {
                      result = await ref
                          .read(medicationLogsProvider(profileId).notifier)
                          .removeLog(
                            med.id,
                            DateTime.now(),
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
