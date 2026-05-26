import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';
import 'package:open_cloud_health/models/medication.dart';

class MedicationLogTab extends ConsumerStatefulWidget {
  const MedicationLogTab({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<MedicationLogTab> createState() => _MedicationLogTabState();
}

class _MedicationLogTabState extends ConsumerState<MedicationLogTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(allMedicationLogsProvider(widget.profileId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(allMedicationLogsProvider(widget.profileId));
    final medicationsAsync = ref.watch(medicationsProvider(widget.profileId));
    final hasMore = ref.watch(allMedicationLogsProvider(widget.profileId).notifier).hasMore;

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(child: Text('No medication logs found.'));
        }

        return medicationsAsync.when(
          data: (medications) {
            return ListView.builder(
              controller: _scrollController,
              itemCount: logs.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == logs.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final log = logs[index];
                
                Medication? medication;
                try {
                  medication = medications.firstWhere((m) => m.id == log.medicationId);
                } catch (_) {}

                final medName = medication?.name ?? 'Deleted Medication';
                final dosageText = (log.dosage != null && log.dosage!.trim().isNotEmpty)
                    ? log.dosage!
                    : (medication?.dosage ?? '');

                return ListTile(
                  leading: Icon(
                    log.isTaken ? Icons.check_circle : Icons.cancel,
                    color: log.isTaken ? Colors.green : Colors.red,
                  ),
                  title: Text(medName),
                  subtitle: Text(
                    DateFormat('MMM d, y - h:mm a').format(log.timestamp),
                  ),
                  trailing: Text(dosageText),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
