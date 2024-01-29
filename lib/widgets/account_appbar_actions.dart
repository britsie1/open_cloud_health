import 'package:flutter/material.dart';
import 'package:open_cloud_health/screens/auth.dart';
import 'package:open_cloud_health/screens/settings.dart';

class AccountAppBarActions extends StatefulWidget {
  const AccountAppBarActions({super.key});

  @override
  State<AccountAppBarActions> createState() => _AccountAppBarActionsState();
}

class _AccountAppBarActionsState extends State<AccountAppBarActions> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      position: PopupMenuPosition.under,
      icon: const Icon(Icons.account_circle),
      itemBuilder: (ctx) => const [
        PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Logout'),
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'settings':
            Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const SettingsScreen()));
            break;
          case 'logout':
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (ctx) => const AuthScreen()));
            break;
        }
      },
    );
  }
}
