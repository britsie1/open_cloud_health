import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';

class AccountAppBarActions extends ConsumerStatefulWidget {
  const AccountAppBarActions({super.key});

  @override
  ConsumerState<AccountAppBarActions> createState() => _AccountAppBarActionsState();
}

class _AccountAppBarActionsState extends ConsumerState<AccountAppBarActions> {
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
            title: Text('Manage Profiles'),
          ),
        ),
        PopupMenuItem(
          value: 'emergency',
          child: ListTile(
            leading: Icon(Icons.emergency, color: Colors.red),
            title: Text('Emergency Lock Screen'),
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
      onSelected: (value) async {
        switch (value) {
          case 'switch_profile':
            context.go(AppRoutes.profiles);
            break;
          case 'emergency':
            final lastProfileId = await ref.read(secureStorageProvider).getLastProfileId();
            final profiles = ref.read(profilesProvider).value ?? [];
            if (profiles.isNotEmpty) {
              final activeProfileId = lastProfileId ?? profiles.first.id;
              if (context.mounted) {
                context.push('${AppRoutes.emergencySettings}/$activeProfileId');
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please create a profile first.')),
                );
              }
            }
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

