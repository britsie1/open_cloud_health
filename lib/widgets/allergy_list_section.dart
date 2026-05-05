import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/providers/allergies_provider.dart';

class AllergyListSection extends ConsumerWidget {
  const AllergyListSection({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allergiesAsync = ref.watch(allergiesProvider(profileId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Allergies',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AddAllergyDialog(profileId: profileId),
                );
              },
              icon: const Icon(Icons.add),
            )
          ],
        ),
        const SizedBox(height: 10),
        allergiesAsync.when(
          data: (allergies) {
            if (allergies.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('No allergies added.'),
              );
            }
            return Column(
              children: allergies.map((allergy) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(allergy.name),
                  subtitle: allergy.note.isNotEmpty ? Text(allergy.note) : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Allergy'),
                          content: const Text(
                              'Are you sure you want to delete this allergy?'),
                          actions: [
                            TextButton(
                              onPressed: () => context.pop(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white),
                              onPressed: () {
                                ref
                                    .read(allergiesProvider(profileId).notifier)
                                    .deleteAllergy(allergy.id);
                                context.pop();
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
      ],
    );
  }
}

class AddAllergyDialog extends ConsumerStatefulWidget {
  const AddAllergyDialog({required this.profileId, super.key});
  final String profileId;

  @override
  ConsumerState<AddAllergyDialog> createState() => _AddAllergyDialogState();
}

class _AddAllergyDialogState extends ConsumerState<AddAllergyDialog> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    final newAllergy = Allergy(
      profileId: widget.profileId,
      name: _nameController.text.trim(),
      note: _noteController.text.trim(),
    );

    ref
        .read(allergiesProvider(widget.profileId).notifier)
        .addAllergy(newAllergy);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Allergy'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Allergy Name'),
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
