import 'package:flutter/material.dart';
import 'package:open_cloud_health/pages/drawer.dart';
import 'package:open_cloud_health/pages/shared_app_bar.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SharedAppBar(),
      drawer: const DrawerPage(),
      body: Container(),
    );
  }
}