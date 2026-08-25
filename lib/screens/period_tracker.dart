import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:healthicons_flutter/healthicons_flutter.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/providers/period_provider.dart';
import 'package:open_cloud_health/widgets/symptom_button.dart';

class _PeriodGroup {
  DateTime startDate;
  DateTime endDate;
  final List<PeriodLog> logs;

  _PeriodGroup(this.startDate, this.endDate, this.logs);
}

class _LogDisplayItem {
  final bool isPeriod;
  final DateTime startDate;
  final DateTime endDate;
  final List<PeriodLog> logs;

  _LogDisplayItem.period({
    required this.startDate,
    required this.endDate,
    required this.logs,
  }) : isPeriod = true;

  _LogDisplayItem.symptom({
    required PeriodLog log,
  })  : isPeriod = false,
        startDate = log.date,
        endDate = log.date,
        logs = [log];
}

class PeriodTrackerScreen extends ConsumerStatefulWidget {
  const PeriodTrackerScreen({super.key, required this.profileId});
  final String profileId;

  @override
  ConsumerState<PeriodTrackerScreen> createState() =>
      _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends ConsumerState<PeriodTrackerScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  bool isFertileDay(DateTime day, PeriodState state) {
    if (!state.trackOvulation) return false;

    final allCycles = [
      if (state.currentCycle != null) state.currentCycle!,
      ...state.pastCycles,
    ];

    for (final cycle in allCycles) {
      final cycleLength = (cycle.cycleLength != null && cycle.cycleLength! > 0)
          ? cycle.cycleLength!
          : (state.averageCycleLength > 0 ? state.averageCycleLength : 28);

      final estimatedOvulationDay = cycleLength - 14;
      final fertileStartDay = (estimatedOvulationDay - 5).clamp(1, cycleLength);
      final fertileEndDay = estimatedOvulationDay.clamp(1, cycleLength);

      final cycleStart = DateTime(
          cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
      final fStart = cycleStart.add(Duration(days: fertileStartDay - 1));
      final fEnd = cycleStart.add(Duration(days: fertileEndDay - 1));

      final checkDay = DateTime(day.year, day.month, day.day);
      if (checkDay.compareTo(fStart) >= 0 && checkDay.compareTo(fEnd) <= 0) {
        return true;
      }
    }

    return false;
  }

  bool isLoggedDay(DateTime day, PeriodState state) {
    final log = state.allLogs.cast<PeriodLog?>().firstWhere(
          (log) => log != null && isSameDay(log.date, day),
          orElse: () => null,
        );
    return log != null && log.flowLevel != null;
  }

  bool hasSymptomsOnly(DateTime day, PeriodState state) {
    final log = state.allLogs.cast<PeriodLog?>().firstWhere(
          (log) => log != null && isSameDay(log.date, day),
          orElse: () => null,
        );
    return log != null &&
        log.flowLevel == null &&
        (log.moods.isNotEmpty || log.physicalSymptoms.isNotEmpty);
  }

  PeriodCycle? _findCycleForDate(DateTime date, PeriodState state) {
    final allCycles = [
      if (state.currentCycle != null) state.currentCycle!,
      ...state.pastCycles,
    ]..sort((a, b) => a.startDate.compareTo(b.startDate));

    if (allCycles.isEmpty) return null;

    final cleanDate = DateTime(date.year, date.month, date.day);
    PeriodCycle? matching;
    for (final c in allCycles) {
      final start =
          DateTime(c.startDate.year, c.startDate.month, c.startDate.day);
      if (!cleanDate.isBefore(start)) {
        if (c.endDate == null) {
          matching = c;
          break;
        }
        final end = DateTime(c.endDate!.year, c.endDate!.month, c.endDate!.day);
        if (!cleanDate.isAfter(end)) {
          matching = c;
          break;
        }
        matching = c;
      }
    }
    return matching ?? allCycles.first;
  }

  @override
  Widget build(BuildContext context) {
    final periodStateAsync = ref.watch(periodProvider(widget.profileId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Period Tracker'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Calendar'),
              Tab(text: 'Log'),
            ],
          ),
        ),
        body: periodStateAsync.when(
          data: (state) {
            final primaryColor = Theme.of(context).colorScheme.primary;
            final loggedColor = Colors.pink[200]!;
            final fertileColor = Colors.teal[100]!;
            final predictedColor = Colors.purple[200]!;

            return TabBarView(
              children: [
                SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildCalendar(state, primaryColor, loggedColor,
                            fertileColor, predictedColor),
                        const SizedBox(height: 16),
                        _legend(state, primaryColor, loggedColor, fertileColor,
                            predictedColor),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (state.currentCycle == null)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    'Select a day and log your flow to start your first cycle.',
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),
                              _buildContextualMessage(state),
                              const SizedBox(height: 16),
                              _buildDayDetails(state),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildLogTab(),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildLogTab() {
    final allLogsAsync = ref.watch(allPeriodLogsProvider(widget.profileId));

    return allLogsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(child: Text('No logs found.'));
        }

        final List<_LogDisplayItem> items = [];
        final flowLogs = logs.where((l) => l.flowLevel != null).toList();
        final symptomLogs = logs
            .where((l) =>
                l.flowLevel == null &&
                (l.moods.isNotEmpty || l.physicalSymptoms.isNotEmpty))
            .toList();

        _PeriodGroup? currentGroup;
        for (var log in flowLogs) {
          if (currentGroup == null) {
            currentGroup = _PeriodGroup(log.date, log.date, [log]);
          } else {
            final diff = currentGroup.startDate.difference(log.date).inDays;
            if (diff == 1 || diff == 0) {
              currentGroup.startDate = log.date;
              currentGroup.logs.add(log);
            } else {
              items.add(_LogDisplayItem.period(
                startDate: currentGroup.startDate,
                endDate: currentGroup.endDate,
                logs: currentGroup.logs,
              ));
              currentGroup = _PeriodGroup(log.date, log.date, [log]);
            }
          }
        }
        if (currentGroup != null) {
          items.add(_LogDisplayItem.period(
            startDate: currentGroup.startDate,
            endDate: currentGroup.endDate,
            logs: currentGroup.logs,
          ));
        }

        for (var log in symptomLogs) {
          items.add(_LogDisplayItem.symptom(log: log));
        }

        items.sort((a, b) => b.startDate.compareTo(a.startDate));

        if (items.isEmpty) {
          return const Center(child: Text('No period or symptom logs found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final title = item.isPeriod ? 'Period' : 'Symptoms Logged';
            final dateRangeStr = item.startDate == item.endDate
                ? DateFormat.yMMMd().format(item.startDate)
                : '${DateFormat.yMMMd().format(item.startDate)} - ${DateFormat.yMMMd().format(item.endDate)}';

            final icons = <Widget>[];
            for (var log in item.logs) {
              if (log.flowLevel != null) {
                icons.add(const Icon(Icons.water_drop,
                    color: Colors.redAccent, size: 20));
              }
              for (var s in log.physicalSymptoms) {
                icons.add(SizedBox(
                    width: 20,
                    height: 20,
                    child: _getPhysicalIcon(s)(
                        Theme.of(context).colorScheme.outline)));
              }
              for (var m in log.moods) {
                icons.add(SizedBox(
                    width: 20,
                    height: 20,
                    child: _getMoodIcon(m)(
                        Theme.of(context).colorScheme.outline)));
              }
            }

            return Card(
              color: Theme.of(context).colorScheme.background,
              child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                onTap: () {
                  setState(() {
                    _selectedDay = item.startDate;
                    _focusedDay = item.startDate;
                  });
                  DefaultTabController.of(context).animateTo(0);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(dateRangeStr),
                      if (icons.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: icons),
                      ]
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildCalendar(PeriodState state, Color primaryColor,
      Color loggedColor, Color fertileColor, Color predictedColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCalendarHeader(context),
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          headerVisible: false,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            todayDecoration: const BoxDecoration(),
            selectedDecoration: const BoxDecoration(),
            selectedTextStyle:
                TextStyle(color: Theme.of(context).colorScheme.onSurface),
            defaultTextStyle:
                TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) => _calendarDayBuilder(
                context,
                day,
                state,
                primaryColor,
                loggedColor,
                fertileColor,
                predictedColor,
                isSelected: false,
                isToday: false),
            todayBuilder: (context, day, focusedDay) => _calendarDayBuilder(
                context,
                day,
                state,
                primaryColor,
                loggedColor,
                fertileColor,
                predictedColor,
                isSelected: false,
                isToday: true),
            selectedBuilder: (context, day, focusedDay) => _calendarDayBuilder(
                context,
                day,
                state,
                primaryColor,
                loggedColor,
                fertileColor,
                predictedColor,
                isSelected: true,
                isToday: isSameDay(day, DateTime.now())),
            outsideBuilder: (context, day, focusedDay) => _calendarDayBuilder(
                context,
                day,
                state,
                primaryColor,
                loggedColor,
                fertileColor,
                predictedColor,
                isSelected: false,
                isToday: false,
                isOutside: true),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader(BuildContext context) {
    final monthFormat = DateFormat.yMMMM();
    final monthText = monthFormat.format(_focusedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(
                    _focusedDay.year, _focusedDay.month - 1, _focusedDay.day);
              });
            },
          ),
          Expanded(
            child: Semantics(
              header: true,
              label: monthText,
              child: Text(
                monthText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(
                    _focusedDay.year, _focusedDay.month + 1, _focusedDay.day);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _calendarDayBuilder(
      BuildContext context,
      DateTime day,
      PeriodState state,
      Color primaryColor,
      Color loggedColor,
      Color fertileColor,
      Color predictedColor,
      {required bool isSelected,
      required bool isToday,
      bool isOutside = false}) {
    final isFertile = isFertileDay(day, state);
    final isLogged = isLoggedDay(day, state);
    final hasSymptoms = hasSymptomsOnly(day, state);
    final isPredicted = state.expectedNextPeriodDate != null &&
        isSameDay(day, state.expectedNextPeriodDate);

    final isPrevFertile =
        isFertileDay(day.subtract(const Duration(days: 1)), state);
    final isNextFertile = isFertileDay(day.add(const Duration(days: 1)), state);

    final isPrevLogged =
        isLoggedDay(day.subtract(const Duration(days: 1)), state);
    final isNextLogged = isLoggedDay(day.add(const Duration(days: 1)), state);

    BoxDecoration? decoration;

    if (isLogged) {
      decoration = BoxDecoration(
          color: loggedColor,
          borderRadius: BorderRadius.horizontal(
            left: isPrevLogged ? Radius.zero : const Radius.circular(50),
            right: isNextLogged ? Radius.zero : const Radius.circular(50),
          ));
    } else if (isFertile) {
      decoration = BoxDecoration(
          color: fertileColor,
          borderRadius: BorderRadius.horizontal(
            left: isPrevFertile ? Radius.zero : const Radius.circular(50),
            right: isNextFertile ? Radius.zero : const Radius.circular(50),
          ));
    } else if (isPredicted) {
      decoration = BoxDecoration(
        color: predictedColor,
        shape: BoxShape.circle,
      );
    }

    final bool isContinuous = (isLogged && (isPrevLogged || isNextLogged)) ||
        (isFertile && (isPrevFertile || isNextFertile));

    return Container(
      margin: isContinuous
          ? const EdgeInsets.symmetric(vertical: 6)
          : const EdgeInsets.all(6),
      decoration: decoration,
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          border: isSelected ? Border.all(color: primaryColor, width: 2) : null,
          color: isToday ? primaryColor.withOpacity(0.3) : null,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isOutside
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight:
                    isToday || isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasSymptoms) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _legend(PeriodState state, Color primaryColor, Color loggedColor,
      Color fertileColor, Color predictedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          _legendItem("Logged", loggedColor),
          if (state.trackOvulation) ...[
            _legendItem("Fertile", fertileColor),
          ],
          _legendItem("Predicted", predictedColor),
          _legendItem("Symptoms", primaryColor, isDot: true),
          _legendItem("Selected", Colors.transparent,
              borderStyle: BorderStyle.solid, borderColor: primaryColor),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color,
      {bool isDot = false,
      BorderStyle borderStyle = BorderStyle.solid,
      Color? borderColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDot)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          )
        else
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              border: borderColor != null
                  ? Border.all(
                      color: borderColor,
                      style: borderStyle,
                    )
                  : null,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildContextualMessage(PeriodState state) {
    if (!state.trackOvulation) return const SizedBox();

    final today = DateTime.now();
    final isFertile = isFertileDay(today, state);
    final isPredicted = state.expectedNextPeriodDate != null &&
        today.compareTo(state.expectedNextPeriodDate!) <= 0 &&
        !isSameDay(today, state.expectedNextPeriodDate);

    String? message;
    if (isFertile) {
      message = "You are in your fertile stage.";
    } else if (isPredicted) {
      final daysTill = state.expectedNextPeriodDate!
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;
      message = "$daysTill days till your next period.";
    }

    if (message == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }

  Widget _buildDayDetails(PeriodState state) {
    if (_selectedDay == null) return const SizedBox();

    final logForDate = state.allLogs.cast<PeriodLog?>().firstWhere(
          (log) => log != null && isSameDay(log.date, _selectedDay!),
          orElse: () => null,
        );

    final matchingCycle = _findCycleForDate(_selectedDay!, state);
    final targetCycleId = logForDate?.cycleId ??
        matchingCycle?.id ??
        state.currentCycle?.id ??
        '';

    DateTime? blockStart;
    DateTime? blockEnd;
    if (logForDate?.flowLevel != null) {
      var curr = _selectedDay!;
      while (true) {
        final prev = curr.subtract(const Duration(days: 1));
        if (isLoggedDay(prev, state)) {
          curr = prev;
        } else {
          break;
        }
      }
      blockStart = curr;

      curr = _selectedDay!;
      while (true) {
        final next = curr.add(const Duration(days: 1));
        if (isLoggedDay(next, state)) {
          curr = next;
        } else {
          break;
        }
      }
      blockEnd = curr;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (logForDate?.flowLevel == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(periodProvider(widget.profileId).notifier)
                      .startNewCycle(_selectedDay!);
                },
                icon: const Icon(Icons.add),
                label: const Text('I got my period'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[100],
                  foregroundColor: Colors.pink[900],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        Text(
          DateFormat.yMMMd().format(_selectedDay!),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (blockStart != null && blockEnd != null) ...[
          OutlinedButton.icon(
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(
                  'Period Dates: ${DateFormat.MMMd().format(blockStart)} - ${DateFormat.MMMd().format(blockEnd)}'),
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange:
                      DateTimeRange(start: blockStart!, end: blockEnd!),
                );

                if (range != null &&
                    (range.start != blockStart || range.end != blockEnd)) {
                  final notifier =
                      ref.read(periodProvider(widget.profileId).notifier);
                  final cycleId = targetCycleId.isNotEmpty
                      ? targetCycleId
                      : (state.currentCycle?.id ?? '');

                  final oldDays = <DateTime>{};
                  var c = blockStart;
                  while (c.compareTo(blockEnd) <= 0) {
                    oldDays.add(DateTime(c.year, c.month, c.day));
                    c = c.add(const Duration(days: 1));
                  }

                  final newDays = <DateTime>{};
                  c = range.start;
                  while (c.compareTo(range.end) <= 0) {
                    newDays.add(DateTime(c.year, c.month, c.day));
                    c = c.add(const Duration(days: 1));
                  }

                  for (var log in state.allLogs) {
                    if (log.flowLevel != null) {
                      final lDate =
                          DateTime(log.date.year, log.date.month, log.date.day);
                      if (oldDays.contains(lDate) && !newDays.contains(lDate)) {
                        final updatedLog = PeriodLog(
                          id: log.id,
                          cycleId: log.cycleId,
                          date: log.date,
                          flowLevel: null,
                          moods: log.moods,
                          physicalSymptoms: log.physicalSymptoms,
                        );
                        await notifier.logSymptom(updatedLog);
                      }
                    }
                  }

                  for (var day in newDays) {
                    if (!oldDays.contains(day)) {
                      final newLog = PeriodLog(
                        cycleId: cycleId,
                        date: day,
                        flowLevel: FlowLevel.medium,
                      );
                      await notifier.logSymptom(newLog);
                    }
                  }
                }
              }),
          const SizedBox(height: 16),
        ],
        Text('Flow', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FlowLevel.values.map((flow) {
            final isSelected = logForDate?.flowLevel == flow;
            return SymptomButton(
              iconBuilder: (c) => Icon(Icons.water_drop,
                  color: c, size: 16.0 + (flow.index * 4.0)),
              label: flow.name.capitalize(),
              isSelected: isSelected,
              onTap: () {
                final newLog = PeriodLog(
                  id: logForDate?.id,
                  cycleId: targetCycleId,
                  date: _selectedDay!,
                  flowLevel: isSelected ? null : flow,
                  moods: logForDate?.moods ?? [],
                  physicalSymptoms: logForDate?.physicalSymptoms ?? [],
                );
                ref
                    .read(periodProvider(widget.profileId).notifier)
                    .logSymptom(newLog);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('Physical', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PhysicalSymptom.values.map((symptom) {
            final isSelected =
                logForDate?.physicalSymptoms.contains(symptom) ?? false;
            return SymptomButton(
              iconBuilder: _getPhysicalIcon(symptom),
              label: _formatSymptomName(symptom.name),
              isSelected: isSelected,
              onTap: () {
                List<PhysicalSymptom> updated =
                    List.from(logForDate?.physicalSymptoms ?? []);
                if (isSelected) {
                  updated.remove(symptom);
                } else {
                  updated.add(symptom);
                }

                final newLog = PeriodLog(
                  id: logForDate?.id,
                  cycleId: targetCycleId,
                  date: _selectedDay!,
                  flowLevel: logForDate?.flowLevel,
                  moods: logForDate?.moods ?? [],
                  physicalSymptoms: updated,
                );
                ref
                    .read(periodProvider(widget.profileId).notifier)
                    .logSymptom(newLog);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('Mood', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Mood.values.map((mood) {
            final isSelected = logForDate?.moods.contains(mood) ?? false;
            return SymptomButton(
              iconBuilder: _getMoodIcon(mood),
              label: mood.name.capitalize(),
              isSelected: isSelected,
              onTap: () {
                List<Mood> updated = List.from(logForDate?.moods ?? []);
                if (isSelected) {
                  updated.remove(mood);
                } else {
                  updated.add(mood);
                }

                final newLog = PeriodLog(
                  id: logForDate?.id,
                  cycleId: targetCycleId,
                  date: _selectedDay!,
                  flowLevel: logForDate?.flowLevel,
                  moods: updated,
                  physicalSymptoms: logForDate?.physicalSymptoms ?? [],
                );
                ref
                    .read(periodProvider(widget.profileId).notifier)
                    .logSymptom(newLog);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget Function(Color) _getPhysicalIcon(PhysicalSymptom s) {
    switch (s) {
      case PhysicalSymptom.cramps:
        return (c) => Stomach(color: c, width: 24, height: 24);
      case PhysicalSymptom.headache:
        return (c) => Headache(color: c, width: 24, height: 24);
      case PhysicalSymptom.bloating:
        return (c) => Weight(color: c, width: 24, height: 24);
      case PhysicalSymptom.breastTenderness:
        return (c) => Breasts(color: c, width: 24, height: 24);
    }
  }

  Widget Function(Color) _getMoodIcon(Mood m) {
    switch (m) {
      case Mood.happy:
        return (c) => Happy(color: c, width: 24, height: 24);
      case Mood.calm:
        return (c) => Calm(color: c, width: 24, height: 24);
      case Mood.irritable:
        return (c) => Angry(color: c, width: 24, height: 24);
      case Mood.sad:
        return (c) => Sad(color: c, width: 24, height: 24);
      case Mood.anxious:
        return (c) => Nervous(color: c, width: 24, height: 24);
    }
  }

  String _formatSymptomName(String name) {
    if (name == 'breastTenderness') return 'Tender\nBreasts';
    return name.capitalize();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
