import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/profile_share_models.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/services/backup_encryption_service.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/utils/constants.dart';

class ImportProfileScreen extends ConsumerStatefulWidget {
  const ImportProfileScreen({super.key});

  @override
  ConsumerState<ImportProfileScreen> createState() => _ImportProfileScreenState();
}

class _ImportProfileScreenState extends ConsumerState<ImportProfileScreen> {
  bool _isLoading = false;
  String _loadingMessage = '';

  void _showLoading(String message) {
    setState(() {
      _isLoading = true;
      _loadingMessage = message;
    });
  }

  void _hideLoading() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadingMessage = '';
      });
    }
  }

  Future<String?> _promptPasswordDialog({
    required String title,
    required String subtitle,
    bool isRequired = true,
  }) async {
    final passwordController = TextEditingController();
    bool obscure = true;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline, color: Colors.blue.shade800),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: isRequired ? 'Backup Password or Key *' : 'Password (Optional)',
                  hintText: 'Enter password or 64-char key',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.key),
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
              onPressed: () {
                final text = passwordController.text.trim();
                if (isRequired && text.isEmpty) {
                  return;
                }
                Navigator.of(dialogCtx).pop(text);
              },
              child: const Text('Decrypt & Import'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleIndividualProfileImport({File? fileOverride}) async {
    try {
      File file;
      String fileName;

      if (fileOverride != null) {
        file = fileOverride;
        fileName = file.path.split(Platform.pathSeparator).last.toLowerCase();
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
        );

        if (result == null || result.files.isEmpty || result.files.single.path == null) {
          return;
        }

        final filePath = result.files.single.path!;
        file = File(filePath);
        fileName = result.files.single.name.toLowerCase();
      }

      // If user selected a full database archive (.ochbackup), offer to restore full backup instead
      if (fileName.endsWith('.ochbackup')) {
        if (!mounted) return;
        final shouldRestoreFull = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Full Backup Archive Selected'),
            content: const Text(
              'The selected file is a full database backup archive (.ochbackup). Would you like to restore the entire database backup instead?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Restore Full Backup'),
              ),
            ],
          ),
        );

        if (shouldRestoreFull == true) {
          await _handleLocalFileRestore(fileOverride: file);
        }
        return;
      }

      final fileBytes = await file.readAsBytes();
      SharedProfileBundle? bundle;

      // Check if file is encrypted (starts with OCH_E2E_V1 header or has .ochprofile extension)
      final headerBytes = utf8.encode(BackupEncryptionService.header);
      final isEncrypted = fileBytes.length >= headerBytes.length &&
          String.fromCharCodes(fileBytes.sublist(0, headerBytes.length)) == BackupEncryptionService.header;

      if (isEncrypted || fileName.endsWith('.ochprofile')) {
        final password = await _promptPasswordDialog(
          title: 'Decrypt & Import Profile',
          subtitle:
              'If this profile file was encrypted with a custom password or recovery key, please enter it below. Otherwise, leave blank to use device keys.',
          isRequired: false,
        );

        if (password == null) return; // User cancelled

        _showLoading('Decrypting profile records...');

        List<int> decryptedBytes;
        try {
          decryptedBytes = BackupEncryptionService.decryptBundle(
            fileBytes,
            password.isNotEmpty ? password : '',
          );
        } catch (e) {
          // Fallback to local master key if blank password attempt failed
          final localMasterKey = await ref.read(secureStorageProvider).getLocalMasterKey();
          if (localMasterKey != null && localMasterKey.isNotEmpty && password.isEmpty) {
            decryptedBytes = BackupEncryptionService.decryptBundle(fileBytes, localMasterKey);
          } else {
            rethrow;
          }
        }

        final jsonStr = utf8.decode(decryptedBytes);
        bundle = SharedProfileBundle.decodeFromJsonString(jsonStr);
      } else {
        // Plain JSON format (.json or plain text export)
        _showLoading('Reading profile data...');
        final content = utf8.decode(fileBytes);
        final dynamic parsed = jsonDecode(content);
        if (parsed is Map<String, dynamic>) {
          if (parsed.containsKey('profile')) {
            bundle = SharedProfileBundle.fromJson(parsed);
          } else if (parsed.containsKey('name') && parsed.containsKey('surname')) {
            final profile = Profile(
              id: parsed['id'] as String?,
              name: parsed['name'] as String,
              middleNames: parsed['middleNames'] as String? ?? '',
              surname: parsed['surname'] as String,
              dateOfBirth: DateTime.parse(parsed['dateOfBirth'] as String),
              gender: Gender.values.byName(parsed['gender'] as String),
              bloodType: parsed['bloodType'] as String? ?? 'Unknown',
              isOrganDonor: parsed['isOrganDonor'] as bool? ?? false,
              trackOvulation: parsed['trackOvulation'] as bool? ?? true,
              chronicConditions: (parsed['chronicConditions'] as List<dynamic>?)?.cast<String>() ?? [],
            );
            bundle = SharedProfileBundle(
              profile: profile,
              sharedBy: 'Imported File',
              sharedAt: DateTime.now(),
              moduleOptions: const ShareModuleOptions(),
            );
          }
        }
      }

      if (bundle == null) {
        throw const FormatException(
          'Unrecognized profile format. Please select a valid .ochprofile or .json profile file.',
        );
      }

      _showLoading('Importing ${bundle.profile.name} ${bundle.profile.surname}...');
      final importedProfile = await ref.read(profilesProvider.notifier).importProfileBundle(bundle);
      _hideLoading();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Profile "${importedProfile.name} ${importedProfile.surname}" imported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('${AppRoutes.home}/${importedProfile.id}', extra: importedProfile);
      }
    } catch (e) {
      _hideLoading();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLocalFileRestore({File? fileOverride}) async {
    try {
      File file;
      if (fileOverride != null) {
        file = fileOverride;
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
        );

        if (result == null || result.files.isEmpty || result.files.single.path == null) {
          return;
        }

        final filePath = result.files.single.path!;
        file = File(filePath);
        final fileName = result.files.single.name.toLowerCase();

        if (fileName.endsWith('.json') || fileName.endsWith('.ochprofile')) {
          if (mounted) {
            final shouldImportProfile = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Individual Profile Selected'),
                content: const Text(
                  'The selected file appears to be an individual profile file, not a full database backup archive. Would you like to import it as an individual profile instead?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Import as Profile'),
                  ),
                ],
              ),
            );

            if (shouldImportProfile == true) {
              await _handleIndividualProfileImport(fileOverride: file);
            }
          }
          return;
        }
      }

      final password = await _promptPasswordDialog(
        title: 'Restore Full Backup Archive',
        subtitle:
            'If this .ochbackup archive was encrypted with a custom password on another device, please enter it below. Otherwise, leave blank to use device hardware keys.',
        isRequired: false,
      );

      if (password == null) return; // User cancelled

      _showLoading('Unpacking & restoring full database backup...');
      final backupService = ref.read(backupServiceProvider);
      await backupService.importLocalBackup(
        file,
        customPassword: password.isNotEmpty ? password : null,
      );

      await ref.read(profilesProvider.notifier).loadProfiles();
      _hideLoading();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Full database backup restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go(AppRoutes.homeBase);
      }
    } catch (e) {
      _hideLoading();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import Health Data',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select whether you want to import an individual patient profile or restore a complete database backup archive.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 1: Import Profile from File (New!)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isLoading ? null : () => _handleIndividualProfileImport(),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_add_alt_1_outlined,
                                size: 32,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Import Profile from File',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Import an individual profile (.ochprofile or .json) with demographics, vitals, medications, and medical history.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section 2: Restore Full Database Backup from File (Clarified!)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isLoading ? null : () => _handleLocalFileRestore(),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.archive_outlined,
                                size: 32,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Restore Full Backup from File',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Restore an entire database archive (.ochbackup) containing all profiles, photos, and attachments. Replaces existing local data.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Security & Privacy Guarantee Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure & Processed Offline',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'All imported files and archives are decrypted and processed locally on your device. Your medical records remain private and secure.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _loadingMessage,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
