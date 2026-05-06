import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/providers/checkups_provider.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';
import 'package:open_cloud_health/widgets/add_custom_checkup_dialog.dart';
import 'package:open_cloud_health/widgets/checkup_card.dart';
import 'package:open_cloud_health/widgets/log_checkup_dialog.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkupsAsync = ref.watch(checkupsProvider(profileId));

    return Scaffold(
      appBar: AppBar(
        actions: const [AccountAppBarActions()],
        title: const Text('Medical Checkups'),
      ),
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
