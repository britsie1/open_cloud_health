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
          final activeCheckups = checkups.where((c) => c.checkup.isActive).toList();
          final inactiveCheckups = checkups.where((c) => !c.checkup.isActive).toList();

          final activeCount = activeCheckups.length;
          final inactiveCount = inactiveCheckups.length;

          if (activeCount == 0 && inactiveCount == 0) {
            return const Center(child: Text('No checkups found.'));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (activeCount == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No Active Checkups',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'All checkups are either completed, deactivated, or not applicable.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...activeCheckups.map((checkupWithStatus) {
                  return CheckupCard(
                    checkupWithStatus: checkupWithStatus,
                    onLogPressed: () => _openLogCheckup(
                      context,
                      checkupWithStatus.checkup.id,
                      checkupWithStatus.checkup.name,
                    ),
                  );
                }),

              if (inactiveCount > 0) ...[
                const SizedBox(height: 16),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Disabled Checkups ($inactiveCount)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    children: inactiveCheckups.map((checkupWithStatus) {
                      return CheckupCard(
                        checkupWithStatus: checkupWithStatus,
                        onLogPressed: () => _openLogCheckup(
                          context,
                          checkupWithStatus.checkup.id,
                          checkupWithStatus.checkup.name,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
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
