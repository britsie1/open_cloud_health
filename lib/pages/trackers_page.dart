import 'package:flutter/material.dart';
import 'package:open_cloud_health/pages/drawer.dart';
import 'package:open_cloud_health/pages/shared_app_bar.dart';

class TrackersPage extends StatelessWidget {
  const TrackersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SharedAppBar(),
      drawer: const DrawerPage(),
      body: Container()
    );
  }
}