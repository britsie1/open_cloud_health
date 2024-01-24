import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/screens/profile_detail.dart';
import 'package:open_cloud_health/screens/history.dart';
import 'package:open_cloud_health/screens/profiles.dart';
import 'package:open_cloud_health/screens/trackers.dart';

class MainDrawer extends ConsumerStatefulWidget {
  const MainDrawer(
      {super.key, required this.profileId, required this.currentRouteName});
  final String profileId;
  final String currentRouteName;

  @override
  ConsumerState<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends ConsumerState<MainDrawer> {
  void _navigateTo(String page, Profile profile) {
    Navigator.of(context).pop();

    if (widget.currentRouteName == page) {
      return;
    }

    Widget pageToNavigateTo = const ProfilesScreen();

    switch (page) {
      case 'profiles':
        pageToNavigateTo = const ProfilesScreen();
        break;
      case 'about':
        showAboutDialog(context: context);
        break;
      case 'trackers':
        pageToNavigateTo = TrackersScreen(profile: profile);
        break;
      case 'history':
        pageToNavigateTo = HistoryScreen(profile: profile);
        break;
      case 'profile_detail':
        pageToNavigateTo = ProfileDetailScreen(profile: profile);
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => pageToNavigateTo),
    );
  }

  @override
  Widget build(BuildContext context) {
    var profile =
        ref.watch(profilesProvider.notifier).getProfile(widget.profileId);

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                ),
                const SizedBox(
                  height: 16,
                ),
                Text('${profile.name} ${profile.surname}'),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.supervised_user_circle_outlined),
            title: const Text('Change Profile'),
            onTap: () => _navigateTo('profiles', profile),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => _navigateTo('dashboard', profile),
          ),
          ListTile(
            leading: const Icon(Icons.medical_information_outlined),
            title: const Text('Medical Information'),
            onTap: () => _navigateTo('profile_detail', profile),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Medical History'),
            onTap: () => _navigateTo('history', profile),
          ),
          ListTile(
            leading: const Icon(Icons.track_changes),
            title: const Text('Trackers'),
            onTap: () => _navigateTo('trackers', profile),
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
      ),
    );
  }
}
