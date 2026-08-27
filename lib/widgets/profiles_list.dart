import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/services/profile_sharing_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/utils/result.dart';

class ProfilesList extends ConsumerStatefulWidget {
  const ProfilesList({super.key, required this.profiles});

  final List<Profile> profiles;

  @override
  ConsumerState<ProfilesList> createState() => _ProfilesListState();
}

class _ProfilesListState extends ConsumerState<ProfilesList> {
  Map<String, String> _profileImagePaths = {};
  bool _isLoadingImages = true;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadAllProfileImages();
  }

  @override
  void didUpdateWidget(covariant ProfilesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profiles != widget.profiles) {
      _loadAllProfileImages();
    }
  }

  Future<void> _loadAllProfileImages() async {
    if (!mounted) return;
    setState(() {
      _isLoadingImages = true;
    });
    final paths = <String, String>{};
    await Future.wait(widget.profiles.map((profile) async {
      final path = await ref
          .read(profilesProvider.notifier)
          .getProfileImagePath(profile.id);
      paths[profile.id] = path;
    }));
    if (mounted) {
      setState(() {
        _profileImagePaths = paths;
        _isLoadingImages = false;
      });
    }
  }

  Future<void> restoreBackup() async {
    setState(() {
      _isRestoring = true;
    });
    try {
      final backupService = ref.read(backupServiceProvider);
      try {
        await backupService.restoreFromBackup();
      } on FormatException {
        setState(() => _isRestoring = false);
        if (!mounted) return;

        final passwordController = TextEditingController();
        bool obscure = true;

        final password = await showDialog<String>(
          context: context,
          builder: (dialogCtx) => StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Encrypted Cloud Backup', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please enter your encryption password or recovery key to restore this cloud backup:'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Password or Key',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(null),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(passwordController.text.trim()),
                  child: const Text('Restore'),
                ),
              ],
            ),
          ),
        );

        if (password == null || password.isEmpty) return;

        setState(() => _isRestoring = true);
        await backupService.restoreFromBackup(password: password);
      }
      await ref.read(profilesProvider.notifier).loadProfiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingImages) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final profiles = widget.profiles;
    final activeShareConfigs = ref.watch(activeShareConfigsProvider).valueOrNull ?? {};

    void selectProfile(Profile profile) async {
      await ref.read(secureStorageProvider).saveLastProfileId(profile.id);
      if (!context.mounted) return;
      context.go('${AppRoutes.home}/${profile.id}', extra: profile);
    }

    Widget content = Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: profiles.length,
            itemBuilder: ((context, index) {
              final profile = profiles[index];
              final imagePath = _profileImagePaths[profile.id] ?? '';
              ImageProvider avatarImage;
              if (imagePath.isEmpty) {
                avatarImage = AssetImage(AppAssets.getGenderPlaceholder(profile.gender.name));
              } else {
                avatarImage = FileImage(File(imagePath));
              }

              final isShared = profile.isShared;
              final isActivelyShared = activeShareConfigs.containsKey(profile.id);

              Widget subtitleWidget;
              if (isShared) {
                subtitleWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Age: ${profile.age} years • ${profile.gender.name}',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_outlined, size: 12, color: Colors.teal),
                              SizedBox(width: 4),
                              Text(
                                'Shared (Read-Only)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (profile.sharedBy != null) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'by ${profile.sharedBy}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                );
              } else if (isActivelyShared) {
                subtitleWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Age: ${profile.age} years • ${profile.gender.name}',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.share, size: 11, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Sharing Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                subtitleWidget = Text(
                  'Age: ${profile.age} years • ${profile.gender.name}',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                      ),
                );
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: avatarImage,
                ),
                title: Text(
                  '${profile.name} ${profile.surname}',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                subtitle: subtitleWidget,
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) async {
                    if (action == 'sync') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Checking for updates from owner...')),
                      );
                      final result = await ref.read(profilesProvider.notifier).syncSharedProfile(profile.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).clearSnackBars();
                      if (result.status == SyncStatus.success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile synced successfully!'), backgroundColor: Colors.teal),
                        );
                      } else if (result.status == SyncStatus.revoked) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Access Revoked'),
                            content: const Text(
                              'The owner has revoked sharing or deleted this profile. Would you like to remove it from your device?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Keep Local Copy'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  foregroundColor: Theme.of(context).colorScheme.onError,
                                ),
                                onPressed: () async {
                                  Navigator.of(ctx).pop();
                                  await ref.read(profilesProvider.notifier).removeSharedProfile(profile.id);
                                },
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
                        );
                      }
                    } else if (action == 'share') {
                      context.push(AppRoutes.shareProfile, extra: profile);
                    } else if (action == 'remove_shared') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove Shared Profile'),
                          content: Text(
                            'Are you sure you want to remove "${profile.name}" from this device? You can re-import it anytime using the share QR code.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error,
                                foregroundColor: Theme.of(context).colorScheme.onError,
                              ),
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await ref.read(profilesProvider.notifier).removeSharedProfile(profile.id);
                              },
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                    } else if (action == 'export') {
                      context.push(AppRoutes.exportProfile, extra: profile);
                    } else if (action == 'edit') {
                      context.push(AppRoutes.profileDetail, extra: profile);
                    } else if (action == 'delete') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Profile'),
                          content: Text(
                              'Are you sure you want to delete ${profile.name}? The profile will be archived for 30 days and then automatically deleted.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error,
                                foregroundColor: Theme.of(context).colorScheme.onError,
                              ),
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                final result = await ref
                                    .read(profilesProvider.notifier)
                                    .archiveProfile(profile.id);
                                
                                if (!context.mounted) return;
                                
                                if (result is Success) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${profile.name} has been archived.'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to delete profile.'),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (ctx) {
                    if (isShared) {
                      return [
                        const PopupMenuItem(
                          value: 'sync',
                          child: ListTile(
                            leading: Icon(Icons.sync, color: Colors.teal),
                            title: Text('Sync / Refresh'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove_shared',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline, color: Colors.red),
                            title: Text('Remove from Device', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ];
                    }

                    return [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.qr_code_scanner, color: Colors.teal),
                          title: Text('Share (QR/Link)'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: ListTile(
                          leading: Icon(Icons.download),
                          title: Text('Export'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ];
                  },
                ),
                onTap: () {
                  selectProfile(profile);
                },
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push(AppRoutes.profileDetail);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(AppRoutes.qrScanner);
                  },
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.teal),
                  label: const Text('Scan QR'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(AppRoutes.importProfile);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Import'),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (profiles.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You don\'t have any profiles yet.\nLet\'s start by creating, scanning, or importing a profile.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 24,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  context.push(AppRoutes.profileDetail);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create a Profile'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                onPressed: () {
                  context.push(AppRoutes.qrScanner);
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Share QR Code'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  context.push(AppRoutes.importProfile);
                },
                icon: const Icon(Icons.download),
                label: const Text('Import a Profile'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isRestoring ? null : restoreBackup,
                icon: _isRestoring
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore),
                label: Text(_isRestoring ? 'Restoring...' : 'Restore backup'),
              ),
            ],
          ),
        ),
      );
    }

    return content;
  }
}
