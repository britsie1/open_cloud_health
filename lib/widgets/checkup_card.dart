import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/providers/checkups_provider.dart';

IconData _getIconData(String? iconName) {
  switch (iconName) {
    case 'medical_services':
      return Icons.medical_services;
    case 'remove_red_eye':
      return Icons.remove_red_eye;
    case 'monitor_heart':
      return Icons.monitor_heart;
    case 'woman':
      return Icons.woman;
    case 'science':
      return Icons.science;
    case 'man':
      return Icons.man;
    case 'biotech':
      return Icons.biotech;
    case 'event':
      return Icons.event;
    case 'health_and_safety':
      return Icons.health_and_safety;
    case 'bloodtype':
      return Icons.bloodtype;
    case 'hearing':
      return Icons.hearing;
    case 'accessibility':
      return Icons.accessibility;
    default:
      return Icons.health_and_safety;
  }
}

class CheckupCard extends StatelessWidget {
  const CheckupCard({
    super.key,
    required this.checkupWithStatus,
    required this.onLogPressed,
    required this.onDeletePressed,
  });

  final CheckupWithStatus checkupWithStatus;
  final VoidCallback onLogPressed;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final checkup = checkupWithStatus.checkup;
    final isDueNow = checkupWithStatus.status == CheckupStatus.dueNow;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isDueNow ? 4 : 1,
      shape: RoundedRectangleBorder(
        side: isDueNow
            ? BorderSide(color: Theme.of(context).colorScheme.error, width: 2)
            : BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconData(checkup.iconName),
                  size: 32,
                  color: isDueNow ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checkup.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Every ${checkup.frequencyInMonths} months',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDeletePressed();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete Checkup'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isDueNow)
                      Text(
                        'DUE NOW',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (checkupWithStatus.nextDueDate != null)
                      Text(
                        'Next due: ${DateFormat.yMMMd().format(checkupWithStatus.nextDueDate!)}',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      ),
                    if (checkupWithStatus.latestLog != null)
                      Text(
                        'Last logged: ${DateFormat.yMMMd().format(checkupWithStatus.latestLog!.dateCompleted)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onLogPressed,
                  icon: const Icon(Icons.check),
                  label: const Text('Log'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDueNow ? Theme.of(context).colorScheme.errorContainer : null,
                    foregroundColor: isDueNow ? Theme.of(context).colorScheme.onErrorContainer : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
