import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/providers/vitals_provider.dart';
import 'package:open_cloud_health/utils/bmi_calculator.dart';

class WeightHistoryList extends ConsumerWidget {
  const WeightHistoryList({
    super.key,
    required this.logs,
    required this.unit,
    required this.vitalsArgs,
    this.heightCm,
  });

  final List<VitalLog> logs;
  final String unit;
  final VitalsArgs vitalsArgs;
  final double? heightCm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No weight logs recorded yet.',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap the + button below to log your first entry.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Sort descending for history
    final sortedLogs = List<VitalLog>.from(logs)..sort((a, b) => b.date.compareTo(a.date));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: sortedLogs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, index) {
        final log = sortedLogs[index];

        // Delta vs previous older log (which is at index + 1 in descending list)
        double? delta;
        if (index + 1 < sortedLogs.length) {
          final olderLog = sortedLogs[index + 1];
          delta = log.value1 - olderLog.value1;
        }

        final bmi = (heightCm != null && heightCm! > 0)
            ? BmiCalculator.calculateBmiValue(log.value1, heightCm!)
            : null;

        return Dismissible(
          key: ValueKey(log.id),
          background: Container(
            color: Theme.of(context).colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Log?'),
                    content: Text('Remove entry for ${DateFormat('MMM d, y').format(log.date)}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (direction) {
            ref.read(vitalsProvider(vitalsArgs).notifier).deleteLog(log.id);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weight Icon badge
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.scale,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${log.value1.toStringAsFixed(1)} $unit',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (delta != null) ...[
                            const SizedBox(width: 8),
                            _DeltaBadge(delta: delta, unit: unit),
                          ],
                          if (bmi != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'BMI $bmi',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, y • h:mm a').format(log.date),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (log.note != null && log.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          log.note!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.delta, required this.unit});

  final double delta;
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (delta == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '0.0 $unit',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
        ),
      );
    }

    final isPositive = delta > 0;
    final color = isPositive ? Colors.orange.shade800 : Colors.green.shade700;
    final bgColor = isPositive ? Colors.orange.shade50 : Colors.green.shade50;
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        '$sign${delta.toStringAsFixed(1)} $unit',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
