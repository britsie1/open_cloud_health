import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/utils/constants.dart';

class MainDrawer extends ConsumerStatefulWidget {
  const MainDrawer(
      {super.key, required this.profileId, required this.currentRouteName});
  final String profileId;
  final String currentRouteName;

  @override
  ConsumerState<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends ConsumerState<MainDrawer> {
  File? _profileImageFile;

  void _navigateTo(String route, Profile profile) {
    if (route == 'about') {
      showAboutDialog(context: context);
      return;
    }

    if (route == 'share') {
      // TODO: Implement share
      context.pop();
      return;
    }

    if (route == widget.currentRouteName) {
      context.pop();
      return;
    }

    context.pop(); // Close drawer

    switch (route) {
      case AppRoutes.profiles:
        context.push(AppRoutes.profiles);
        break;
      case AppRoutes.history:
        context.push('${AppRoutes.history}/${profile.id}', extra: profile);
        break;
      case AppRoutes.profileDetail:
        context.push(AppRoutes.profileDetail, extra: profile);
        break;
      case AppRoutes.medicationTracker:
        context.push('${AppRoutes.medicationTracker}/${profile.id}');
        break;
      case AppRoutes.checkups:
        context.push('${AppRoutes.checkups}/${profile.id}');
        break;
      case AppRoutes.measurements:
        context.push('${AppRoutes.measurements}/${profile.id}');
        break;
    }
  }

  @override
  void initState() {
    super.initState();

    var profile =
        ref.read(profilesProvider.notifier).getProfile(widget.profileId);

    ref
        .read(profilesProvider.notifier)
        .getProfileImagePath(profile.id)
        .then((value) {
      if (value.isNotEmpty) {
        setState(() {
          _profileImageFile = File.fromUri(Uri(path: value));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);

    ImageProvider getProfileImage(Profile profile) {
      if (_profileImageFile != null) {
        return FileImage(_profileImageFile!);
      } else {
        return AssetImage(AppAssets.getGenderPlaceholder(profile.gender.name));
      }
    }

    return Drawer(
      child: profilesAsync.when(
        data: (profiles) {
          final profile = profiles.firstWhere((p) => p.id == widget.profileId);

          return ListView(
            children: [
              DrawerHeader(
                child: Column(
                  children: [
                    CircleAvatar(
                        radius: 40, backgroundImage: getProfileImage(profile)),
                    const SizedBox(
                      height: 16,
                    ),
                    Text('${profile.name} ${profile.surname}'),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.supervised_user_circle_outlined),
                title: const Text('Switch Profile'),
                onTap: () => _navigateTo(AppRoutes.profiles, profile),
              ),
              ListTile(
                leading: const Icon(Icons.medical_information_outlined),
                title: const Text('Profile Information'),
                onTap: () => _navigateTo(AppRoutes.profileDetail, profile),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Medical History'),
                onTap: () => _navigateTo(AppRoutes.history, profile),
              ),
              ListTile(
                leading: const Icon(Icons.medication_liquid_sharp),
                title: const Text('Medication Tracker'),
                onTap: () => _navigateTo(AppRoutes.medicationTracker, profile),
              ),
              ListTile(
                leading: const Icon(Icons.medical_services),
                title: const Text('Medical Checkups'),
                onTap: () => _navigateTo(AppRoutes.checkups, profile),
              ),
              ListTile(
                leading: const Icon(Icons.monitor_heart),
                title: const Text('Vitals & Measurements'),
                onTap: () => _navigateTo(AppRoutes.measurements, profile),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Profile'),
                onTap: () => _navigateTo('share', profile),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About OpenCloudHealth'),
                onTap: () => _navigateTo('about', profile),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
