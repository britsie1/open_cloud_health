import 'package:flutter/material.dart';
import 'package:open_cloud_health/widgets/account_appbar_actions.dart';

class HistoryEventDetailScreen extends StatelessWidget {
  const HistoryEventDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [AccountAppBarActions()],
      ),
      body: const Center(
        child: Text('Historic event details page'),
      ),
    );
  }
}
