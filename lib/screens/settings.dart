import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/backup_frequency.dart';
import 'package:open_cloud_health/models/storage_info.dart';
import 'package:open_cloud_health/providers/allergies_provider.dart';
import 'package:open_cloud_health/providers/checkups_provider.dart';
import 'package:open_cloud_health/providers/emergency_provider.dart';
import 'package:open_cloud_health/providers/history_provider.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';
import 'package:open_cloud_health/providers/period_provider.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/providers/theme_provider.dart';
import 'package:open_cloud_health/providers/vitals_provider.dart';
import 'package:open_cloud_health/screens/emergency_settings.dart';
import 'package:open_cloud_health/screens/security_setup.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/theme/app_theme_mode.dart';
import 'package:open_cloud_health/theme/app_theme_preset.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/utils/format_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared helper for HomeScreen-inspired rounded surface containers.
BoxDecoration _buildSurfaceCardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return BoxDecoration(
    color: theme.cardTheme.color ?? theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(24),
    border: isDark ? Border.all(color: const Color(0xFF2C2C2C)) : null,
    boxShadow: isDark
        ? null
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
  );
}

/// Shared monotone icon badge used across Settings and its sub-screens.
Widget _buildMonotoneIconBadge(
  BuildContext context,
  IconData icon, {
  double size = 22,
  double padding = 11,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: theme.colorScheme.onSurface.withOpacity(isDark ? 0.08 : 0.05),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(
      icon,
      size: size,
      color: theme.colorScheme.onSurface,
    ),
  );
}

/// Shared HomeScreen-style section header with monotone icon and bold title.
Widget _buildSectionHeader(
  BuildContext context, {
  required IconData icon,
  required String title,
  Widget? trailing,
}) {
  final onSurface = Theme.of(context).colorScheme.onSurface;
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Row(
          children: [
            Icon(icon, color: onSurface, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      if (trailing != null) trailing,
    ],
  );
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _databaseSizeKb = 0;
  double _documentsFileSizeKb = 0;
  bool _isConnectedToGoogle = false;
  String? _connectedEmail;

  @override
  void initState() {
    super.initState();
    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    ref.read(appDatabaseProvider).getDatabaseSize().then((value) {
      if (mounted) {
        setState(() => _databaseSizeKb = value / 1024);
      }
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final files = appDir.listSync(recursive: true);
      var size = 0;
      if (files.isNotEmpty) {
        size = files
            .where((file) => p.basename(file.path) != 'opencloudhealth.db')
            .map((file) => file is File ? File(file.path).lengthSync() : 0)
            .fold(0, (prev, elem) => prev + elem);
      }
      if (mounted) {
        setState(() => _documentsFileSizeKb = size / 1024);
      }
    } catch (e) {
      debugPrint('Error calculating local document size: $e');
    }

    try {
      final user = await ref.read(backupServiceProvider).getConnectedUser();
      if (mounted) {
        setState(() {
          _isConnectedToGoogle = user != null;
          _connectedEmail = user?.email;
        });
      }
    } catch (e) {
      debugPrint('Error checking Google connection: $e');
    }
  }

  Future<void> _openScreen(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (mounted) {
      _loadSummaries();
    }
  }

  Future<void> _openSecuritySetup() async {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      await context.push(AppRoutes.securitySetup);
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SecuritySetupScreen()),
      );
    }
    if (mounted) {
      _loadSummaries();
    }
  }

  Future<void> _openEmergencySettings() async {
    final lastProfileId =
        await ref.read(secureStorageProvider).getLastProfileId();
    if (!mounted) return;
    final profiles = ref.read(profilesProvider).value ?? [];
    if (profiles.isNotEmpty) {
      final activeProfileId = lastProfileId ?? profiles.first.id;
      if (!mounted) return;
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        await context.push('${AppRoutes.emergencySettings}/$activeProfileId');
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                EmergencySettingsScreen(profileId: activeProfileId),
          ),
        );
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
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = ref.watch(themeSettingsProvider);
    final totalLocalKb =
        (_databaseSizeKb + _documentsFileSizeKb).toStringAsFixed(1);
    final googleSubtitle = _isConnectedToGoogle
        ? (_connectedEmail != null && _connectedEmail!.isNotEmpty
            ? 'Connected • $_connectedEmail'
            : 'Connected to Google Drive')
        : 'Not connected • Cloud sync';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: _buildSurfaceCardDecoration(context),
              child: Column(
                children: [
                  _SettingsNavTile(
                    icon: Icons.palette_outlined,
                    title: 'Appearance & Theme',
                    subtitle:
                        '${themeSettings.themeMode.displayName} • ${themeSettings.preset.name}',
                    onTap: () => _openScreen(const AppearanceSettingsScreen()),
                  ),
                  const Divider(height: 1, indent: 72, endIndent: 16),
                  _SettingsNavTile(
                    icon: Icons.cloud_outlined,
                    title: 'Google Drive Backup',
                    subtitle: googleSubtitle,
                    onTap: () => _openScreen(const CloudBackupSettingsScreen()),
                  ),
                  const Divider(height: 1, indent: 72, endIndent: 16),
                  _SettingsNavTile(
                    icon: Icons.lock_outline,
                    title: 'App Lock & Security',
                    subtitle: 'Biometrics, PIN & encryption',
                    onTap: _openSecuritySetup,
                  ),
                  const Divider(height: 1, indent: 72, endIndent: 16),
                  _SettingsNavTile(
                    icon: Icons.medical_information_outlined,
                    title: 'Emergency Lock Screen Info',
                    subtitle: 'Contacts, allergies & conditions',
                    onTap: _openEmergencySettings,
                  ),
                  const Divider(height: 1, indent: 72, endIndent: 16),
                  _SettingsNavTile(
                    icon: Icons.folder_outlined,
                    title: 'Local Storage & Backup',
                    subtitle: '$totalLocalKb KB • Export, import & reset',
                    onTap: () =>
                        _openScreen(const LocalStorageSettingsScreen()),
                  ),
                  const Divider(height: 1, indent: 72, endIndent: 16),
                  _SettingsNavTile(
                    icon: Icons.info_outline,
                    title: 'About & Privacy',
                    subtitle: 'Privacy policy & disclaimer',
                    onTap: () => _openScreen(const AboutSettingsScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      horizontalTitleGap: 14,
      leading: _buildMonotoneIconBadge(context, icon),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3.0),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

// =============================================================================
// 1. APPEARANCE & THEME SUB-SCREEN
// =============================================================================

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeSettings = ref.watch(themeSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance & Theme'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              icon: Icons.brightness_6_outlined,
              title: 'Theme Mode',
            ),
            const SizedBox(height: 12),
            Container(
              decoration: _buildSurfaceCardDecoration(context),
              child: Column(
                children: [
                  for (var i = 0; i < AppThemeMode.values.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 76, endIndent: 20),
                    Builder(
                      builder: (context) {
                        final mode = AppThemeMode.values[i];
                        final isSelected = themeSettings.themeMode == mode;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          leading: _buildMonotoneIconBadge(context, mode.icon),
                          title: Text(
                            mode.displayName,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            mode.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.onSurface,
                                )
                              : Icon(
                                  Icons.circle_outlined,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                          onTap: () {
                            ref
                                .read(themeNotifierProvider.notifier)
                                .setThemeMode(mode);
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),
            _buildSectionHeader(
              context,
              icon: Icons.palette_outlined,
              title: 'Color Theme',
            ),
            const SizedBox(height: 12),
            Container(
              decoration: _buildSurfaceCardDecoration(context),
              child: Column(
                children: [
                  for (var i = 0; i < AppThemePresets.all.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 76, endIndent: 20),
                    Builder(
                      builder: (context) {
                        final preset = AppThemePresets.all[i];
                        final isSelected = themeSettings.presetId == preset.id;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: preset.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            preset.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            preset.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.onSurface,
                                )
                              : Icon(
                                  Icons.circle_outlined,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                          onTap: () {
                            ref
                                .read(themeNotifierProvider.notifier)
                                .setThemePreset(preset.id);
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 2. GOOGLE DRIVE BACKUP SUB-SCREEN
// =============================================================================

class CloudBackupSettingsScreen extends ConsumerStatefulWidget {
  const CloudBackupSettingsScreen({super.key});

  @override
  ConsumerState<CloudBackupSettingsScreen> createState() =>
      _CloudBackupSettingsScreenState();
}

class _CloudBackupSettingsScreenState
    extends ConsumerState<CloudBackupSettingsScreen> {
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
      final files = appDir.listSync(recursive: true);
      var size = 0;
      if (files.isNotEmpty) {
        size = files
            .where((file) => p.basename(file.path) != 'opencloudhealth.db')
            .map((file) => file is File ? File(file.path).lengthSync() : 0)
            .fold(0, (prev, elem) => prev + elem);
      }
      if (mounted) {
        setState(() => _documentsFileSizeKb = size / 1024);
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
                    ? 'Medical data encrypted & backed up to Google Drive'
                    : 'Medical data backed up to Google Drive',
              ),
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

  Future<void> _toggleBackupWifiOnly(bool val) async {
    await ref.read(secureStorageProvider).setBackupWifiOnly(val);
    setState(() => _isBackupWifiOnly = val);
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

  void _showBackupFrequencyDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 8.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildMonotoneIconBadge(context, Icons.schedule_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Back up to Google Drive',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Idle Hours Auto-Backup',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.nightlight_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Automated backups run overnight during idle hours (2:00 AM – 5:00 AM) when your device is charging and connected.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
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
                              content: Text(
                                  'Backup frequency set to ${freq.displayName}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Radio<BackupFrequency>(
                              value: freq,
                              groupValue: _frequency,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              activeColor: theme.colorScheme.onSurface,
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
                                        content: Text(
                                            'Backup frequency set to ${val.displayName}'),
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
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    freq.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = _storageInfo;
    final backupSize = (info != null && info.appBackupBytes > 0)
        ? info.formattedAppBackup
        : '${(_databaseSizeKb + _documentsFileSizeKb).toStringAsFixed(1)} KB (local)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Drive Backup'),
        actions: [
          if (_isConnectedToGoogle)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Storage Info',
              onPressed: _checkGoogleConnection,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: _isLoadingStorage
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: CircularProgressIndicator(),
                ),
              )
            : !_isConnectedToGoogle
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        context,
                        icon: Icons.cloud_outlined,
                        title: 'Cloud Connection',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: _buildSurfaceCardDecoration(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildMonotoneIconBadge(
                                    context, Icons.cloud_sync_outlined),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Google Drive Backup',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Backup medical data to your Drive',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Connect your Google Account to back up all patient histories, medication schedules, and attachments securely into your personal Google Drive App Data folder.',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _connectToGoogle,
                                icon: const Icon(Icons.add_to_drive),
                                label: const Text('Connect to Google Drive'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.onSurface,
                                  foregroundColor: theme.colorScheme.surface,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        context,
                        icon: Icons.person_outline,
                        title: 'Connected Account',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _buildSurfaceCardDecoration(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: theme.colorScheme.onSurface
                                      .withOpacity(0.08),
                                  backgroundImage: (info?.photoUrl != null &&
                                          info!.photoUrl!.isNotEmpty)
                                      ? NetworkImage(info.photoUrl!)
                                      : null,
                                  child: (info?.photoUrl == null ||
                                          info!.photoUrl!.isEmpty)
                                      ? Text(
                                          (info?.displayName?.isNotEmpty ==
                                                  true)
                                              ? info!.displayName![0]
                                                  .toUpperCase()
                                              : (info?.userEmail?.isNotEmpty ==
                                                      true
                                                  ? info!.userEmail![0]
                                                      .toUpperCase()
                                                  : 'G'),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        info?.displayName ?? 'Google Account',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (info?.userEmail != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          info!.userEmail!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isBackingUp ? null : _uploadBackup,
                                icon: _isBackingUp
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.colorScheme.surface,
                                        ),
                                      )
                                    : const Icon(Icons.cloud_upload_outlined),
                                label: Text(
                                  _isBackingUp
                                      ? 'Backing up...'
                                      : 'Back Up Now',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.onSurface,
                                  foregroundColor: theme.colorScheme.surface,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        context,
                        icon: Icons.pie_chart_outline,
                        title: 'Google Storage',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _buildSurfaceCardDecoration(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (info != null) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${info.formattedUsed} of ${info.formattedTotal} used',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (!info.isUnlimited)
                                    Text(
                                      FormatUtils.formatPercentage(
                                          info.usageFraction),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: info.isUnlimited
                                      ? null
                                      : info.usageFraction,
                                  minHeight: 8,
                                  backgroundColor: theme.colorScheme.onSurface
                                      .withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${info.formattedAvailable} available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(height: 1),
                              ),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        _isE2eEnabled
                                            ? Icons.lock_outline
                                            : Icons.folder_zip_outlined,
                                        size: 18,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          _isE2eEnabled
                                              ? 'Encrypted Backup Size'
                                              : 'Medical Data Backup Size',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  backupSize,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_outlined,
                                        size: 18,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          'Last Cloud Backup',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _lastBackupDateTime,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        context,
                        icon: Icons.schedule_outlined,
                        title: 'Auto-Backup Schedule',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: _buildSurfaceCardDecoration(context),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 6),
                              leading: _buildMonotoneIconBadge(
                                  context, Icons.schedule_outlined),
                              title: Text(
                                'Back up to Google Drive',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 3.0),
                                child: Text(
                                  _getFrequencySubtitle(_frequency),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onTap: _showBackupFrequencyDialog,
                            ),
                            const Divider(height: 1, indent: 76, endIndent: 20),
                            SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 4),
                              secondary: _buildMonotoneIconBadge(
                                  context, Icons.wifi_outlined),
                              title: Text(
                                'Back up over Wi-Fi only',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  _isBackupWifiOnly
                                      ? 'Avoid cellular data usage'
                                      : 'Back up over Wi-Fi or cellular data',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              value: _isBackupWifiOnly,
                              onChanged: _toggleBackupWifiOnly,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: _openManageGoogleStorage,
                            icon: Icon(
                              Icons.open_in_new,
                              size: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                            label: Text(
                              'Manage Google Storage',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _disconnectGoogle,
                            child: Text(
                              'Disconnect',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}

// =============================================================================
// 3. LOCAL STORAGE & BACKUP SUB-SCREEN
// =============================================================================

class LocalStorageSettingsScreen extends ConsumerStatefulWidget {
  const LocalStorageSettingsScreen({super.key});

  @override
  ConsumerState<LocalStorageSettingsScreen> createState() =>
      _LocalStorageSettingsScreenState();
}

class _LocalStorageSettingsScreenState
    extends ConsumerState<LocalStorageSettingsScreen> {
  double _databaseSizeKb = 0;
  double _documentsFileSizeKb = 0;

  @override
  void initState() {
    super.initState();
    _loadLocalSizes();
  }

  Future<void> _loadLocalSizes() async {
    ref.read(appDatabaseProvider).getDatabaseSize().then((value) {
      if (mounted) {
        setState(() => _databaseSizeKb = value / 1024);
      }
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final files = appDir.listSync(recursive: true);
      var size = 0;

      if (files.isNotEmpty) {
        size = files
            .where((file) => p.basename(file.path) != 'opencloudhealth.db')
            .map((file) => file is File ? File(file.path).lengthSync() : 0)
            .fold(0, (previousValue, element) => previousValue + element);
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

  Future<void> _exportLocalBackup() async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isPasswordProtected = false;
    String? errorMessage;
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.file_upload_outlined,
                  color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
              const Expanded(
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
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPasswordProtected
                            ? Icons.lock_outline
                            : Icons.shield_outlined,
                        color: theme.colorScheme.onSurface,
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
                  Text(
                    'Set a password to protect this backup file when sharing via WhatsApp, email, or AirDrop:',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
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
            FilledButton.icon(
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
    final theme = Theme.of(context);
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.file_download_outlined,
                    color: theme.colorScheme.onSurface),
                const SizedBox(width: 8),
                const Expanded(
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              FilledButton(
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _resetDB() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: theme.colorScheme.onSurface),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Reset All Data',
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(notificationServiceProvider).cancelAllNotifications();
    await ref.read(fileServiceProvider).deleteAllLocalFiles();
    await ref.read(appDatabaseProvider).resetDatabase();
    await ref.read(secureStorageProvider).clear();

    ref.invalidate(appDatabaseProvider);
    ref.invalidate(profilesProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(allergiesProvider);
    ref.invalidate(medicationsProvider);
    ref.invalidate(medicationLogsProvider);
    ref.invalidate(checkupsProvider);
    ref.invalidate(periodProvider);
    ref.invalidate(vitalsProvider);
    ref.invalidate(emergencyContactsProvider);
    ref.invalidate(lockScreenSettingsProvider);
    ref.invalidate(primaryProfileIdProvider);

    if (!mounted) return;
    context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Storage & Backup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              icon: Icons.storage_outlined,
              title: 'On-Device Storage',
            ),
            const SizedBox(height: 12),
            Container(
              decoration: _buildSurfaceCardDecoration(context),
              child: Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    leading:
                        _buildMonotoneIconBadge(context, Icons.storage_outlined),
                    title: Text(
                      'Local Database',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Encrypted SQLite medical records',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Text(
                      '${_databaseSizeKb.toStringAsFixed(1)} KB',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 76, endIndent: 20),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    leading: _buildMonotoneIconBadge(
                        context, Icons.attach_file_outlined),
                    title: Text(
                      'Attachments & Documents',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Profile photos, lab PDFs & images',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Text(
                      '${_documentsFileSizeKb.toStringAsFixed(1)} KB',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),
            _buildSectionHeader(
              context,
              icon: Icons.folder_outlined,
              title: 'Local Backup Files',
            ),
            const SizedBox(height: 12),
            Container(
              decoration: _buildSurfaceCardDecoration(context),
              child: Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: _buildMonotoneIconBadge(
                        context, Icons.file_upload_outlined),
                    title: Text(
                      'Export Local Backup (.ochbackup)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: Text(
                        'Bundle DB, photos & PDFs to share via WhatsApp or Files',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onTap: _exportLocalBackup,
                  ),
                  const Divider(height: 1, indent: 76, endIndent: 20),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: _buildMonotoneIconBadge(
                        context, Icons.file_download_outlined),
                    title: Text(
                      'Import Local Backup',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: Text(
                        'Restore from a .ochbackup or encrypted file',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onTap: _importLocalBackup,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),
            _buildSectionHeader(
              context,
              icon: Icons.delete_outline,
              title: 'Data Reset',
            ),
            const SizedBox(height: 12),
            Container(
              decoration: _buildSurfaceCardDecoration(context),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading:
                    _buildMonotoneIconBadge(context, Icons.delete_outline),
                title: Text(
                  'Reset Database',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Text(
                    'Erase all local health logs and data',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onTap: _resetDB,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 4. ABOUT & PRIVACY SUB-SCREEN
// =============================================================================

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Privacy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              icon: Icons.health_and_safety_outlined,
              title: 'Medical Disclaimer',
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _buildSurfaceCardDecoration(context),
              child: Text(
                'Open Cloud Health is an informational logbook application for tracking personal medical histories, medication times, checkup schedules, and cycles. It does not provide professional medical advice, diagnosis, or treatment. Always consult a qualified physician or healthcare provider with any questions you have regarding a medical condition or treatment.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),
            _buildSectionHeader(
              context,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _buildSurfaceCardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMonotoneIconBadge(
                          context, Icons.phone_android_outlined),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Local-First Storage',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All medical histories, symptoms, medication logs, and biometrics are stored strictly on your local device. The developer has zero access to your information.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMonotoneIconBadge(context, Icons.lock_outline),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Zero-Knowledge Cloud Backup',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'If you manually connect Google Drive, the database and attachments are stored directly in your personal Google Drive\'s secure App Data folder. With End-to-End Encryption enabled, your backups are client-side encrypted with AES-256 before upload.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
