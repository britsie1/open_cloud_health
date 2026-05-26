import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthicons_flutter/healthicons_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/utils/constants.dart';
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

class MedicationAllTab extends ConsumerWidget {
  const MedicationAllTab({super.key, required this.profileId});
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsProvider(profileId));

    return medicationsAsync.when(
      data: (medications) {
        if (medications.isEmpty) {
          return const Center(child: Text("No medications added yet."));
        }

        return ListView.builder(
          itemCount: medications.length,
          itemBuilder: (ctx, index) {
            final med = medications[index];
            return ListTile(
              leading: SizedBox(height: 32, width: 32, child: _getMedicationIcon(med.type)),
              title: Text(med.name),
              subtitle: Builder(
                builder: (context) {
                  final List<String> parts = [];
                  if (med.dosage.trim().isNotEmpty) {
                    parts.add(med.dosage);
                  }
                  if (med.isAsNeeded) {
                    parts.add('As needed');
                  } else {
                    parts.add(med.timeFormatted);
                  }
                  if (med.trackInventory) {
                    parts.add('Stock: ${med.stockQuantityFormatted}');
                  }
                  return Text(parts.join(' • '));
                },
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: med.isActive,
                    onChanged: (val) async {
                      final result = await ref
                          .read(medicationsProvider(profileId).notifier)
                          .toggleIsActive(med);

                      if (result is Failure && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Failed to update: ${result.exception}')),
                        );
                      }
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.push('${AppRoutes.medicationEditor}/$profileId', extra: med);
                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Medication'),
                            content: const Text(
                                'Are you sure you want to delete this medication? This will also remove its daily logs.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white),
                                onPressed: () async {
                                  final result = await ref
                                      .read(medicationsProvider(profileId)
                                          .notifier)
                                      .deleteMedication(med.id);

                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop();

                                    if (result is Failure && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Failed to delete: ${result.exception}')),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
