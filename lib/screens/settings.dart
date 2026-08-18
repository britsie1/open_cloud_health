import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/backup_frequency.dart';
import 'package:open_cloud_health/models/storage_info.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/utils/format_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  bool _isE2eEnabled = false;
  BackupFrequency _frequency = BackupFrequency.manual;
  bool _isBackupWifiOnly = true;
  GoogleStorageInfo? _storageInfo;
  String _lastBackupDateTime = 'Not connected';

  @override
  void initState() {
    super.initState();
    _loadLocalSizes();
    _checkGoogleConnection();
  }

  Future<void> _loadLocalSizes() async {
    ref.read(appDatabaseProvider).getDatabaseSize().then((value) {
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
    final secureStorage = ref.read(secureStorageProvider);
    final user = await backupService.getConnectedUser();
    final isE2e = await secureStorage.isE2eBackupEnabled();
    final frequency = await secureStorage.getBackupFrequency();
    final wifiOnly = await secureStorage.getBackupWifiOnly();

    if (user != null) {
      final info = await backupService.getGoogleStorageInfo(interactive: false);
      if (mounted) {
        setState(() {
          _isConnectedToGoogle = true;
          _isE2eEnabled = isE2e || (info?.isE2eEncrypted ?? false);
          _frequency = frequency;
          _isBackupWifiOnly = wifiOnly;
          _storageInfo = info;
          _lastBackupDateTime = info?.lastBackupDateTime ?? 'Never';
          _isLoadingStorage = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isConnectedToGoogle = false;
          _isE2eEnabled = isE2e;
          _frequency = frequency;
          _isBackupWifiOnly = wifiOnly;
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
      final secureStorage = ref.read(secureStorageProvider);
      final info = await backupService.getGoogleStorageInfo(interactive: true);
      final isE2e = await secureStorage.isE2eBackupEnabled();
      final frequency = await secureStorage.getBackupFrequency();
      final wifiOnly = await secureStorage.getBackupWifiOnly();

      if (info != null) {
        if (mounted) {
          setState(() {
            _isConnectedToGoogle = true;
            _isE2eEnabled = isE2e || info.isE2eEncrypted;
            _frequency = frequency;
            _isBackupWifiOnly = wifiOnly;
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
        final updatedInfo = await ref
            .read(backupServiceProvider)
            .getGoogleStorageInfo(interactive: false);
        final isE2e =
            await ref.read(secureStorageProvider).isE2eBackupEnabled();

        if (mounted) {
          setState(() {
            _lastBackupDateTime = '$formattedTime UTC';
            _isE2eEnabled = isE2e;
            if (updatedInfo != null) {
              _storageInfo = updatedInfo;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isE2eEnabled
                    ? 'Medical data encrypted & backed up to Google Drive 🔒'
                    : 'Medical data backed up to Google Drive',
              ),
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

  void _showBackupFrequencyDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.schedule, color: Colors.blue.shade700, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Back up to Google Drive',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Idle Hours Auto-Backup',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.nightlight_round,
                            size: 18, color: Colors.blue.shade800),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Automated backups run overnight during idle hours (2:00 AM – 5:00 AM) when your device is charging and connected.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...BackupFrequency.values.map((freq) {
                    final isSelected = _frequency == freq;
                    return InkWell(
                      onTap: () async {
                        await ref
                            .read(secureStorageProvider)
                            .setBackupFrequency(freq);
                        setState(() => _frequency = freq);
                        setModalState(() {});
                        if (mounted && ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Backup frequency set to ${freq.displayName}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Radio<BackupFrequency>(
                              value: freq,
                              groupValue: _frequency,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              activeColor: Colors.blue.shade700,
                              onChanged: (BackupFrequency? val) async {
                                if (val != null) {
                                  await ref
                                      .read(secureStorageProvider)
                                      .setBackupFrequency(val);
                                  setState(() => _frequency = val);
                                  setModalState(() {});
                                  if (mounted && ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Backup frequency set to ${val.displayName}'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    freq.displayName,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 14,
                                      color: isSelected ? Colors.blue.shade900 : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    freq.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.blue.shade800 : Colors.grey.shade600,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBackupWifiOnly(bool val) async {
    await ref.read(secureStorageProvider).setBackupWifiOnly(val);
    setState(() => _isBackupWifiOnly = val);
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

    await ref.read(appDatabaseProvider).resetDatabase();

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

  String _getFrequencySubtitle(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.daily:
        return 'Daily • Idle hours (2:00 AM – 5:00 AM)';
      case BackupFrequency.weekly:
        return 'Weekly • Idle hours (2:00 AM – 5:00 AM)';
      case BackupFrequency.monthly:
        return 'Monthly • Idle hours (2:00 AM – 5:00 AM)';
      case BackupFrequency.manual:
        return 'Only when I tap "Back up"';
      case BackupFrequency.never:
        return 'Never';
    }
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
                      Row(
                        children: [
                          Text(
                            'Google Drive Backup',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isE2eEnabled) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock,
                                      size: 10, color: Colors.green.shade900),
                                  const SizedBox(width: 2),
                                  Text(
                                    'E2E',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _isConnectedToGoogle
                            ? (_isE2eEnabled
                                ? 'Encrypted cloud backup active 🔒'
                                : 'Cloud backup active')
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
              // Account Tile
              _buildAccountRow(),
              const SizedBox(height: 16),

              // Storage Usage Bar
              _buildStorageMeter(),
              const SizedBox(height: 16),

              // Medical Backup stats
              _buildBackupStats(),
              const SizedBox(height: 16),

              // Auto-Backup Settings Card (WhatsApp style)
              _buildAutoBackupSettingsCard(),
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
                      label:
                          Text(_isBackingUp ? 'Backing up...' : 'Back Up Now'),
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
                  Icon(
                    _isE2eEnabled
                        ? Icons.lock_outline
                        : Icons.folder_zip_outlined,
                    size: 16,
                    color: _isE2eEnabled
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isE2eEnabled
                        ? 'Encrypted Backup Size'
                        : 'Medical Data Backup Size',
                    style: const TextStyle(fontSize: 13),
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

  Widget _buildAutoBackupSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.schedule_outlined,
                  color: Colors.blue.shade700, size: 20),
            ),
            title: const Text(
              'Back up to Google Drive',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: Text(
                _getFrequencySubtitle(_frequency),
                style: TextStyle(
                  fontSize: 12,
                  color: _frequency.isAutomated
                      ? Colors.blue.shade800
                      : Colors.grey.shade700,
                  fontWeight: _frequency.isAutomated
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: _showBackupFrequencyDialog,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.wifi, color: Colors.blue.shade700, size: 20),
            ),
            title: const Text(
              'Back up over Wi-Fi only',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                _isBackupWifiOnly
                    ? 'Avoid cellular data usage'
                    : 'Back up over Wi-Fi or cellular data',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            value: _isBackupWifiOnly,
            onChanged: _toggleBackupWifiOnly,
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
            subtitle: const Text('Biometrics, passcodes & E2E encrypted backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await context.push(AppRoutes.securitySetup);
              _checkGoogleConnection();
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
              if (!mounted) return;
              final profiles = ref.read(profilesProvider).value ?? [];
              if (profiles.isNotEmpty) {
                final activeProfileId = lastProfileId ?? profiles.first.id;
                if (mounted) {
                  context.push(
                      '${AppRoutes.emergencySettings}/$activeProfileId');
                }
              } else {
                if (mounted) {
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

  Future<void> _exportLocalBackup() async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isPasswordProtected = false;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.file_upload_outlined, color: Colors.teal),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Export Local Backup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Packages your medical records, profile images, and PDF attachments into a single AES-256 encrypted .ochbackup file.',
                  style: TextStyle(fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPasswordProtected
                            ? Icons.lock
                            : Icons.shield_outlined,
                        color: isPasswordProtected
                            ? Colors.teal
                            : Colors.grey.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isPasswordProtected
                              ? 'Password Protection'
                              : 'Standard Device-Key Protection',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Switch(
                        value: isPasswordProtected,
                        activeColor: Colors.teal,
                        onChanged: (val) {
                          setDialogState(() {
                            isPasswordProtected = val;
                            errorMessage = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (isPasswordProtected) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Set a password to protect this backup file when sharing via WhatsApp, email, or AirDrop:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Backup Password',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.share, size: 16),
              label: const Text('Export & Share'),
              onPressed: () async {
                if (isPasswordProtected) {
                  if (passwordController.text.isEmpty) {
                    setDialogState(
                        () => errorMessage = 'Please enter a password.');
                    return;
                  }
                  if (passwordController.text !=
                      confirmPasswordController.text) {
                    setDialogState(
                        () => errorMessage = 'Passwords do not match.');
                    return;
                  }
                }
                Navigator.of(ctx)
                    .pop(isPasswordProtected ? passwordController.text : '');
              },
            ),
          ],
        ),
      ),
    ).then((result) async {
      if (result != null && result is String && mounted) {
        final customPassword = result.isNotEmpty ? result : null;
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Generating encrypted backup bundle...'),
              duration: Duration(seconds: 2),
            ),
          );

          final backupFile = await ref
              .read(backupServiceProvider)
              .exportLocalBackup(customPassword: customPassword);

          if (await backupFile.exists() && mounted) {
            await Share.shareXFiles(
              [XFile(backupFile.path)],
              text: 'Open Cloud Health Encrypted Backup (.ochbackup)',
            );
          }
        } catch (e) {
          debugPrint('Export error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Export failed: $e')),
            );
          }
        }
      }
    });
  }

  Future<void> _importLocalBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        return;
      }

      final filePath = result.files.single.path!;
      final file = File(filePath);

      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected backup file not found.')),
          );
        }
        return;
      }

      final passwordController = TextEditingController();

      if (!mounted) return;

      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.file_download_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Import Local Backup',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File: ${p.basename(filePath)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'If this backup was protected with a password, enter it below. Otherwise, leave it blank to use the device master key:',
                    style: TextStyle(fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password (Optional)',
                      hintText: 'Leave empty if no password was set',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Restore Backup'),
              ),
            ],
          ),
        ),
      );

      if (shouldProceed == true && mounted) {
        final enteredPassword = passwordController.text.trim().isNotEmpty
            ? passwordController.text.trim()
            : null;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restoring medical records and files...'),
            duration: Duration(seconds: 2),
          ),
        );

        await ref.read(backupServiceProvider).importLocalBackup(
              file,
              customPassword: enteredPassword,
            );

        await _loadLocalSizes();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Backup restored successfully! All profiles and attachments loaded.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Import error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to restore backup: ${e is FormatException ? e.message : e}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
            leading:
                const Icon(Icons.file_upload_outlined, color: Colors.teal),
            title: const Text('Export Local Backup (.ochbackup)'),
            subtitle: const Text(
                'Bundle DB, photos & PDFs to share via WhatsApp or Files'),
            trailing: const Icon(Icons.share, size: 20),
            onTap: _exportLocalBackup,
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading:
                const Icon(Icons.file_download_outlined, color: Colors.blue),
            title: const Text('Import Local Backup'),
            subtitle: const Text('Restore from a .ochbackup or encrypted file'),
            trailing: const Icon(Icons.folder_open, size: 20),
            onTap: _importLocalBackup,
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
                '• Cloud Backup: If you manually connect Google Drive, the database and attachments are stored directly in your personal Google Drive\'s secure App Data folder. With End-to-End Encryption enabled, your backups are client-side encrypted with AES-256 before upload.',
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
