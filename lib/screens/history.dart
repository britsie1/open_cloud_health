import 'package:flutter/material.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/screens/history_event_detail.dart';
import 'package:open_cloud_health/widgets/history_event_card.dart';
import 'package:open_cloud_health/widgets/main_drawer.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';
import 'package:timelines/timelines.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.profile});

  final Profile profile;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History'),
        actions: const [AccountAppBarActions()],
      ),
      drawer: MainDrawer(
        profile: widget.profile,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Timeline.tileBuilder(
                theme: TimelineTheme.of(context).copyWith(
                  nodePosition: 0,
                ),
                builder: TimelineTileBuilder.fromStyle(
                  indicatorStyle: IndicatorStyle.outlined,
                  contentsAlign: ContentsAlign.basic,
                  contentsBuilder: (context, index) => const HistoryEventCard(),
                  itemCount: 20,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const HistoryEventDetailScreen(),
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
