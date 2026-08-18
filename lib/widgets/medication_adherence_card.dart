import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';

class MedicationAdherenceCard extends ConsumerWidget {
  final String profileId;

  const MedicationAdherenceCard({
    super.key,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adherenceAsync = ref.watch(medicationAdherenceProvider(profileId));
    final theme = Theme.of(context);

    return adherenceAsync.when(
      data: (data) {
        final percentage = (data.adherenceRate * 100).toInt();
        
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer.withOpacity(0.2),
                  theme.colorScheme.surface,
                ],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Medication Adherence',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (data.streakDays > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '🔥 ',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              '${data.streakDays} Day Streak',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Circular Dial
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              value: data.adherenceRate,
                              strokeWidth: 7,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              color: theme.colorScheme.primary,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                '$percentage%',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 7-day checklist
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: data.dailyAdherence.map((day) {
                            final label = _getDayLabel(day.date.weekday);
                            final isToday = _isSameDay(day.date, DateTime.now());
                            
                            Color iconColor;
                            IconData iconData;
                            BoxDecoration decoration;

                            if (day.expected == 0) {
                              iconColor = theme.colorScheme.outline.withOpacity(0.3);
                              iconData = Icons.remove;
                              decoration = BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(0.3),
                                  width: 1,
                                ),
                              );
                            } else if (day.isPerfect) {
                              iconColor = Colors.green;
                              iconData = Icons.check;
                              decoration = BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.withOpacity(0.15),
                              );
                            } else {
                              iconColor = theme.colorScheme.error;
                              iconData = Icons.close;
                              decoration = BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.error.withOpacity(0.15),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0),
                              child: Column(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: decoration,
                                    child: Center(
                                      child: Icon(
                                        iconData,
                                        size: 16,
                                        color: iconColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    label,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                      color: isToday
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => Card(
        child: SizedBox(
          height: 140,
          child: Center(child: Text('Failed to load adherence data: $err')),
        ),
      ),
    );
  }

  String _getDayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return 'M';
      case 2:
        return 'T';
      case 3:
        return 'W';
      case 4:
        return 'T';
      case 5:
        return 'F';
      case 6:
        return 'S';
      case 7:
        return 'S';
      default:
        return '';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
