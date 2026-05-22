import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/utils/icon_utils.dart';

class HistoryEventCard extends StatelessWidget {
  const HistoryEventCard({super.key, required this.historyEvent});

  final HistoryEvent historyEvent;

  void _openEventDetail(BuildContext context) {
    if (historyEvent.eventType != EventType.period &&
        historyEvent.eventType != EventType.checkup) {
      context.push(
        '${AppRoutes.historyDetail}/${historyEvent.profileId}',
        extra: historyEvent,
      );
    } else {
      context.push(
        AppRoutes.historyReadonlyDetail,
        extra: historyEvent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openEventDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Type Icon Container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: getHistoryEventIcon(
                        historyEvent.eventType,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title & Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                historyEvent.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (historyEvent.attachmentCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.attach_file,
                                      size: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      historyEvent.attachmentCount.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Date/Time row
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              historyEvent.formattedDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        // Provider / Facility row if present
                        if (historyEvent.provider != null ||
                            historyEvent.facility != null) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              if (historyEvent.provider != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 14,
                                      color: primaryColor.withOpacity(0.8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      historyEvent.provider!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              if (historyEvent.facility != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_hospital_outlined,
                                      size: 14,
                                      color: primaryColor.withOpacity(0.8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      historyEvent.facility!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (historyEvent.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 8),
                Text(
                  historyEvent.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
