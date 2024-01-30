import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/history_provider.dart';
import 'package:open_cloud_health/screens/history_event_detail.dart';
import 'package:open_cloud_health/widgets/history_event_card.dart';
import 'package:open_cloud_health/widgets/main_drawer.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';
import 'package:timelines/timelines.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, required this.profile});

  final Profile profile;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {

  @override
  void initState() {
    super.initState();
    ref.read(historyProvider.notifier).loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(historyProvider);
    Widget content = const Center(child: Text('No events to display'),);

    if (events.isNotEmpty) {
      content = Timeline.tileBuilder(
        theme: TimelineTheme.of(context).copyWith(
          nodePosition: 0,
        ),
        builder: TimelineTileBuilder.fromStyle(
          indicatorStyle: IndicatorStyle.outlined,
          contentsAlign: ContentsAlign.basic,
          contentsBuilder: (context, index) => HistoryEventCard(historyEvent: events[index]),
          itemCount: events.length,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History'),
        actions: const [AccountAppBarActions()],
      ),
      drawer: MainDrawer(
        profileId: widget.profile.id,
        currentRouteName: 'history',
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: content),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => HistoryEventDetailScreen(profileId: widget.profile.id),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create event'),
            ),
          ),
        ],
      ),
    );
  }
}
