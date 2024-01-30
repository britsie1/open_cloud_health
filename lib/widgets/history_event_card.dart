import 'package:flutter/material.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/screens/history_event_detail.dart';

class HistoryEventCard extends StatelessWidget {
  const HistoryEventCard({super.key, required this.historyEvent});

  final HistoryEvent historyEvent;

  void _openEventDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => HistoryEventDetailScreen(
          profileId: historyEvent.profileId,
          historyEvent: historyEvent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: Theme.of(context).colorScheme.background,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          onTap: () {
            _openEventDetail(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                historyEvent.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(historyEvent.formattedDate),
              const SizedBox(
                height: 10,
              ),
              Text(historyEvent.description)
            ]),
          ),
        ),
      ),
    );
  }
}
