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
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: medications.length,
          itemBuilder: (ctx, index) {
            final med = medications[index];
            final showLowStock = med.trackInventory && med.stockQuantity <= med.lowStockThreshold;
            return ListTile(
              onTap: () => context.push('${AppRoutes.medicationEditor}/$profileId', extra: med),
              leading: SizedBox(height: 32, width: 32, child: _getMedicationIcon(med.type)),
              title: Text(
                med.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: med.isActive ? null : Colors.grey,
                  decoration: med.isActive ? null : TextDecoration.lineThrough,
                ),
              ),
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(parts.join(' • ')),
                      if (med.trackInventory) ...[
                        const SizedBox(height: 4),
                        if (showLowStock)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red.shade900),
                                const SizedBox(width: 4),
                                Text(
                                  'Low Stock: ${med.stockQuantityFormatted}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            'Stock: ${med.stockQuantityFormatted}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: med.isActive,
                    onChanged: (val) async {
                      if (!val) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            title: Text('Pause ${med.name}?'),
                            content: const Text(
                              'Pausing this medication will turn off its daily schedule and reminders until you re-enable it.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogCtx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(dialogCtx).pop(true),
                                child: const Text('Pause'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                      }

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
