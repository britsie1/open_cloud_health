import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/screens/profile_detail.dart';
import 'package:open_cloud_health/screens/history.dart';
import 'package:open_cloud_health/screens/profiles.dart';

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

  void _navigateTo(String page, Profile profile) {
    if (page == 'about'){
      showAboutDialog(context: context);
      return;
    }

    Navigator.of(context).pop();
    Widget pageToNavigateTo = const ProfilesScreen();

    switch (page) {
      case 'profiles':
        pageToNavigateTo = const ProfilesScreen();
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
  void initState() {
    super.initState();

    var profile =
        ref.read(profilesProvider.notifier).getProfile(widget.profileId);

    if (profile.image.isNotEmpty) {
      ref
          .read(profilesProvider.notifier)
          .getProfileImagePath(profile.image, profile.name)
          .then((value) {
        setState(() {
          _profileImageFile = File.fromUri(Uri(path: value));
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var profile =
        ref.watch(profilesProvider.notifier).getProfile(widget.profileId);

    ImageProvider getProfileImage(Profile profile) {
      if (_profileImageFile != null) {
        return FileImage(_profileImageFile!);
      } else {
        return AssetImage(
            'assets/images/${profile.gender.name}_placeholder.png');
      }
    }

    return Drawer(
      child: ListView(
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
            onTap: () => _navigateTo('profiles', profile),
          ),
          ListTile(
            leading: const Icon(Icons.medical_information_outlined),
            title: const Text('Profile Information'),
            onTap: () => _navigateTo('profile_detail', profile),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Medical History'),
            onTap: () => _navigateTo('history', profile),
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
