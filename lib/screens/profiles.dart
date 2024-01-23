import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';
import 'package:open_cloud_health/widgets/profiles_list.dart';

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  late Future<void> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _profilesFuture = ref.read(profilesProvider.notifier).loadProfiles();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        actions: const [AccountAppBarActions()],
      ),
      body: FutureBuilder(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ProfilesList(
            profiles: profiles,
          );
        },
      ),
    );
  }
}
