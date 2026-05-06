import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/history_provider.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/widgets/history_event_card.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';
import 'package:timelines/timelines.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.profile, this.profileId});

  final Profile? profile;
  final String? profileId;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  Profile? _activeProfile;

  void _initializeProfile() {
    Profile? profile = widget.profile;
    if (profile == null && widget.profileId != null) {
      profile = ref.read(profilesProvider.notifier).getProfile(widget.profileId!);
    }
    setState(() {
      _activeProfile = profile;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_activeProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final historyAsync = ref.watch(historyProvider(_activeProfile!.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History'),
        actions: const [AccountAppBarActions()],
      ),
      body: historyAsync.when(
        data: (events) {
          Widget content = const Center(
            child: Text('No events to display'),
          );

          if (events.isNotEmpty) {
            content = Timeline.tileBuilder(
              theme: TimelineTheme.of(context).copyWith(
                nodePosition: 0,
              ),
              builder: TimelineTileBuilder.fromStyle(
                indicatorStyle: IndicatorStyle.outlined,
                contentsAlign: ContentsAlign.basic,
                contentsBuilder: (context, index) =>
                    HistoryEventCard(historyEvent: events[index]),
                itemCount: events.length,
              ),
            );
          }

          return Column(
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
                    context.push('${AppRoutes.historyDetail}/${_activeProfile!.id}');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create event'),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
