import 'package:flutter/material.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';
import 'package:open_cloud_health/widgets/main_drawer.dart';

class MeasurementsScreen extends StatelessWidget {
  const MeasurementsScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [AccountAppBarActions()],
        title: const Text('Vitals & Measurements'),
      ),
      drawer: MainDrawer(profileId: profileId, currentRouteName: 'measurements'),
      body: const Center(
        child: Text('Vitals & Measurements feature coming soon!'),
      ),
    );
  }
}
