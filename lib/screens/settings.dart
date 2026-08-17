import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/storage_info.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/utils/format_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _databaseSizeKb = 0;
  double _documentsFileSizeKb = 0;
  bool _isLoadingStorage = true;
  bool _isBackingUp = false;
  bool _isConnectedToGoogle = false;
  GoogleStorageInfo? _storageInfo;
  String _lastBackupDateTime = 'Not connected';

  @override
  void initState() {
    super.initState();
    _loadLocalSizes();
    _checkGoogleConnection();
  }

  Future<void> _loadLocalSizes() async {
    ref.read(databaseHelperProvider).getDatabaseSize().then((value) {
      if (mounted) {
        setState(() => _databaseSizeKb = value / 1024);
      }
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      var files = appDir.listSync(recursive: true);
      var size = 0;

      if (files.isNotEmpty) {
        size = files
            .where((file) => p.basename(file.path) != 'opencloudhealth.db')
            .map((file) {
          if (file is File) {
            return File(file.path).lengthSync();
          }
          return 0;
        }).fold(0, (previousValue, element) => previousValue + element);
      }

      if (mounted) {
        setState(() {
          _documentsFileSizeKb = size / 1024;
        });
      }
    } catch (e) {
      debugPrint('Error calculating local document size: $e');
    }
  }

  Future<void> _checkGoogleConnection() async {
    setState(() => _isLoadingStorage = true);
    final backupService = ref.read(backupServiceProvider);
    final user = await backupService.getConnectedUser();

    if (user != null) {
      final info = await backupService.getGoogleStorageInfo(interactive: false);
      if (mounted) {
        setState(() {
          _isConnectedToGoogle = true;
          _storageInfo = info;
          _lastBackupDateTime = info?.lastBackupDateTime ?? 'Never';
          _isLoadingStorage = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isConnectedToGoogle = false;
          _storageInfo = null;
          _isLoadingStorage = false;
        });
      }
    }
  }

  Future<void> _connectToGoogle() async {
    setState(() => _isLoadingStorage = true);
    try {
      final backupService = ref.read(backupServiceProvider);
      final info = await backupService.getGoogleStorageInfo(interactive: true);

      if (info != null) {
        if (mounted) {
          setState(() {
            _isConnectedToGoogle = true;
            _storageInfo = info;
            _lastBackupDateTime = info.lastBackupDateTime ?? 'Never';
            _isLoadingStorage = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connected to Google Drive successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isConnectedToGoogle = false;
            _isLoadingStorage = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error connecting to Google: $e');
      if (mounted) {
        setState(() {
          _isConnectedToGoogle = false;
          _isLoadingStorage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to Google Drive: $e')),
        );
      }
    }
  }

  Future<void> _disconnectGoogle() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Google Drive'),
        content: const Text(
          'Are you sure you want to disconnect Google Drive? Automatic backups will be paused until you reconnect.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(backupServiceProvider).signOut();
      if (mounted) {
        setState(() {
          _isConnectedToGoogle = false;
          _storageInfo = null;
          _lastBackupDateTime = 'Not connected';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disconnected from Google Drive')),
        );
      }
    }
  }

  Future<void> _uploadBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final formattedTime =
          await ref.read(backupServiceProvider).backupToGoogleDrive();

      if (formattedTime.isNotEmpty) {
        // Refresh storage info after backup
        final updatedInfo = await ref
            .read(backupServiceProvider)
            .getGoogleStorageInfo(interactive: false);

        if (mounted) {
          setState(() {
            _lastBackupDateTime = '$formattedTime UTC';
            if (updatedInfo != null) {
              _storageInfo = updatedInfo;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medical data backed up to Google Drive'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Backup error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _openManageGoogleStorage() async {
    final Uri storageUrl = Uri.parse('https://one.google.com/storage');
    try {
      final launched = await launchUrl(
        storageUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Storage settings.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error launching storage URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening Google Storage: $e')),
        );
      }
    }
  }

  Future<void> _resetDB() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Reset All Data'),
          ],
        ),
        content: const Text(
          'This will permanently delete all local patient profiles, history logs, medication schedules, and attachments. This action cannot be undone.\n\nAre you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(databaseHelperProvider).resetDatabase();

    Directory dir = await getTemporaryDirectory();
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
      dir.create();
    }

    if (!mounted) return;
    context.go(AppRoutes.auth);
  }

  Color _getStorageProgressColor(double fraction) {
    if (fraction >= 0.95) return Colors.red;
    if (fraction >= 0.80) return Colors.amber.shade800;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _buildGoogleBackupSection(),
          const SizedBox(height: 20),
          _buildSecuritySection(),
          const SizedBox(height: 20),
          _buildLocalStorageSection(),
          const SizedBox(height: 20),
          _buildAboutSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGoogleBackupSection() {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_sync_outlined, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Drive Backup',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isConnectedToGoogle
                            ? 'Encrypted cloud backup active'
                            : 'Backup medical data to your Drive',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isConnectedToGoogle)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh Storage Info',
                    onPressed: _checkGoogleConnection,
                  ),
              ],
            ),
            const Divider(height: 24),
            if (_isLoadingStorage)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (!_isConnectedToGoogle) ...[
              Text(
                'Connect your Google Account to back up all patient histories, medication schedules, and attachments securely into your personal Google Drive App Data folder.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _connectToGoogle,
                  icon: const Icon(Icons.add_to_drive),
                  label: const Text('Connect to Google Drive'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // WhatsApp-style Account Tile
              _buildAccountRow(),
              const SizedBox(height: 16),

              // WhatsApp-style Storage Usage Bar
              _buildStorageMeter(),
              const SizedBox(height: 16),

              // Medical Backup stats
              _buildBackupStats(),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isBackingUp ? null : _uploadBackup,
                      icon: _isBackingUp
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(_isBackingUp ? 'Backing up...' : 'Back Up Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Manage Google Storage link & Disconnect option
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _openManageGoogleStorage,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Manage Google Storage'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  TextButton(
                    onPressed: _disconnectGoogle,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountRow() {
    final info = _storageInfo;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.shade100,
            backgroundImage:
                (info?.photoUrl != null && info!.photoUrl!.isNotEmpty)
                    ? NetworkImage(info.photoUrl!)
                    : null,
            child: (info?.photoUrl == null || info!.photoUrl!.isEmpty)
                ? Text(
                    (info?.displayName?.isNotEmpty == true)
                        ? info!.displayName![0].toUpperCase()
                        : (info?.userEmail?.isNotEmpty == true
                            ? info!.userEmail![0].toUpperCase()
                            : 'G'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info?.displayName ?? 'Google Account',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (info?.userEmail != null)
                  Text(
                    info!.userEmail!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageMeter() {
    final info = _storageInfo;
    if (info == null) return const SizedBox.shrink();

    final fraction = info.usageFraction;
    final progressColor = _getStorageProgressColor(fraction);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline, size: 16, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    'Google Storage',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (!info.isUnlimited)
                Text(
                  FormatUtils.formatPercentage(fraction),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: progressColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: info.isUnlimited ? null : fraction,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${info.formattedUsed} of ${info.formattedTotal} used',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${info.formattedAvailable} available',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackupStats() {
    final info = _storageInfo;
    final backupSize = (info != null && info.appBackupBytes > 0)
        ? info.formattedAppBackup
        : '${(_databaseSizeKb + _documentsFileSizeKb).toStringAsFixed(1)} KB (local)';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_zip_outlined,
                      size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Medical Data Backup Size',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
              Text(
                backupSize,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Last Cloud Backup',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
              Text(
                _lastBackupDateTime,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Security & Emergency',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.blue),
            title: const Text('App Lock & Security'),
            subtitle: const Text('Biometrics, PIN & passcodes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push(AppRoutes.securitySetup);
            },
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.emergency, color: Colors.red),
            title: const Text('Emergency Lock Screen Info'),
            subtitle: const Text('Contacts, allergies & medical conditions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final lastProfileId =
                  await ref.read(secureStorageProvider).getLastProfileId();
              final profiles = ref.read(profilesProvider).value ?? [];
              if (profiles.isNotEmpty) {
                final activeProfileId = lastProfileId ?? profiles.first.id;
                if (context.mounted) {
                  context.push(
                      '${AppRoutes.emergencySettings}/$activeProfileId');
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please create a profile first.'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocalStorageSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Local Storage & Diagnostics',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.teal),
            title: const Text('Local Database'),
            trailing: Text(
              '${_databaseSizeKb.toStringAsFixed(1)} KB',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.attach_file, color: Colors.indigo),
            title: const Text('Attachments & Documents'),
            trailing: Text(
              '${_documentsFileSizeKb.toStringAsFixed(1)} KB',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Reset Database',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Erase all local health logs and data'),
            onTap: _resetDB,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'About & Privacy',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.blue),
            title: const Text('Privacy Policy & Disclaimers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPrivacyDisclaimerDialog,
          ),
        ],
      ),
    );
  }

  void _showPrivacyDisclaimerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Privacy & Disclaimer'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medical Disclaimer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Open Cloud Health is an informational logbook application for tracking personal medical histories, medication times, checkup schedules, and cycles. It does not provide professional medical advice, diagnosis, or treatment. Always consult a qualified physician or healthcare provider with any questions you have regarding a medical condition or treatment.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '• Local Storage: All medical histories, symptoms, medication logs, and biometrics are stored strictly on your local device. The developer has zero access to your information.\n\n'
                '• Cloud Backup: If you manually connect Google Drive, the database and attachments are stored directly in your personal Google Drive\'s secure App Data folder, accessible only by you. No data is shared with or sold to third parties.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
