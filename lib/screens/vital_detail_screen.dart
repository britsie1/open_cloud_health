import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/providers/vitals_provider.dart';
import 'package:open_cloud_health/providers/weight_preferences_provider.dart';
import 'package:open_cloud_health/utils/result.dart';
import 'package:open_cloud_health/widgets/weight/bmi_summary_card.dart';
import 'package:open_cloud_health/widgets/weight/weight_chart_widget.dart';
import 'package:open_cloud_health/widgets/weight/weight_goal_card.dart';
import 'package:open_cloud_health/widgets/weight/weight_history_list.dart';

/// Clinical classification helper for Blood Pressure (AHA/ESC guidelines).
class BpCategoryInfo {
  final String label;
  final Color color;
  final String summary;

  const BpCategoryInfo({
    required this.label,
    required this.color,
    required this.summary,
  });

  static BpCategoryInfo classify(double systolic, double diastolic) {
    if (systolic < 90 || diastolic < 60) {
      return BpCategoryInfo(
        label: 'Low',
        color: Colors.blue.shade700,
        summary: 'Below 90/60 mmHg',
      );
    }
    if (systolic < 120 && diastolic < 80) {
      return BpCategoryInfo(
        label: 'Normal',
        color: Colors.teal.shade700,
        summary: 'Optimal (< 120/80 mmHg)',
      );
    }
    if (systolic < 130 && diastolic < 80) {
      return BpCategoryInfo(
        label: 'Elevated',
        color: Colors.amber.shade800,
        summary: '120–129 / < 80 mmHg',
      );
    }
    if (systolic < 140 || (diastolic >= 80 && diastolic < 90)) {
      if (systolic >= 140 || diastolic >= 90) {
        return BpCategoryInfo(
          label: 'Stage 2 High',
          color: Colors.red.shade700,
          summary: '140/90 mmHg or higher',
        );
      }
      return BpCategoryInfo(
        label: 'Stage 1 High',
        color: Colors.deepOrange.shade700,
        summary: '130–139 / 80–89 mmHg',
      );
    }
    return BpCategoryInfo(
      label: 'Stage 2 High',
      color: Colors.red.shade700,
      summary: '140/90 mmHg or higher',
    );
  }
}

/// Clinical classification helper for Blood Glucose (ADA guidelines).
class GlucoseCategoryInfo {
  final String label;
  final Color color;
  final bool isFastingContext;

  const GlucoseCategoryInfo({
    required this.label,
    required this.color,
    required this.isFastingContext,
  });

  static bool isFastingNote(String? note) {
    if (note == null || note.isEmpty) return false;
    final lower = note.toLowerCase();
    return lower.contains('fasting') || lower.contains('before meal') || lower.contains('waking');
  }

  static bool isPostMealNote(String? note) {
    if (note == null || note.isEmpty) return false;
    final lower = note.toLowerCase();
    return lower.contains('post-meal') || lower.contains('after meal') || lower.contains('2h') || lower.contains('postprandial');
  }

  static GlucoseCategoryInfo classify(double mgDl, {String? note}) {
    final fasting = isFastingNote(note);
    if (mgDl < 70) {
      return GlucoseCategoryInfo(
        label: 'Low',
        color: Colors.blue.shade700,
        isFastingContext: fasting,
      );
    }
    if (fasting) {
      if (mgDl <= 99) {
        return GlucoseCategoryInfo(
          label: 'Normal Fasting',
          color: Colors.teal.shade700,
          isFastingContext: true,
        );
      }
      if (mgDl <= 125) {
        return GlucoseCategoryInfo(
          label: 'Elevated Fasting',
          color: Colors.amber.shade800,
          isFastingContext: true,
        );
      }
      return GlucoseCategoryInfo(
        label: 'High',
        color: Colors.red.shade700,
        isFastingContext: true,
      );
    } else {
      if (mgDl <= 140) {
        return GlucoseCategoryInfo(
          label: 'In Range',
          color: Colors.teal.shade700,
          isFastingContext: false,
        );
      }
      if (mgDl <= 180) {
        return GlucoseCategoryInfo(
          label: 'Elevated',
          color: Colors.amber.shade800,
          isFastingContext: false,
        );
      }
      return GlucoseCategoryInfo(
        label: 'High',
        color: Colors.red.shade700,
        isFastingContext: false,
      );
    }
  }
}

class VitalDetailScreen extends ConsumerStatefulWidget {
  const VitalDetailScreen({
    super.key,
    required this.profileId,
    required this.vitalType,
  });

  final String profileId;
  final VitalType vitalType;

  @override
  ConsumerState<VitalDetailScreen> createState() => _VitalDetailScreenState();
}

class _VitalDetailScreenState extends ConsumerState<VitalDetailScreen> {
  String get _title {
    switch (widget.vitalType) {
      case VitalType.bloodPressure:
        return 'Blood Pressure';
      case VitalType.weight:
        return 'Weight Tracker';
      case VitalType.bloodSugar:
        return 'Blood Sugar';
    }
  }

  String get _unit {
    switch (widget.vitalType) {
      case VitalType.bloodPressure:
        return 'mmHg';
      case VitalType.weight:
        return 'kg';
      case VitalType.bloodSugar:
        return 'mg/dL';
    }
  }

  String get _fabLabel {
    switch (widget.vitalType) {
      case VitalType.bloodPressure:
        return 'Log BP';
      case VitalType.weight:
        return 'Log Weight';
      case VitalType.bloodSugar:
        return 'Log Sugar';
    }
  }

  void _openAddVitalDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddVitalDialog(
        profileId: widget.profileId,
        vitalType: widget.vitalType,
        unit: _unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vitalsArgs = (profileId: widget.profileId, type: widget.vitalType);
    final vitalsAsync = ref.watch(vitalsProvider(vitalsArgs));
    final isWeight = widget.vitalType == VitalType.weight;
    final weightPrefsAsync = isWeight
        ? ref.watch(weightPreferencesProvider(widget.profileId))
        : null;
    final profilesAsync = isWeight ? ref.watch(profilesProvider) : null;
    final profile = profilesAsync?.value?.where((p) => p.id == widget.profileId).firstOrNull;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
              Tab(icon: Icon(Icons.show_chart), text: 'Trends'),
              Tab(icon: Icon(Icons.history), text: 'History'),
            ],
          ),
        ),
        body: vitalsAsync.when(
          data: (logs) {
            if (isWeight) {
              final prefs = weightPrefsAsync?.value ?? const WeightPreferences();
              final sortedAsc = List<VitalLog>.from(logs)..sort((a, b) => a.date.compareTo(b.date));
              final latestWeight = sortedAsc.isNotEmpty ? sortedAsc.last.value1 : null;
              final startWeight = sortedAsc.isNotEmpty ? sortedAsc.first.value1 : null;

              return TabBarView(
                children: [
                  _WeightOverviewTab(
                    profileId: widget.profileId,
                    logs: logs,
                    heightCm: prefs.heightCm,
                    targetWeightKg: prefs.targetWeightKg,
                    currentWeightKg: latestWeight,
                    startWeightKg: startWeight,
                    unit: _unit,
                    age: profile?.age,
                    gender: profile?.gender,
                    onOpenAddLog: _openAddVitalDialog,
                  ),
                  WeightChartWidget(
                    logs: logs,
                    unit: _unit,
                    heightCm: prefs.heightCm,
                    targetWeightKg: prefs.targetWeightKg,
                    onOpenAddLog: _openAddVitalDialog,
                  ),
                  WeightHistoryList(
                    logs: logs,
                    unit: _unit,
                    vitalsArgs: vitalsArgs,
                    heightCm: prefs.heightCm,
                  ),
                ],
              );
            }

            if (widget.vitalType == VitalType.bloodPressure) {
              return TabBarView(
                children: [
                  _BloodPressureOverviewTab(
                    logs: logs,
                    unit: _unit,
                    onOpenAddLog: _openAddVitalDialog,
                  ),
                  _VitalTrendsTab(
                    logs: logs,
                    vitalType: widget.vitalType,
                    unit: _unit,
                    onOpenAddLog: _openAddVitalDialog,
                  ),
                  _HistoryTab(
                    logs: logs,
                    vitalType: widget.vitalType,
                    unit: _unit,
                    vitalsArgs: vitalsArgs,
                  ),
                ],
              );
            }

            // Blood Sugar
            return TabBarView(
              children: [
                _BloodSugarOverviewTab(
                  logs: logs,
                  unit: _unit,
                  onOpenAddLog: _openAddVitalDialog,
                ),
                _VitalTrendsTab(
                  logs: logs,
                  vitalType: widget.vitalType,
                  unit: _unit,
                  onOpenAddLog: _openAddVitalDialog,
                ),
                _HistoryTab(
                  logs: logs,
                  vitalType: widget.vitalType,
                  unit: _unit,
                  vitalsArgs: vitalsArgs,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'vital_add_fab_${widget.vitalType.name}',
          onPressed: _openAddVitalDialog,
          icon: const Icon(Icons.add),
          label: Text(_fabLabel),
          tooltip: 'Log measurement entry',
        ),
      ),
    );
  }
}

// ============================================================================
// BLOOD PRESSURE OVERVIEW TAB
// ============================================================================

class _BloodPressureOverviewTab extends StatelessWidget {
  const _BloodPressureOverviewTab({
    required this.logs,
    required this.unit,
    required this.onOpenAddLog,
  });

  final List<VitalLog> logs;
  final String unit;
  final VoidCallback onOpenAddLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_outline, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              const Text(
                'No Blood Pressure Readings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Log your systolic and diastolic readings to see AHA classifications and averages.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onOpenAddLog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Blood Pressure'),
              ),
            ],
          ),
        ),
      );
    }

    final sortedAsc = List<VitalLog>.from(logs)..sort((a, b) => a.date.compareTo(b.date));
    final latest = sortedAsc.last;
    final sys = latest.value1;
    final dia = latest.value2 ?? 80.0;
    final pulsePressure = (sys - dia).round();
    final category = BpCategoryInfo.classify(sys, dia);

    final now = DateTime.now();
    final last7Days = sortedAsc.where((l) => now.difference(l.date).inDays <= 7).toList();
    final last30Days = sortedAsc.where((l) => now.difference(l.date).inDays <= 30).toList();

    final avg7Sys = last7Days.isEmpty
        ? sys.round()
        : (last7Days.map((l) => l.value1).reduce((a, b) => a + b) / last7Days.length).round();
    final avg7Dia = last7Days.isEmpty
        ? dia.round()
        : (last7Days.map((l) => l.value2 ?? 80.0).reduce((a, b) => a + b) / last7Days.length).round();

    final avg30Sys = last30Days.isEmpty
        ? sys.round()
        : (last30Days.map((l) => l.value1).reduce((a, b) => a + b) / last30Days.length).round();
    final avg30Dia = last30Days.isEmpty
        ? dia.round()
        : (last30Days.map((l) => l.value2 ?? 80.0).reduce((a, b) => a + b) / last30Days.length).round();

    final inTargetCount = sortedAsc.where((l) => l.value1 < 130 && (l.value2 ?? 80.0) < 80).length;
    final inTargetPct = ((inTargetCount / sortedAsc.length) * 100).round();

    // Morning vs Evening split
    final morningLogs = sortedAsc.where((l) {
      final n = l.note?.toLowerCase() ?? '';
      if (n.contains('morning')) return true;
      if (n.contains('evening') || n.contains('night')) return false;
      return l.date.hour < 12;
    }).toList();
    final eveningLogs = sortedAsc.where((l) => !morningLogs.contains(l)).toList();

    final recentLogsDesc = sortedAsc.reversed.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Latest Reading & AHA Spectrum
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.favorite_border, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Latest Reading',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d, y').format(latest.date),
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              Text(
                '${sys.toInt()}/${dia.toInt()} $unit',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              _StatusBadge(label: category.label, color: category.color),
              if (sortedAsc.length > 1) _buildBpDelta(sortedAsc),
            ],
          ),
          if (latest.note != null && latest.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              latest.note!,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 14),
          _BpSpectrumBar(systolic: sys, diastolic: dia),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                'Target: < 120/80 mmHg',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
              Text(
                'Pulse Pressure: $pulsePressure mmHg (${pulsePressure >= 35 && pulsePressure <= 55 ? "Normal" : "Monitor"})',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Section 2: Period Averages & Time in Target
          const Row(
            children: [
              Icon(Icons.analytics_outlined, size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Averages & Control',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OverviewKpiCard(
                label: '7-Day Avg',
                value: '$avg7Sys/$avg7Dia',
                subtitle: unit,
                color: BpCategoryInfo.classify(avg7Sys.toDouble(), avg7Dia.toDouble()).color,
              ),
              const SizedBox(width: 8),
              _OverviewKpiCard(
                label: '30-Day Avg',
                value: '$avg30Sys/$avg30Dia',
                subtitle: unit,
                color: BpCategoryInfo.classify(avg30Sys.toDouble(), avg30Dia.toDouble()).color,
              ),
              const SizedBox(width: 8),
              _OverviewKpiCard(
                label: 'In Target',
                value: '$inTargetPct%',
                subtitle: '$inTargetCount of ${sortedAsc.length} (<130/80)',
                color: inTargetPct >= 70 ? Colors.teal.shade700 : Colors.amber.shade800,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Morning vs Evening comparison
          Row(
            children: [
              Expanded(
                child: _TimeOfDayCard(
                  icon: Icons.wb_sunny_outlined,
                  iconColor: Colors.amber.shade700,
                  title: 'Morning Avg',
                  value: morningLogs.isEmpty
                      ? '—'
                      : '${(morningLogs.map((l) => l.value1).reduce((a, b) => a + b) / morningLogs.length).round()}/${(morningLogs.map((l) => l.value2 ?? 80).reduce((a, b) => a + b) / morningLogs.length).round()} $unit',
                  subtitle: '${morningLogs.length} reading${morningLogs.length == 1 ? '' : 's'}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TimeOfDayCard(
                  icon: Icons.nights_stay_outlined,
                  iconColor: Colors.indigo.shade400,
                  title: 'Evening Avg',
                  value: eveningLogs.isEmpty
                      ? '—'
                      : '${(eveningLogs.map((l) => l.value1).reduce((a, b) => a + b) / eveningLogs.length).round()}/${(eveningLogs.map((l) => l.value2 ?? 80).reduce((a, b) => a + b) / eveningLogs.length).round()} $unit',
                  subtitle: '${eveningLogs.length} reading${eveningLogs.length == 1 ? '' : 's'}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Section 3: Recent Readings Snapshot
          const Row(
            children: [
              Icon(Icons.history, size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Recent Readings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...recentLogsDesc.map((log) {
            final s = log.value1.toInt();
            final d = (log.value2 ?? 80).toInt();
            final cat = BpCategoryInfo.classify(log.value1, log.value2 ?? 80);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                '$s/$d $unit',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              _StatusBadge(label: cat.label, color: cat.color),
                            ],
                          ),
                          if (log.note != null && log.note!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              log.note!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('MMM d').format(log.date),
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBpDelta(List<VitalLog> sortedAsc) {
    final latest = sortedAsc.last;
    final prev = sortedAsc[sortedAsc.length - 2];
    final diffSys = (latest.value1 - prev.value1).round();
    final diffDia = ((latest.value2 ?? 80) - (prev.value2 ?? 80)).round();
    final isUp = diffSys > 0;
    final color = diffSys == 0
        ? Colors.grey.shade700
        : (isUp ? Colors.amber.shade900 : Colors.teal.shade700);
    final sysStr = '${diffSys >= 0 ? '+' : ''}$diffSys';
    final diaStr = '${diffDia >= 0 ? '+' : ''}$diffDia';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$sysStr/$diaStr $unit',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ============================================================================
// BLOOD SUGAR OVERVIEW TAB
// ============================================================================

class _BloodSugarOverviewTab extends StatelessWidget {
  const _BloodSugarOverviewTab({
    required this.logs,
    required this.unit,
    required this.onOpenAddLog,
  });

  final List<VitalLog> logs;
  final String unit;
  final VoidCallback onOpenAddLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water_drop_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              const Text(
                'No Blood Sugar Readings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Log fasting or post-meal glucose readings to track Time in Range and estimated A1C.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onOpenAddLog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Blood Sugar'),
              ),
            ],
          ),
        ),
      );
    }

    final sortedAsc = List<VitalLog>.from(logs)..sort((a, b) => a.date.compareTo(b.date));
    final latest = sortedAsc.last;
    final val = latest.value1;
    final category = GlucoseCategoryInfo.classify(val, note: latest.note);

    final now = DateTime.now();
    final last7Days = sortedAsc.where((l) => now.difference(l.date).inDays <= 7).toList();
    final last30Days = sortedAsc.where((l) => now.difference(l.date).inDays <= 30).toList();

    final avg7 = last7Days.isEmpty
        ? val.round()
        : (last7Days.map((l) => l.value1).reduce((a, b) => a + b) / last7Days.length).round();
    final avg30 = last30Days.isEmpty
        ? val.round()
        : (last30Days.map((l) => l.value1).reduce((a, b) => a + b) / last30Days.length).round();
    final overallAvg = sortedAsc.map((l) => l.value1).reduce((a, b) => a + b) / sortedAsc.length;

    // Nathan ADAG formula: eA1C (%) = (Average Glucose mg/dL + 46.7) / 28.7
    final estimatedA1c = (overallAvg + 46.7) / 28.7;

    // Time in Range (70 - 140 mg/dL tight target)
    final lowCount = sortedAsc.where((l) => l.value1 < 70).length;
    final inRangeCount = sortedAsc.where((l) => l.value1 >= 70 && l.value1 <= 140).length;
    final highCount = sortedAsc.where((l) => l.value1 > 140).length;
    final tirPct = ((inRangeCount / sortedAsc.length) * 100).round();

    // Fasting vs Post-meal split
    final fastingLogs = sortedAsc.where((l) => GlucoseCategoryInfo.isFastingNote(l.note)).toList();
    final postMealLogs = sortedAsc.where((l) => GlucoseCategoryInfo.isPostMealNote(l.note)).toList();

    final recentLogsDesc = sortedAsc.reversed.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Latest Glucose Reading
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.water_drop_outlined, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Latest Glucose',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d, y').format(latest.date),
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              Text(
                '${val.toInt()} $unit',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              _StatusBadge(label: category.label, color: category.color),
              if (sortedAsc.length > 1) _buildSugarDelta(sortedAsc),
            ],
          ),
          if (latest.note != null && latest.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              latest.note!,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 14),
          _GlucoseSpectrumBar(mgDl: val),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                'Fasting target: 70–99 mg/dL',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
              Text(
                '2h Post-meal: < 140 mg/dL',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Section 2: Time in Range & Estimated A1C
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.pie_chart_outline, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Time in Range & Est. A1C',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$tirPct% In Range',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: tirPct >= 70 ? Colors.teal.shade700 : Colors.amber.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Time in Range Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (lowCount > 0)
                    Expanded(
                      flex: lowCount,
                      child: Container(color: Colors.blue.shade400),
                    ),
                  if (inRangeCount > 0)
                    Expanded(
                      flex: inRangeCount,
                      child: Container(color: Colors.teal.shade500),
                    ),
                  if (highCount > 0)
                    Expanded(
                      flex: highCount,
                      child: Container(color: Colors.amber.shade600),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$inRangeCount of ${sortedAsc.length} readings between 70–140 mg/dL',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OverviewKpiCard(
                label: '7-Day Avg',
                value: '$avg7',
                subtitle: unit,
                color: GlucoseCategoryInfo.classify(avg7.toDouble()).color,
              ),
              const SizedBox(width: 8),
              _OverviewKpiCard(
                label: '30-Day Avg',
                value: '$avg30',
                subtitle: unit,
                color: GlucoseCategoryInfo.classify(avg30.toDouble()).color,
              ),
              const SizedBox(width: 8),
              _OverviewKpiCard(
                label: 'Est. A1C',
                value: '${estimatedA1c.toStringAsFixed(1)}%',
                subtitle: estimatedA1c < 5.7 ? 'Normal (<5.7%)' : (estimatedA1c < 6.5 ? 'Prediabetes' : 'Diabetes range'),
                color: estimatedA1c < 5.7 ? Colors.teal.shade700 : Colors.amber.shade800,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeOfDayCard(
                  icon: Icons.wb_twilight,
                  iconColor: Colors.teal.shade600,
                  title: 'Fasting Avg',
                  value: fastingLogs.isEmpty
                      ? '—'
                      : '${(fastingLogs.map((l) => l.value1).reduce((a, b) => a + b) / fastingLogs.length).round()} $unit',
                  subtitle: '${fastingLogs.length} reading${fastingLogs.length == 1 ? '' : 's'}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TimeOfDayCard(
                  icon: Icons.restaurant_outlined,
                  iconColor: Colors.orange.shade700,
                  title: 'Post-Meal Avg',
                  value: postMealLogs.isEmpty
                      ? '—'
                      : '${(postMealLogs.map((l) => l.value1).reduce((a, b) => a + b) / postMealLogs.length).round()} $unit',
                  subtitle: '${postMealLogs.length} reading${postMealLogs.length == 1 ? '' : 's'}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Section 3: Recent Readings Snapshot
          const Row(
            children: [
              Icon(Icons.history, size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Recent Readings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...recentLogsDesc.map((log) {
            final cat = GlucoseCategoryInfo.classify(log.value1, note: log.note);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                '${log.value1.toInt()} $unit',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              _StatusBadge(label: cat.label, color: cat.color),
                            ],
                          ),
                          if (log.note != null && log.note!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              log.note!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('MMM d').format(log.date),
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSugarDelta(List<VitalLog> sortedAsc) {
    final latest = sortedAsc.last.value1;
    final prev = sortedAsc[sortedAsc.length - 2].value1;
    final diff = (latest - prev).round();
    final isUp = diff > 0;
    final color = diff == 0
        ? Colors.grey.shade700
        : (isUp ? Colors.amber.shade900 : Colors.teal.shade700);
    final sign = isUp ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$sign$diff $unit',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ============================================================================
// WEIGHT OVERVIEW TAB
// ============================================================================

class _WeightOverviewTab extends StatelessWidget {
  const _WeightOverviewTab({
    required this.profileId,
    required this.logs,
    required this.heightCm,
    required this.targetWeightKg,
    required this.currentWeightKg,
    required this.startWeightKg,
    required this.unit,
    this.age,
    this.gender,
    required this.onOpenAddLog,
  });

  final String profileId;
  final List<VitalLog> logs;
  final double? heightCm;
  final double? targetWeightKg;
  final double? currentWeightKg;
  final double? startWeightKg;
  final String unit;
  final int? age;
  final Gender? gender;
  final VoidCallback onOpenAddLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.scale_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              const Text(
                'No Weight Entries',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Log your first entry to track BMI and trends.',
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onOpenAddLog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Weight'),
              ),
            ],
          ),
        ),
      );
    }

    final latestLog = logs.last;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.monitor_weight_outlined, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Current Weight',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d, y').format(latestLog.date),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                '${latestLog.value1.toStringAsFixed(1)} $unit',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              if (logs.length > 1) _buildRecentDelta(logs),
            ],
          ),
          if (latestLog.note != null && latestLog.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              latestLog.note!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          BmiSummaryCard(
            profileId: profileId,
            currentWeightKg: currentWeightKg,
            heightCm: heightCm,
            age: age,
            gender: gender,
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          WeightGoalCard(
            profileId: profileId,
            targetWeightKg: targetWeightKg,
            currentWeightKg: currentWeightKg,
            startWeightKg: startWeightKg,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDelta(List<VitalLog> logs) {
    final sorted = List<VitalLog>.from(logs)..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.length < 2) return const SizedBox.shrink();
    final latest = sorted.last.value1;
    final previous = sorted[sorted.length - 2].value1;
    final diff = latest - previous;

    final isPositive = diff > 0;
    final color = diff == 0
        ? Colors.grey.shade700
        : (isPositive ? Colors.amber.shade900 : Colors.teal.shade700);
    final bgColor = color.withOpacity(0.08);
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            diff == 0 ? Icons.remove : (isPositive ? Icons.arrow_upward : Icons.arrow_downward),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '$sign${diff.toStringAsFixed(1)} $unit',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TRENDS TAB FOR BLOOD PRESSURE & BLOOD SUGAR
// ============================================================================

class _VitalTrendsTab extends StatefulWidget {
  const _VitalTrendsTab({
    required this.logs,
    required this.vitalType,
    required this.unit,
    required this.onOpenAddLog,
  });

  final List<VitalLog> logs;
  final VitalType vitalType;
  final String unit;
  final VoidCallback onOpenAddLog;

  @override
  State<_VitalTrendsTab> createState() => _VitalTrendsTabState();
}

class _VitalTrendsTabState extends State<_VitalTrendsTab> {
  ChartTimeframe _selectedTimeframe = ChartTimeframe.oneMonth;

  ({DateTime startDate, DateTime endDate, List<VitalLog> logs}) _getTimeframeData() {
    if (widget.logs.isEmpty) {
      final now = DateTime.now();
      return (startDate: now.subtract(const Duration(days: 30)), endDate: now, logs: <VitalLog>[]);
    }

    final sorted = List<VitalLog>.from(widget.logs)..sort((a, b) => a.date.compareTo(b.date));
    final now = DateTime.now();
    final endDate = now;

    if (_selectedTimeframe.duration != null) {
      final startDate = now.subtract(_selectedTimeframe.duration!);
      final filtered = sorted.where((l) => !l.date.isBefore(startDate) && !l.date.isAfter(endDate)).toList();
      return (startDate: startDate, endDate: endDate, logs: filtered);
    } else {
      return (startDate: sorted.first.date, endDate: endDate, logs: sorted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBP = widget.vitalType == VitalType.bloodPressure;
    final tfData = _getTimeframeData();
    final filteredLogs = tfData.logs;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeframe Selector Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: ChartTimeframe.values.map((tf) {
                final isSelected = tf == _selectedTimeframe;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: ChoiceChip(
                      showCheckmark: false,
                      labelPadding: EdgeInsets.zero,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      label: Center(
                        child: Text(
                          tf.label,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTimeframe = tf;
                          });
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (filteredLogs.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No readings in the last ${_selectedTimeframe.label}.',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Switch to "All" or tap below to log a new measurement.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            _buildKpiRow(filteredLogs, theme, isBP),
            const SizedBox(height: 16),
            Container(
              height: 270,
              padding: const EdgeInsets.only(right: 24, left: 12, top: 16, bottom: 8),
              child: _buildLineChart(
                filteredLogs,
                tfData.startDate,
                tfData.endDate,
                theme,
                isBP,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 6,
                children: isBP
                    ? [
                        _ChartLegendDot(color: theme.colorScheme.primary, label: 'Systolic (Upper)'),
                        _ChartLegendDot(color: Colors.teal.shade600, label: 'Diastolic (Lower)'),
                        _ChartLegendDot(
                          color: Colors.amber.shade800,
                          label: 'Normal Limit (120/80 mmHg)',
                          isDashed: true,
                        ),
                      ]
                    : [
                        _ChartLegendDot(color: theme.colorScheme.primary, label: 'Blood Glucose (${widget.unit})'),
                        _ChartLegendDot(
                          color: Colors.teal.shade700,
                          label: 'Target Upper (140 ${widget.unit})',
                          isDashed: true,
                        ),
                      ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiRow(List<VitalLog> logs, ThemeData theme, bool isBP) {
    if (isBP) {
      final avgSys = (logs.map((l) => l.value1).reduce((a, b) => a + b) / logs.length).round();
      final avgDia = (logs.map((l) => l.value2 ?? 80).reduce((a, b) => a + b) / logs.length).round();
      final minSys = logs.map((l) => l.value1).reduce((a, b) => a < b ? a : b).round();
      final maxSys = logs.map((l) => l.value1).reduce((a, b) => a > b ? a : b).round();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          children: [
            _OverviewKpiCard(
              label: 'Average (${_selectedTimeframe.label})',
              value: '$avgSys/$avgDia',
              subtitle: widget.unit,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            _OverviewKpiCard(
              label: 'Lowest Sys',
              value: '$minSys',
              subtitle: widget.unit,
              color: Colors.teal.shade700,
            ),
            const SizedBox(width: 8),
            _OverviewKpiCard(
              label: 'Highest Sys',
              value: '$maxSys',
              subtitle: widget.unit,
              color: maxSys >= 130 ? Colors.deepOrange.shade700 : Colors.grey.shade800,
            ),
          ],
        ),
      );
    } else {
      final avg = (logs.map((l) => l.value1).reduce((a, b) => a + b) / logs.length).round();
      final minVal = logs.map((l) => l.value1).reduce((a, b) => a < b ? a : b).round();
      final maxVal = logs.map((l) => l.value1).reduce((a, b) => a > b ? a : b).round();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          children: [
            _OverviewKpiCard(
              label: 'Average (${_selectedTimeframe.label})',
              value: '$avg',
              subtitle: widget.unit,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            _OverviewKpiCard(
              label: 'Lowest',
              value: '$minVal',
              subtitle: widget.unit,
              color: Colors.teal.shade700,
            ),
            const SizedBox(width: 8),
            _OverviewKpiCard(
              label: 'Highest',
              value: '$maxVal',
              subtitle: widget.unit,
              color: maxVal > 140 ? Colors.amber.shade800 : Colors.grey.shade800,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLineChart(
    List<VitalLog> logs,
    DateTime startDate,
    DateTime endDate,
    ThemeData theme,
    bool isBP,
  ) {
    final firstDate = logs.first.date;
    final totalDays = logs.last.date.difference(firstDate).inHours / 24.0;
    final maxX = totalDays < 1.0 ? 1.0 : totalDays;
    const minX = 0.0;

    final spots1 = <FlSpot>[];
    final spots2 = <FlSpot>[];

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final log in logs) {
      final x = (log.date.difference(firstDate).inHours / 24.0).clamp(minX, maxX);
      spots1.add(FlSpot(x, log.value1));
      if (log.value1 < minY) minY = log.value1;
      if (log.value1 > maxY) maxY = log.value1;

      if (isBP && log.value2 != null) {
        spots2.add(FlSpot(x, log.value2!));
        if (log.value2! < minY) minY = log.value2!;
        if (log.value2! > maxY) maxY = log.value2!;
      }
    }

    // Round Y-axis bounds to clean multiples of 10 so gridlines and labels never wrap or collide
    final rawMin = isBP ? (minY < 75 ? minY - 10 : 65.0) : (minY < 80 ? minY - 10 : 75.0);
    final rawMax = isBP ? (maxY > 135 ? maxY + 10 : 145.0) : (maxY > 135 ? maxY + 10 : 145.0);
    final finalMinY = (rawMin / 10).floor() * 10.0;
    final finalMaxY = (rawMax / 10).ceil() * 10.0;
    final yInterval = (finalMaxY - finalMinY) > 60 ? 20.0 : 10.0;
    final xInterval = (maxX / 4.0).clamp(1.0, 90.0);

    final diastolicColor = Colors.teal.shade600;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: finalMinY,
        maxY: finalMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > maxX) return const SizedBox.shrink();
                final date = firstDate.add(Duration(hours: (value * 24).toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    DateFormat('M/d').format(date),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.35), width: 1),
            left: BorderSide(color: Colors.grey.withOpacity(0.35), width: 1),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: isBP
              ? [
                  HorizontalLine(
                    y: 120,
                    color: Colors.amber.shade700.withOpacity(0.6),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                  ),
                  HorizontalLine(
                    y: 80,
                    color: diastolicColor.withOpacity(0.5),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                  ),
                ]
              : [
                  HorizontalLine(
                    y: 140,
                    color: Colors.teal.shade700.withOpacity(0.6),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                  ),
                ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots1,
            isCurved: spots1.length > 2,
            preventCurveOverShooting: true,
            curveSmoothness: 0.25,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3.5,
                color: Colors.white,
                strokeWidth: 2.5,
                strokeColor: theme.colorScheme.primary,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withOpacity(0.12),
            ),
          ),
          if (isBP && spots2.isNotEmpty)
            LineChartBarData(
              spots: spots2,
              isCurved: spots2.length > 2,
              preventCurveOverShooting: true,
              curveSmoothness: 0.25,
              color: diastolicColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: diastolicColor,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: diastolicColor.withOpacity(0.10),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// HISTORY TAB FOR BLOOD PRESSURE & BLOOD SUGAR
// ============================================================================

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({
    required this.logs,
    required this.vitalType,
    required this.unit,
    required this.vitalsArgs,
  });

  final List<VitalLog> logs;
  final VitalType vitalType;
  final String unit;
  final VitalsArgs vitalsArgs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (logs.isEmpty) {
      return const Center(child: Text('No data recorded yet.'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedLogs = List<VitalLog>.from(logs)..sort((a, b) => b.date.compareTo(a.date));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: sortedLogs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, index) {
        final log = sortedLogs[index];
        final isBP = vitalType == VitalType.bloodPressure;

        final String title = isBP
            ? '${log.value1.toInt()}/${log.value2?.toInt() ?? '?'} $unit'
            : '${log.value1.toInt()} $unit';

        final String badgeLabel;
        final Color badgeColor;
        if (isBP) {
          final cat = BpCategoryInfo.classify(log.value1, log.value2 ?? 80);
          badgeLabel = cat.label;
          badgeColor = cat.color;
        } else {
          final cat = GlucoseCategoryInfo.classify(log.value1, note: log.note);
          badgeLabel = cat.label;
          badgeColor = cat.color;
        }

        return Dismissible(
          key: ValueKey(log.id),
          background: Container(
            color: Theme.of(context).colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Reading?'),
                    content: Text('Remove $title from ${DateFormat('MMM d, y').format(log.date)}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (direction) {
            ref.read(vitalsProvider(vitalsArgs).notifier).deleteLog(log.id);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isBP ? Icons.favorite_outline : Icons.water_drop_outlined,
                    size: 20,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          _StatusBadge(label: badgeLabel, color: badgeColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, y • h:mm a').format(log.date),
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                      if (log.note != null && log.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          log.note!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// SHARED UI WIDGETS FOR VITALS
// ============================================================================

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _BpSpectrumBar extends StatelessWidget {
  const _BpSpectrumBar({required this.systolic, required this.diastolic});

  final double systolic;
  final double diastolic;

  @override
  Widget build(BuildContext context) {
    final clamped = systolic.clamp(90.0, 160.0);
    final fraction = (clamped - 90.0) / (160.0 - 90.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final indicatorX = (fraction * totalWidth).clamp(4.0, totalWidth - 4.0);

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    Expanded(flex: 42, child: Container(color: Colors.teal.shade400)),
                    const SizedBox(width: 1),
                    Expanded(flex: 15, child: Container(color: Colors.amber.shade400)),
                    const SizedBox(width: 1),
                    Expanded(flex: 15, child: Container(color: Colors.deepOrange.shade400)),
                    const SizedBox(width: 1),
                    Expanded(flex: 28, child: Container(color: Colors.red.shade400)),
                  ],
                ),
              ),
            ),
            Positioned(
              left: indicatorX - 3,
              child: Container(
                width: 6,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlucoseSpectrumBar extends StatelessWidget {
  const _GlucoseSpectrumBar({required this.mgDl});

  final double mgDl;

  @override
  Widget build(BuildContext context) {
    final clamped = mgDl.clamp(55.0, 200.0);
    final fraction = (clamped - 55.0) / (200.0 - 55.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final indicatorX = (fraction * totalWidth).clamp(4.0, totalWidth - 4.0);

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    Expanded(flex: 15, child: Container(color: Colors.blue.shade300)),
                    const SizedBox(width: 1),
                    Expanded(flex: 48, child: Container(color: Colors.teal.shade400)),
                    const SizedBox(width: 1),
                    Expanded(flex: 22, child: Container(color: Colors.amber.shade400)),
                    const SizedBox(width: 1),
                    Expanded(flex: 15, child: Container(color: Colors.red.shade400)),
                  ],
                ),
              ),
            ),
            Positioned(
              left: indicatorX - 3,
              child: Container(
                width: 6,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverviewKpiCard extends StatelessWidget {
  const _OverviewKpiCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeOfDayCard extends StatelessWidget {
  const _TimeOfDayCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  const _ChartLegendDot({
    required this.color,
    required this.label,
    this.isDashed = false,
  });

  final Color color;
  final String label;
  final bool isDashed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDashed)
          Container(width: 14, height: 2, color: color)
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
        ),
      ],
    );
  }
}

// ============================================================================
// ADD VITAL DIALOG WITH ONE-TAP CONTEXT TAGS
// ============================================================================

class _AddVitalDialog extends ConsumerStatefulWidget {
  const _AddVitalDialog({
    required this.profileId,
    required this.vitalType,
    required this.unit,
  });

  final String profileId;
  final VitalType vitalType;
  final String unit;

  @override
  ConsumerState<_AddVitalDialog> createState() => _AddVitalDialogState();
}

class _AddVitalDialogState extends ConsumerState<_AddVitalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  double? _enteredValue1;
  double? _enteredValue2;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  static const _bpContextTags = [
    'Morning reading',
    'Evening reading',
    'Before medication',
    'After medication',
    'At rest',
  ];

  static const _sugarContextTags = [
    'Fasting morning',
    'Before meal',
    '2h post-meal',
    'Bedtime',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    final noteText = _noteController.text.trim();
    final log = VitalLog(
      profileId: widget.profileId,
      type: widget.vitalType,
      date: _selectedDate,
      value1: _enteredValue1!,
      value2: _enteredValue2,
      unit: widget.unit,
      note: noteText.isEmpty ? null : noteText,
    );

    final vitalsArgs = (profileId: widget.profileId, type: widget.vitalType);
    final result = await ref.read(vitalsProvider(vitalsArgs).notifier).addLog(log);

    if (!mounted) return;

    if (result is Success) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving measurement.')),
      );
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBP = widget.vitalType == VitalType.bloodPressure;
    final isWeight = widget.vitalType == VitalType.weight;
    final isSugar = widget.vitalType == VitalType.bloodSugar;
    final quickTags = isBP ? _bpContextTags : (isSugar ? _sugarContextTags : const <String>[]);

    final dialogTitle = isBP
        ? 'Log Blood Pressure'
        : (isWeight ? 'Log Weight' : 'Log Blood Sugar');

    return AlertDialog(
      title: Text(dialogTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat.yMMMd().format(_selectedDate)),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Change Date'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isBP) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Systolic',
                          hintText: '120',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid' : null,
                        onSaved: (value) => _enteredValue1 = double.parse(value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Diastolic',
                          hintText: '80',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid' : null,
                        onSaved: (value) => _enteredValue2 = double.parse(value!),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextFormField(
                  decoration: InputDecoration(
                    labelText: isWeight ? 'Weight' : 'Blood Glucose',
                    suffixText: widget.unit,
                    hintText: isWeight ? 'e.g. 74.5' : 'e.g. 96',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid number' : null,
                  onSaved: (value) => _enteredValue1 = double.parse(value!),
                ),
              ],
              if (quickTags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Quick Context',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: quickTags.map((tag) {
                    final isSelected = _noteController.text.trim().toLowerCase() == tag.toLowerCase();
                    return ChoiceChip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (selected) {
                        setState(() {
                          _noteController.text = selected ? tag : '';
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
              : const Text('Save'),
        ),
      ],
    );
  }
}
