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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final checkup = checkupWithStatus.checkup;
    final isOverdue = checkupWithStatus.isOverdue;
    final isActive = checkup.isActive;
    final hasBeenLogged = checkupWithStatus.latestLog != null;
    final isTrulyOverdue = isActive && isOverdue && hasBeenLogged;
    final isUnlogged = isActive && !hasBeenLogged;

    final color = !isActive
        ? Colors.grey.shade400
        : (isTrulyOverdue
            ? Colors.red
            : (isUnlogged ? theme.colorScheme.primary : Colors.teal));

    final iconWidget = getCheckupIconWidget(
      checkup.iconName,
      checkupName: checkup.name,
      color: color,
      size: 28,
    );

    final cardBgColor = !isActive
        ? (isDark ? const Color(0xFF181818) : Colors.grey.shade50)
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final cardBorderColor = isTrulyOverdue
        ? Colors.red.withOpacity(0.35)
        : (isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200);

    return GestureDetector(
      onTap: isActive ? onLogPressed : null,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.65,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorderColor),
            boxShadow: isActive && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
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
                  color: color.withOpacity(0.12),
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
                        color: !isActive
                            ? Colors.grey.shade500
                            : (isDark ? Colors.white : Colors.black87),
                        decoration: !isActive ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Every ${checkup.frequencyInMonths} months',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Actionable status / next due info
                    if (!isActive)
                      Text(
                        'Inactive',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      )
                    else if (isUnlogged)
                      Row(
                        children: [
                          Icon(Icons.add_circle_outline, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Tap to log last visit',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (isTrulyOverdue)
                      Text(
                        checkupWithStatus.nextDueDate != null
                            ? 'Due ${DateFormat.yMMMd().format(checkupWithStatus.nextDueDate!)} • Tap to log'
                            : 'Due now • Tap to log',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      )
                    else
                      Text(
                        checkupWithStatus.nextDueDate != null
                            ? 'Next due: ${DateFormat.yMMMd().format(checkupWithStatus.nextDueDate!)}'
                            : 'Up to date',
                        style: TextStyle(
                          color: isDark ? Colors.teal.shade300 : Colors.teal.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
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
                  if (isTrulyOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Overdue',
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
                    )
                  else if (isUnlogged)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Not logged yet',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 12,
                            color: isDark ? Colors.teal.shade300 : Colors.teal.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Up to date',
                            style: TextStyle(
                              color: isDark ? Colors.teal.shade300 : Colors.teal.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
