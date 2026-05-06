import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/utils/constants.dart';

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
          value: 'switch_profile',
          child: ListTile(
            leading: Icon(Icons.supervised_user_circle_outlined),
            title: Text('Switch Profile'),
          ),
        ),
        PopupMenuItem(
          value: AppRoutes.settings,
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ),
        PopupMenuItem(
          value: 'about',
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
          ),
        ),
        PopupMenuItem(
          value: AppRoutes.auth,
          child: ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Logout'),
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'switch_profile':
            context.go(AppRoutes.profiles);
            break;
          case AppRoutes.settings:
            context.push(AppRoutes.settings);
            break;
          case 'about':
            showAboutDialog(
              context: context,
              applicationName: 'Open Cloud Health',
              applicationVersion: '1.0.0',
            );
            break;
          case AppRoutes.auth:
            context.go(AppRoutes.auth);
            break;
        }
      },
    );
  }
}
