import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/utils/result.dart';

class ArchivedProfilesScreen extends ConsumerStatefulWidget {
  const ArchivedProfilesScreen({super.key});

  @override
  ConsumerState<ArchivedProfilesScreen> createState() => _ArchivedProfilesScreenState();
}

class _ArchivedProfilesScreenState extends ConsumerState<ArchivedProfilesScreen> {
  List<Profile> _archivedProfiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchivedProfiles();
  }

  Future<void> _loadArchivedProfiles() async {
    setState(() {
      _isLoading = true;
    });
    final archived = await ref.read(profilesProvider.notifier).fetchArchivedProfiles();
    if (mounted) {
      setState(() {
        _archivedProfiles = archived;
        _isLoading = false;
      });
    }
  }

  Future<ImageProvider> getProfileImage(Profile profile) async {
    String filepath = await ref
        .read(profilesProvider.notifier)
        .getProfileImagePath(profile.id);

    if (filepath.isEmpty) {
      return AssetImage(AppAssets.getGenderPlaceholder(profile.gender.name));
    } else {
      return FileImage(File(filepath));
    }
  }

  int _daysRemaining(DateTime archivedAt) {
    final diff = DateTime.now().difference(archivedAt).inDays;
    return (30 - diff).clamp(0, 30);
  }

  void _restoreProfile(Profile profile) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Profile'),
        content: Text('Are you sure you want to restore ${profile.name} ${profile.surname} back to your active list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await ref.read(profilesProvider.notifier).restoreProfile(profile.id);
              if (!mounted) return;
              if (result is Success) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${profile.name} has been restored successfully.'),
                  ),
                );
                _loadArchivedProfiles();
              } else {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to restore profile.'),
                  ),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _deletePermanently(Profile profile) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: Text(
          'WARNING: Are you sure you want to permanently delete ${profile.name} ${profile.surname}? This will immediately destroy all demographics, medication trackers, allergies, checkups, and history events. This action CANNOT be undone.',
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
              final result = await ref.read(profilesProvider.notifier).deleteProfilePermanently(profile.id);
              if (!mounted) return;
              if (result is Success) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${profile.name} has been permanently deleted.'),
                  ),
                );
                _loadArchivedProfiles();
              } else {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to permanently delete profile.'),
                  ),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Profiles'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _archivedProfiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No archived profiles',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Profiles you delete will appear here for 30 days.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _archivedProfiles.length,
                  itemBuilder: (context, index) {
                    final profile = _archivedProfiles[index];
                    final days = _daysRemaining(profile.archivedAt ?? DateTime.now());
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: FutureBuilder<ImageProvider>(
                          future: getProfileImage(profile),
                          builder: (context, snapshot) {
                            final image = snapshot.data;
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundImage: image,
                              ),
                              title: Text(
                                '${profile.name} ${profile.surname}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Age: ${profile.age} years • ${profile.gender.name}'),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$days days remaining before deletion',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.unarchive_outlined),
                                    tooltip: 'Restore Profile',
                                    color: Theme.of(context).colorScheme.primary,
                                    onPressed: () => _restoreProfile(profile),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever_outlined),
                                    tooltip: 'Delete Permanently',
                                    color: Theme.of(context).colorScheme.error,
                                    onPressed: () => _deletePermanently(profile),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
