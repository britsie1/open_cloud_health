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
              Row(
                children: [
                  Flexible(
                    fit: FlexFit.tight,
                    flex: 1,
                    child: Text(
                      historyEvent.title,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (historyEvent.attachmentCount > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.attach_file, size: 18),
                      Text(
                        historyEvent.attachmentCount.toString(),
                      ),
                    ],
                  )
                ],
              ),
              Text(historyEvent.formattedDate),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 35,
                child: Text(
                  historyEvent.description,
                  overflow: TextOverflow.fade,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
