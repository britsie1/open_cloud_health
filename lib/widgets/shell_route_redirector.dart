import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/utils/constants.dart';

class ShellRouteRedirector extends ConsumerWidget {
  const ShellRouteRedirector({super.key, required this.targetRoute});

  final String targetRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profilesAsync = ref.read(profilesProvider);
      final profiles = profilesAsync.value ?? [];
      
      String? profileId;
      
      // 1. Try last used profile
      profileId = await ref.read(secureStorageProvider).getLastProfileId();
      
      // 2. Fallback to first profile if only one
      if (profileId == null && profiles.length == 1) {
        profileId = profiles[0].id;
      }
      
      if (!context.mounted) return;

      if (profileId != null) {
        final profile = profiles.where((p) => p.id == profileId).firstOrNull;
        context.go('$targetRoute/$profileId', extra: profile);
      } else {
        context.go(AppRoutes.profiles);
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
