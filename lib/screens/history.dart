import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/history_provider.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/utils/icon_utils.dart';
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
  final Set<EventType> _selectedTypes = {};

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
    final profilesAsync = ref.watch(profilesProvider);
    final profileId = widget.profileId ?? widget.profile?.id ?? _activeProfile?.id;
    
    final activeProfile = profilesAsync.maybeWhen(
      data: (profiles) {
        try {
          return profiles.firstWhere((p) => p.id == profileId);
        } catch (_) {
          return widget.profile ?? _activeProfile;
        }
      },
      orElse: () => widget.profile ?? _activeProfile,
    );

    if (activeProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final historyAsync = ref.watch(historyProvider(activeProfile.id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History'),
        actions: const [AccountAppBarActions()],
      ),
      floatingActionButton: activeProfile.isReadOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                context.push('${AppRoutes.historyDetail}/${activeProfile.id}');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
            ),
      body: historyAsync.when(
        data: (events) {
          final filteredEvents = events.where((event) {
            if (activeProfile.gender == Gender.male && event.eventType == EventType.period) {
              return false;
            }
            if (_selectedTypes.isNotEmpty && !_selectedTypes.contains(event.eventType)) {
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
              padding: const EdgeInsets.only(bottom: 96, top: 4),
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

          final availableTypes = EventType.values
              .where((type) => !(activeProfile.gender == Gender.male && type == EventType.period))
              .toList();
          final isAllSelected = _selectedTypes.isEmpty;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search events, notes, or doctors...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            showCheckmark: false,
                            avatar: Icon(
                              Icons.filter_list,
                              size: 16,
                              color: isAllSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            label: Text(
                              'All',
                              style: TextStyle(
                                fontWeight: isAllSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            selected: isAllSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedTypes.clear();
                              });
                            },
                          ),
                        ),
                        ...availableTypes.map((type) {
                          final isSelected = _selectedTypes.contains(type);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              showCheckmark: false,
                              avatar: SizedBox(
                                width: 18,
                                height: 18,
                                child: getHistoryEventIcon(
                                  type,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              label: Text(
                                type.displayName,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedTypes.add(type);
                                  } else {
                                    _selectedTypes.remove(type);
                                  }
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: content,
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
