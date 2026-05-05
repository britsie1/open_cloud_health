import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/providers/checkups_provider.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';
import 'package:open_cloud_health/widgets/add_custom_checkup_dialog.dart';
import 'package:open_cloud_health/widgets/checkup_card.dart';
import 'package:open_cloud_health/widgets/log_checkup_dialog.dart';
import 'package:open_cloud_health/widgets/main_drawer.dart';

class CheckupsScreen extends ConsumerWidget {
  const CheckupsScreen({super.key, required this.profileId});

  final String profileId;

  void _openAddCustomCheckup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AddCustomCheckupDialog(profileId: profileId),
    );
  }

  void _openLogCheckup(BuildContext context, String checkupId, String checkupName) {
    showDialog(
      context: context,
      builder: (ctx) => LogCheckupDialog(
        profileId: profileId,
        checkupId: checkupId,
        checkupName: checkupName,
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String checkupId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Checkup'),
        content: const Text('Are you sure you want to delete this checkup? This will also delete all its logs. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(checkupsProvider(profileId).notifier).deleteCheckup(checkupId);
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkupsAsync = ref.watch(checkupsProvider(profileId));

    return Scaffold(
      appBar: AppBar(
        actions: const [AccountAppBarActions()],
        title: const Text('Medical Checkups'),
      ),
      drawer: MainDrawer(profileId: profileId, currentRouteName: 'checkups'),
      body: checkupsAsync.when(
        data: (checkups) {
          if (checkups.isEmpty) {
            return const Center(child: Text('No checkups found.'));
          }

          return ListView.builder(
            itemCount: checkups.length,
            itemBuilder: (context, index) {
              final checkupWithStatus = checkups[index];
              return CheckupCard(
                checkupWithStatus: checkupWithStatus,
                onLogPressed: () => _openLogCheckup(
                  context,
                  checkupWithStatus.checkup.id,
                  checkupWithStatus.checkup.name,
                ),
                onDeletePressed: () => _confirmDelete(
                  context,
                  ref,
                  checkupWithStatus.checkup.id,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddCustomCheckup(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
