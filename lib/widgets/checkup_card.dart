import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/providers/checkups_provider.dart';
import 'package:open_cloud_health/utils/icon_utils.dart';
import 'package:open_cloud_health/widgets/edit_checkup_dialog.dart';

class CheckupCard extends ConsumerWidget {
  const CheckupCard({
    super.key,
    required this.checkupWithStatus,
    required this.onLogPressed,
  });

  final CheckupWithStatus checkupWithStatus;
  final VoidCallback onLogPressed;

  void _openEditCheckup(BuildContext context, String profileId, String checkupId) {
    showDialog(
      context: context,
      builder: (ctx) => EditCheckupDialog(
        profileId: profileId,
        checkupId: checkupId,
      ),
    );
  }

  void _toggleActiveStatus(WidgetRef ref, String profileId, String checkupId, bool newStatus) async {
    await ref.read(checkupsProvider(profileId).notifier).updateCheckupSettings(
      checkupId: checkupId,
      frequencyInMonths: checkupWithStatus.checkup.frequencyInMonths,
      isCustomInterval: checkupWithStatus.checkup.isCustomInterval,
      isActive: newStatus,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkup = checkupWithStatus.checkup;
    final isOverdue = checkupWithStatus.isOverdue;
    final isActive = checkup.isActive;

    final color = !isActive
        ? Colors.grey.shade400
        : (isOverdue ? Colors.red : Colors.blue);

    final iconWidget = getCheckupIconWidget(
      checkup.iconName,
      checkupName: checkup.name,
      color: color,
      size: 28,
    );

    return GestureDetector(
      onTap: isActive ? onLogPressed : null,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.65,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: !isActive ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: !isActive ? Border.all(color: Colors.grey.shade200) : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
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
                child: Center(child: iconWidget),
              ),

              const SizedBox(width: 16),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkup.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: !isActive ? Colors.grey.shade600 : Colors.black,
                        decoration: !isActive ? TextDecoration.lineThrough : null,
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
                      !isActive
                          ? "INACTIVE"
                          : (isOverdue
                              ? "DUE NOW"
                              : "UPCOMING${checkupWithStatus.nextDueDate != null ? ' - ${DateFormat.yMMMd().format(checkupWithStatus.nextDueDate!)}' : ''}"),
                      style: TextStyle(
                        color: !isActive
                            ? Colors.grey.shade500
                            : (isOverdue ? Colors.red : Colors.orange),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right side (status badge + popup menu)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive && isOverdue)
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
                  const SizedBox(height: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'log') {
                        onLogPressed();
                      } else if (value == 'edit') {
                        _openEditCheckup(context, checkup.profileId, checkup.id);
                      } else if (value == 'toggle') {
                        _toggleActiveStatus(ref, checkup.profileId, checkup.id, !isActive);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      if (isActive)
                        const PopupMenuItem<String>(
                          value: 'log',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text('Log Completion'),
                            ],
                          ),
                        ),
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text('Settings & Interval'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(isActive ? 'Deactivate & Hide' : 'Activate Checkup'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
