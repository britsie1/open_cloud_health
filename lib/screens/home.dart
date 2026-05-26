import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/providers/checkups_provider.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/utils/icon_utils.dart';
import 'package:open_cloud_health/utils/result.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';
import 'package:open_cloud_health/widgets/log_checkup_dialog.dart';
import 'package:open_cloud_health/widgets/log_tracked_dose_dialog.dart';

class TodayMedicationTask {
  final Medication medication;
  final TimeOfDay time;

  TodayMedicationTask({required this.medication, required this.time});
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.profile, this.profileId});

  final Profile? profile;
  final String? profileId;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Profile? _activeProfile;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

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

  Future<ImageProvider> _getProfileImage(Profile activeProfile) async {
    final filepath = await ref
        .read(profilesProvider.notifier)
        .getProfileImagePath(activeProfile.id);

    if (filepath.isEmpty) {
      return AssetImage(AppAssets.getGenderPlaceholder(activeProfile.gender.name));
    } else {
      return FileImage(File(filepath));
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: const [AccountAppBarActions()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeProfile.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context.go('${AppRoutes.profileDetail}/${activeProfile.id}',
                        extra: activeProfile);
                  },
                  child: FutureBuilder<ImageProvider>(
                    future: _getProfileImage(activeProfile),
                    builder: (context, snapshot) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: snapshot.data,
                          child: snapshot.connectionState == ConnectionState.waiting
                              ? const CircularProgressIndicator()
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // Quick Vitals Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Quick Vitals',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _VitalsSection(profile: activeProfile),
              ],
            ),

            // Medication Section (Handles its own spacing/divider if visible)
            _MedicationSummarySection(profileId: activeProfile.id),

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),
            
            // Checkups Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event_available_outlined, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Medical Checkups',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    context.push('${AppRoutes.checkups}/${activeProfile.id}');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Consumer(
              builder: (context, ref, child) {
                final checkupsAsync = ref.watch(checkupsProvider(activeProfile.id));
                
                return checkupsAsync.when(
                  data: (checkups) {
                    if (checkups.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('No checkups scheduled.'),
                        ),
                      );
                    }
                    
                    final nextUp = checkups.first;
                    final overdueCount = checkups.where((c) => c.isOverdue).length;
                    final isOverdue = nextUp.isOverdue;
                    final color = isOverdue ? Colors.red : Colors.blue;
                    final iconWidget = getCheckupIconWidget(nextUp.checkup.iconName, checkupName: nextUp.checkup.name, color: color, size: 28);

                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => LogCheckupDialog(
                            profileId: activeProfile.id,
                            checkupId: nextUp.checkup.id,
                            checkupName: nextUp.checkup.name,
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(child: iconWidget),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nextUp.checkup.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isOverdue 
                                            ? 'Overdue now' 
                                            : 'Due on ${nextUp.nextDueDate != null ? DateFormat.yMMMd().format(nextUp.nextDueDate!) : 'TBD'}',
                                        style: TextStyle(
                                          color: isOverdue ? Colors.red : Colors.grey.shade600,
                                          fontSize: 14,
                                          fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOverdue)
                                  const Icon(Icons.error_outline, color: Colors.red),
                              ],
                            ),
                            if (overdueCount > 1) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade800),
                                  const SizedBox(width: 8),
                                  Text(
                                    'You have $overdueCount total checkups overdue',
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Error: $err'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationSummarySection extends ConsumerWidget {
  const _MedicationSummarySection({required this.profileId});
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsProvider(profileId));
    final logsAsync = ref.watch(medicationLogsProvider(profileId));

    return medicationsAsync.maybeWhen(
      data: (medications) {
        if (medications.isEmpty) return const SizedBox.shrink();

        final todayWeekday = DateTime.now().weekday;
        
        // Active scheduled medications today
        final activeScheduled = medications
            .where((m) => m.isActive && !m.isAsNeeded && m.daysOfWeek.contains(todayWeekday))
            .toList();

        final List<TodayMedicationTask> tasks = [];
        for (final med in activeScheduled) {
          for (final time in med.timesOfDay) {
            tasks.add(TodayMedicationTask(medication: med, time: time));
          }
        }

        // Sort tasks chronologically
        tasks.sort((a, b) {
          if (a.time.hour != b.time.hour) return a.time.hour.compareTo(b.time.hour);
          return a.time.minute.compareTo(b.time.minute);
        });

        // PRN / As Needed active medications
        final prnMedications = medications
            .where((m) => m.isActive && m.isAsNeeded)
            .toList();

        if (tasks.isEmpty && prnMedications.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medication_outlined,
                        color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Today\'s Medication',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    context.go('${AppRoutes.medicationTracker}/$profileId');
                  },
                  child: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Mini Adherence Bar
            Consumer(
              builder: (context, ref, child) {
                final adherenceAsync = ref.watch(medicationAdherenceProvider(profileId));
                return adherenceAsync.maybeWhen(
                  data: (data) {
                    final percentage = (data.adherenceRate * 100).toInt();
                    final theme = Theme.of(context);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daily Adherence',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '$percentage%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: data.adherenceRate,
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                );
              },
            ),
            
            if (tasks.isNotEmpty) ...[
              const Text(
                'Scheduled Tasks',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              logsAsync.when(
                data: (logs) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: tasks.map((task) {
                        final isTaken = logs.any((log) =>
                            log.medicationId == task.medication.id &&
                            log.timestamp.hour == task.time.hour &&
                            log.timestamp.minute == task.time.minute);
                        return _MedicationSummaryItem(
                          task: task,
                          isTaken: isTaken,
                          profileId: profileId,
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              ),
              const SizedBox(height: 16),
            ],

            if (prnMedications.isNotEmpty) ...[
              const Text(
                'As-Needed & Tracked',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                child: Column(
                  children: prnMedications.map((med) {
                    return _PRNMedicationSummaryItem(
                      medication: med,
                      profileId: profileId,
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _MedicationSummaryItem extends ConsumerWidget {
  const _MedicationSummaryItem({
    required this.task,
    required this.isTaken,
    required this.profileId,
  });

  final TodayMedicationTask task;
  final bool isTaken;
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final med = task.medication;
    final taskTime = task.time;
    final theme = Theme.of(context);
    
    final hour = taskTime.hour.toString().padLeft(2, '0');
    final minute = taskTime.minute.toString().padLeft(2, '0');
    final timeFormatted = '$hour:$minute';

    final isLowStock = med.trackInventory &&
        med.stockQuantity <= med.lowStockThreshold;

    return CheckboxListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              med.name,
              style: TextStyle(
                decoration: isTaken ? TextDecoration.lineThrough : null,
                color: isTaken ? Colors.grey : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isLowStock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, size: 10, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 2),
                  Text(
                    'Low Stock: ${med.stockQuantity.toInt()}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      subtitle: Text(
        med.trackInventory
            ? '${med.dosage} at $timeFormatted • Stock: ${med.stockQuantity.toInt()} left'
            : '${med.dosage} at $timeFormatted',
      ),
      value: isTaken,
      activeColor: Colors.blue,
      onChanged: (val) async {
        Result<void, Exception> result;
        final now = DateTime.now();
        final targetTimestamp = DateTime(now.year, now.month, now.day, taskTime.hour, taskTime.minute);

        if (val == true) {
          result = await ref
              .read(medicationLogsProvider(profileId).notifier)
              .addLog(
                MedicationLog(
                  medicationId: med.id,
                  timestamp: targetTimestamp,
                ),
              );
        } else {
          result = await ref
              .read(medicationLogsProvider(profileId).notifier)
              .removeLog(
                med.id,
                targetTimestamp,
                time: taskTime,
              );
        }

        if (result is Failure && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update log: ${result.exception}')),
          );
        }
      },
    );
  }
}

class _PRNMedicationSummaryItem extends ConsumerWidget {
  const _PRNMedicationSummaryItem({
    required this.medication,
    required this.profileId,
  });

  final Medication medication;
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLowStock = medication.trackInventory &&
        medication.stockQuantity <= medication.lowStockThreshold;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Row(
        children: [
          Expanded(
            child: Text(
              medication.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          if (isLowStock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, size: 10, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 2),
                  Text(
                    'Low Stock: ${medication.stockQuantity.toInt()}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      subtitle: Text(
        medication.trackInventory
            ? '${medication.dosage} • Stock: ${medication.stockQuantity.toInt()} left'
            : medication.dosage,
      ),
      trailing: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => LogTrackedDoseDialog(
              profileId: profileId,
              medication: medication,
            ),
          );
        },
        icon: const Icon(Icons.add, size: 14),
        label: const Text('Log', style: TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _VitalsSection extends StatelessWidget {
  const _VitalsSection({required this.profile});

  final Profile profile;

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final showPeriodTracker =
        profile.gender == Gender.female && _calculateAge(profile.dateOfBirth) >= 10;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (showPeriodTracker)
            _VitalItem(
              icon: getVitalIcon('Period', color: Colors.redAccent, size: 28),
              color: Colors.redAccent,
              label: 'Period',
              onTap: () => context.push('${AppRoutes.periodTracker}/${profile.id}'),
            ),
          _VitalItem(
            icon: getVitalIcon('BP', color: Colors.deepPurple, size: 28),
            color: Colors.deepPurple,
            label: 'BP',
            onTap: () => context.push(
                '${AppRoutes.vitalTracker}/${profile.id}/${VitalType.bloodPressure.name}'),
          ),
          _VitalItem(
            icon: getVitalIcon('Heart', color: Colors.red, size: 28),
            color: Colors.red,
            label: 'Heart',
            onTap: () => context.push(
                '${AppRoutes.vitalTracker}/${profile.id}/${VitalType.heartRate.name}'),
          ),
          _VitalItem(
            icon: getVitalIcon('Weight', color: Colors.blue, size: 28),
            color: Colors.blue,
            label: 'Weight',
            onTap: () => context.push(
                '${AppRoutes.vitalTracker}/${profile.id}/${VitalType.weight.name}'),
          ),
          _VitalItem(
            icon: getVitalIcon('Sugar', color: Colors.orange, size: 28),
            color: Colors.orange,
            label: 'Sugar',
            onTap: () => context.push(
                '${AppRoutes.vitalTracker}/${profile.id}/${VitalType.bloodSugar.name}'),
          ),
        ],
      ),
    );
  }
}

class _VitalItem extends StatelessWidget {
  const _VitalItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

