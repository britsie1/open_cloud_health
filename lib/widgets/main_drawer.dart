import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/screens/profile_detail.dart';
import 'package:open_cloud_health/screens/history.dart';
import 'package:open_cloud_health/screens/profiles.dart';
import 'package:open_cloud_health/screens/trackers.dart';

class MainDrawer extends ConsumerStatefulWidget {
  const MainDrawer({super.key, required this.profileId});
  final String profileId;

  //final Profile profile;

  @override
  ConsumerState<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends ConsumerState<MainDrawer> {
  void _navigateTo(String page, Profile profile) {
    Navigator.of(context).pop();
    switch (page) {
      case 'profiles':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (ctx) => const ProfilesScreen()));
        break;
      case 'about':
        showAboutDialog(context: context);
        break;
      case 'trackers':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => TrackersScreen(
              profile: profile,
            ),
          ),
        );
        break;
      case 'history':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => HistoryScreen(
              profile: profile,
            ),
          ),
        );
        break;
      case 'information':
      Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ProfileDetailScreen(
              profile: profile,
            ),
          ),
        );
      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    var profile = ref.watch(profilesProvider.notifier).getProfile(widget.profileId);

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
            onTap: () => _navigateTo('information', profile),
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
