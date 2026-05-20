import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/services/backup_service.dart';
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
      await ref.read(backupServiceProvider).restoreFromBackup();
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

    void selectProfile(Profile profile) async {
      await ref.read(secureStorageProvider).saveLastProfileId(profile.id);
      if (!context.mounted) return;
      context.go('${AppRoutes.home}/${profile.id}', extra: profile);
    }

    Widget content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 20),
          child: Text(
            'Select a profile',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
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

              return ListTile(
                contentPadding: const EdgeInsets.all(5),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: avatarImage,
                ),
                title: Text(
                  '${profile.name} ${profile.surname}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground,
                          fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Age: ${profile.age} years • ${profile.gender.name}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.6)),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    if (action == 'export') {
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
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
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
                  ],
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
                  label: const Text('Create Profile'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(AppRoutes.importProfile);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Import Profile'),
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
                'You don\'t have any profiles yet.\nLet\'s start by creating or importing a new profile.',
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
