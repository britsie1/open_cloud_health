import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/screens/history.dart';
import 'package:open_cloud_health/screens/profile_detail.dart';

class ProfilesList extends ConsumerStatefulWidget {
  const ProfilesList({super.key, required this.profiles});

  final List<Profile> profiles;

  @override
  ConsumerState<ProfilesList> createState() => _ProfilesListState();
}

class _ProfilesListState extends ConsumerState<ProfilesList> {
  Future<ImageProvider> getProfileImage(Profile profile) async {
    if (profile.image.isEmpty) {
      return AssetImage(
          'assets/images/${profile.gender.name.toString()}_placeholder.png');
    } else {
      String filepath = await ref
          .read(profilesProvider.notifier)
          .getProfileImagePath(profile.image, profile.id);
      return FileImage(File(filepath));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider);

    void selectProfile(Profile profile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => HistoryScreen(profile: profile),
        ),
      );
    }

    Widget content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 20),
          child: Text(
            'Select a profile',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: profiles.length,
            itemBuilder: ((context, index) => FutureBuilder(
                  future: getProfileImage(profiles[index]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Text('Loading...'));
                    } else if (snapshot.hasError) {
                      return const Center(child: Text('Error loading profile'));
                    } else {
                      return ListTile(
                        contentPadding: const EdgeInsets.all(5),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundImage: snapshot.data,
                        ),
                        title: Text(
                          profiles[index].name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground),
                        ),
                        onTap: () {
                          selectProfile(profiles[index]);
                        },
                      );
                    }
                  },
                )),
          ),
        ),
        Center(
          child: Container(
              padding: const EdgeInsets.only(bottom: 24),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const ProfileDetailScreen(
                        profile: null,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add or import a profile'),
              )),
        )
      ],
    );

    if (profiles.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You don\'t have any profiles yet.\nLet\'s start by creating or importing a new profile.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const ProfileDetailScreen(
                        profile: null,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create or import a profile'),
              )
            ],
          ),
        ),
      );
    }

    return content;
  }
}
