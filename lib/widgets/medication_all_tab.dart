import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';
import 'package:open_cloud_health/utils/result.dart';
import 'package:open_cloud_health/widgets/medication_dialog.dart';

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
              title: Text(med.name),
              subtitle: Text('${med.dosage} - ${med.timeFormatted}'),
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
                        showDialog(
                          context: context,
                          builder: (ctx) => MedicationDialog(
                            profileId: profileId,
                            medication: med,
                          ),
                        );
                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Medication'),
                            content: const Text(
                                'Are you sure you want to delete this medication? This will also remove its daily logs.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
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

                                  if (context.mounted) {
                                    Navigator.of(context).pop();

                                    if (result is Failure) {
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
