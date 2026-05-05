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
          value: AppRoutes.settings,
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
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
          case AppRoutes.settings:
            context.push(AppRoutes.settings);
            break;
          case AppRoutes.auth:
            context.go(AppRoutes.auth);
            break;
        }
      },
    );
  }
}
