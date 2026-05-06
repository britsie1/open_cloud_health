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
  });

  final CheckupWithStatus checkupWithStatus;
  final VoidCallback onLogPressed;

  @override
  Widget build(BuildContext context) {
    final checkup = checkupWithStatus.checkup;
    final isOverdue = checkupWithStatus.isOverdue;
    final color = isOverdue ? Colors.red : Colors.blue;
    final icon = _getIconData(checkup.iconName);

    return GestureDetector(
      onTap: onLogPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon bubble
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),

            const SizedBox(width: 16),

            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checkup.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Every ${checkup.frequencyInMonths} months',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Status
                  Text(
                    isOverdue
                        ? "DUE NOW"
                        : "UPCOMING${checkupWithStatus.nextDueDate != null ? ' - ${DateFormat.yMMMd().format(checkupWithStatus.nextDueDate!)}' : ''}",
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right side (status badge + arrow)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 14, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          "Overdue",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
