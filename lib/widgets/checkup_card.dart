import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/providers/checkups_provider.dart';
import 'package:open_cloud_health/utils/icon_utils.dart';

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
    final icon = getCheckupIcon(checkup.iconName);

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
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 12, color: Colors.red),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "Overdue",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
