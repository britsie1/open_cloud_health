import 'package:flutter/material.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';
import 'package:open_cloud_health/widgets/main_drawer.dart';

class CheckupsScreen extends StatelessWidget {
  const CheckupsScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [AccountAppBarActions()],
        title: const Text('Medical Checkups'),
      ),
      drawer: MainDrawer(profileId: profileId, currentRouteName: 'checkups'),
      body: const Center(
        child: Text('Medical Checkups feature coming soon!'),
      ),
    );
  }
}
