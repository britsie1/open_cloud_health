import 'package:flutter/material.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';
import 'package:open_cloud_health/widgets/main_drawer.dart';

class TrackersScreen extends StatelessWidget {
  const TrackersScreen({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trackers"),
        actions: const [AccountAppBarActions()]),
      drawer: MainDrawer(profile: profile),
      body: const Center(
        child: Text('Trackers screen'),
      ),
    );
  }
}
