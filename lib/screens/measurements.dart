import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';

class MeasurementsScreen extends ConsumerWidget {
  const MeasurementsScreen({super.key, required this.profileId});

  final String profileId;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);

    return Scaffold(
      appBar: AppBar(
        actions: const [AccountAppBarActions()],
        title: const Text('Vitals & Measurements'),
      ),
      body: profilesAsync.when(
        data: (profiles) {
          final profile = profiles.firstWhere((p) => p.id == profileId);
          final showPeriodTracker = profile.gender == Gender.female && _calculateAge(profile.dateOfBirth) >= 10;

          return ListView(
            children: [
              if (showPeriodTracker)
                ListTile(
                  leading: const Icon(Icons.water_drop, color: Colors.redAccent),
                  title: const Text('Period Tracker'),
                  subtitle: const Text('Log cycle and symptoms'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('${AppRoutes.periodTracker}/$profileId');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.deepPurple),
                title: const Text('Blood Pressure'),
                subtitle: const Text('Systolic & Diastolic tracking'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('${AppRoutes.vitalTracker}/$profileId/${VitalType.bloodPressure.name}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.monitor_heart, color: Colors.red),
                title: const Text('Heart Rate'),
                subtitle: const Text('BPM tracking'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('${AppRoutes.vitalTracker}/$profileId/${VitalType.heartRate.name}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.scale, color: Colors.blue),
                title: const Text('Weight & BMI'),
                subtitle: const Text('Body mass tracking'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('${AppRoutes.vitalTracker}/$profileId/${VitalType.weight.name}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bloodtype, color: Colors.orange),
                title: const Text('Blood Sugar'),
                subtitle: const Text('Glucose tracking'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('${AppRoutes.vitalTracker}/$profileId/${VitalType.bloodSugar.name}');
                },
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
