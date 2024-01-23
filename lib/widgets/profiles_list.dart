import 'package:flutter/material.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/screens/profile_detail.dart';
import 'package:open_cloud_health/screens/dashboard.dart';

class ProfilesList extends StatelessWidget {
  const ProfilesList({super.key, required this.profiles});

  final List<Profile> profiles;

  @override
  Widget build(BuildContext context) {
    void selectProfile(Profile profile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => DashboardScreen(profile: profile),
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
            itemBuilder: ((context, index) => ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundImage: AssetImage(
                        'assets/images/${profiles[index].gender.name.toString()}_placeholder.png'),
                  ),
                  title: Text(
                    profiles[index].name,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onBackground),
                  ),
                  onTap: () {
                    selectProfile(profiles[index]);
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
