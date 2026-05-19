import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/history_event.dart';
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
  String _searchQuery = '';
  Set<EventType> _selectedTypes = {EventType.manual, EventType.period, EventType.checkup};

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
          final filteredEvents = events.where((event) {
            if (!_selectedTypes.contains(event.eventType)) {
              return false;
            }
            final query = _searchQuery.toLowerCase();
            return event.title.toLowerCase().contains(query) ||
                event.description.toLowerCase().contains(query);
          }).toList();

          Widget content = const Center(
            child: Text('No events to display'),
          );

          if (filteredEvents.isNotEmpty) {
            content = Timeline.tileBuilder(
              theme: TimelineTheme.of(context).copyWith(
                nodePosition: 0,
              ),
              builder: TimelineTileBuilder.fromStyle(
                indicatorStyle: IndicatorStyle.outlined,
                contentsAlign: ContentsAlign.basic,
                contentsBuilder: (context, index) =>
                    HistoryEventCard(historyEvent: filteredEvents[index]),
                itemCount: filteredEvents.length,
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8.0,
                    children: EventType.values.map((type) {
                      return FilterChip(
                        label: Text(type.name.toUpperCase()),
                        selected: _selectedTypes.contains(type),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTypes.add(type);
                            } else {
                              _selectedTypes.remove(type);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
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
