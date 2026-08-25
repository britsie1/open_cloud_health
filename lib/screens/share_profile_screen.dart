import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/profile_share_config.dart';
import 'package:open_cloud_health/models/profile_share_models.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/services/profile_sharing_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ShareProfileScreen extends ConsumerStatefulWidget {
  const ShareProfileScreen({super.key, required this.profile});

  final Profile profile;

  @override
  ConsumerState<ShareProfileScreen> createState() => _ShareProfileScreenState();
}

class _ShareProfileScreenState extends ConsumerState<ShareProfileScreen> {
  String _profileImagePath = '';
  bool _isLoadingImage = true;
  bool _isGenerating = false;
  bool _isRevoking = false;
  bool _isPushingUpdate = false;
  bool _isEditingModules = false;

  ShareModuleOptions _options = const ShareModuleOptions();
  ShareCreationResult? _shareResult;
  ActiveShareConfig? _activeConfig;
  ShareSyncFrequency _syncFrequency = ShareSyncFrequency.manual;
  bool _syncWifiOnly = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    await Future.wait([
      _loadProfileImage(),
      _loadActiveShareConfig(),
    ]);
  }

  Future<void> _loadProfileImage() async {
    final path = await ref
        .read(profilesProvider.notifier)
        .getProfileImagePath(widget.profile.id);
    if (mounted) {
      setState(() {
        _profileImagePath = path;
        _isLoadingImage = false;
      });
    }
  }

  Future<void> _loadActiveShareConfig() async {
    final secureStorage = ref.read(secureStorageProvider);
    final activeConfig = await secureStorage.getActiveShareConfig(widget.profile.id);
    final frequency = await secureStorage.getShareSyncFrequency();
    final wifiOnly = await secureStorage.getShareSyncWifiOnly();

    if (mounted) {
      setState(() {
        _syncFrequency = frequency;
        _syncWifiOnly = wifiOnly;
        if (activeConfig != null) {
          _activeConfig = activeConfig;
          _options = activeConfig.options;
          final payload = ShareLinkPayload(
            fileId: activeConfig.driveFileId,
            key: activeConfig.encryptionKey,
            profileName: activeConfig.profileName,
            sharedBy: activeConfig.sharedBy,
          );
          _shareResult = ShareCreationResult(
            payload: payload,
            driveFileId: activeConfig.driveFileId,
            shareLink: payload.toUniversalUriString(),
          );
        }
      });
    }
  }

  Future<void> _generateShareQrCode({bool isManualPush = false}) async {
    setState(() {
      if (isManualPush) {
        _isPushingUpdate = true;
      } else {
        _isGenerating = true;
      }
      _errorMessage = null;
    });

    try {
      final sharingService = ref.read(profileSharingServiceProvider);
      final result = await sharingService.createOrUpdateProfileShare(
        profileId: widget.profile.id,
        options: _options,
        existingFileId: _activeConfig?.driveFileId ?? _shareResult?.driveFileId,
        existingEncryptionKey: _activeConfig?.encryptionKey,
      );

      final activeConfig = await ref.read(secureStorageProvider).getActiveShareConfig(widget.profile.id);

      if (mounted) {
        setState(() {
          _shareResult = result;
          _activeConfig = activeConfig;
          _isGenerating = false;
          _isPushingUpdate = false;
          _isEditingModules = false;
        });

        if (isManualPush) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Latest profile changes uploaded to Google Drive.'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _isPushingUpdate = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('FormatException: ', '');
        });
      }
    }
  }

  Future<void> _revokeShare() async {
    if (_shareResult == null && _activeConfig == null) return;
    final fileId = _shareResult?.driveFileId ?? _activeConfig!.driveFileId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Profile Sharing'),
        content: const Text(
          'Are you sure you want to stop sharing this profile? Anyone who scanned this QR code or has the link will lose access immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Revoke Access'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRevoking = true;
    });

    try {
      final sharingService = ref.read(profileSharingServiceProvider);
      await sharingService.revokeProfileShare(fileId, profileId: widget.profile.id);

      if (mounted) {
        setState(() {
          _shareResult = null;
          _activeConfig = null;
          _isRevoking = false;
          _isEditingModules = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile sharing has been revoked. Access deleted from Google Drive.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRevoking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke: $e')),
        );
      }
    }
  }

  Future<void> _onFrequencyChanged(ShareSyncFrequency? freq) async {
    if (freq == null) return;
    setState(() {
      _syncFrequency = freq;
    });
    await ref.read(secureStorageProvider).setShareSyncFrequency(freq);
  }

  Future<void> _onWifiOnlyChanged(bool val) async {
    setState(() {
      _syncWifiOnly = val;
    });
    await ref.read(secureStorageProvider).setShareSyncWifiOnly(val);
  }

  void _copyShareLink() {
    if (_shareResult == null) return;
    Clipboard.setData(ClipboardData(text: _shareResult!.shareLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Encrypted share link copied to clipboard!')),
    );
  }

  void _shareViaOtherApps() {
    if (_shareResult == null) return;
    Share.share(
      'View my read-only health summary in Open Cloud Health: ${_shareResult!.shareLink}',
      subject: 'Open Cloud Health Profile: ${widget.profile.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    ImageProvider avatarImage;
    if (_profileImagePath.isEmpty) {
      avatarImage = AssetImage(AppAssets.getGenderPlaceholder(profile.gender.name));
    } else {
      avatarImage = FileImage(File(_profileImagePath));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Profile (E2EE)'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Summary Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                        Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.2),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: _isLoadingImage ? null : avatarImage,
                        child: _isLoadingImage
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profile.name} ${profile.surname}',
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Age: ${profile.age} • ${profile.gender.name} • Blood: ${profile.bloodType}',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_shareResult == null) ...[
                // Module Selection Checklist
                Text(
                  'Select what to include in this share:',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose which health modules the receiver will be able to see in read-only mode.',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 12),

                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const CheckboxListTile(
                        value: true,
                        onChanged: null, // Demographics are required
                        title: Text('Demographics & Blood Type'),
                        subtitle: Text('Name, age, blood type, and profile photo'),
                        secondary: Icon(Icons.person_outline, color: Colors.teal),
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        value: _options.includeChronicConditions,
                        onChanged: (val) {
                          setState(() {
                            _options = _options.copyWith(includeChronicConditions: val ?? true);
                          });
                        },
                        title: const Text('Chronic Conditions'),
                        subtitle: const Text('Known ongoing health conditions'),
                        secondary: const Icon(Icons.health_and_safety_outlined, color: Colors.blue),
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        value: _options.includeAllergies,
                        onChanged: (val) {
                          setState(() {
                            _options = _options.copyWith(includeAllergies: val ?? true);
                          });
                        },
                        title: const Text('Allergies & Reactions'),
                        subtitle: const Text('Drug and environmental allergy notes'),
                        secondary: const Icon(Icons.warning_amber_outlined, color: Colors.orange),
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        value: _options.includeMedications,
                        onChanged: (val) {
                          setState(() {
                            _options = _options.copyWith(includeMedications: val ?? true);
                          });
                        },
                        title: const Text('Medications & Dosages'),
                        subtitle: const Text('Active prescriptions, schedule, and stock'),
                        secondary: const Icon(Icons.medication_outlined, color: Colors.indigo),
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        value: _options.includeVitals,
                        onChanged: (val) {
                          setState(() {
                            _options = _options.copyWith(includeVitals: val ?? true);
                          });
                        },
                        title: const Text('Vital Signs & Logs'),
                        subtitle: const Text('Blood pressure, sugar, weight'),
                        secondary: const Icon(Icons.monitor_heart_outlined, color: Colors.red),
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        value: _options.includeCheckups,
                        onChanged: (val) {
                          setState(() {
                            _options = _options.copyWith(includeCheckups: val ?? true);
                          });
                        },
                        title: const Text('Doctor Checkups & Visits'),
                        subtitle: const Text('Routine checkup intervals and visit logs'),
                        secondary: const Icon(Icons.calendar_today_outlined, color: Colors.cyan),
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        value: _options.includeHistory,
                        onChanged: (val) {
                          setState(() {
                            _options = _options.copyWith(includeHistory: val ?? true);
                          });
                        },
                        title: const Text('Medical History'),
                        subtitle: const Text('Timeline of past procedures and tests'),
                        secondary: const Icon(Icons.history_edu_outlined, color: Colors.purple),
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        value: _options.includeEmergency,
                        onChanged: (val) {
                          setState(() {
                            _options = _options.copyWith(includeEmergency: val ?? true);
                          });
                        },
                        title: const Text('Emergency Info & Contacts'),
                        subtitle: const Text('Next-of-kin contacts & emergency banner settings'),
                        secondary: const Icon(Icons.emergency_outlined, color: Colors.redAccent),
                      ),
                      if (profile.gender == Gender.female && profile.trackOvulation) ...[
                        const Divider(height: 1),
                        CheckboxListTile(
                          value: _options.includeFertility,
                          onChanged: (val) {
                            setState(() {
                              _options = _options.copyWith(includeFertility: val ?? true);
                            });
                          },
                          title: const Text('Period & Fertility Tracker'),
                          subtitle: const Text('Menstrual cycle records and symptom logs'),
                          secondary: const Icon(Icons.water_drop_outlined, color: Colors.pink),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateShareQrCode,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.qr_code),
                    label: Text(
                      _isGenerating ? 'Encrypting & Uploading to Drive...' : 'Generate Share QR Code',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else ...[
                // QR Code Display Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, size: 16, color: Colors.green),
                              SizedBox(width: 6),
                              Text(
                                'End-to-End Encrypted (AES-256)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Scan with Open Cloud Health',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Have the recipient open Open Cloud Health and tap "Scan Share QR Code".',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(height: 20),

                        // Render QR Code
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: _shareResult!.shareLink,
                            version: QrVersions.auto,
                            size: 220.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _copyShareLink,
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text('Copy Link'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _shareViaOtherApps,
                                icon: const Icon(Icons.share, size: 18),
                                label: const Text('Share Link'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Auto-Sync Schedule Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sync, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Share Sync Schedule',
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Control how often updated health records are pushed to Google Drive for this shared profile.',
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(height: 16),

                        // Frequency Dropdown
                        DropdownButtonFormField<ShareSyncFrequency>(
                          value: _syncFrequency,
                          decoration: InputDecoration(
                            labelText: 'Auto-Sync Frequency',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: ShareSyncFrequency.values.map((freq) {
                            return DropdownMenuItem(
                              value: freq,
                              child: Text(freq.displayName),
                            );
                          }).toList(),
                          onChanged: _onFrequencyChanged,
                        ),
                        const SizedBox(height: 12),

                        // Wi-Fi Only Switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Wi-Fi only', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('Only push sync updates over Wi-Fi to save mobile data', style: TextStyle(fontSize: 12)),
                          value: _syncWifiOnly,
                          onChanged: _onWifiOnlyChanged,
                        ),
                        const Divider(height: 24),

                        // Last uploaded info & Manual Push Update button
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Last updated on Drive:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(
                                    _activeConfig != null
                                        ? DateFormat.yMMMd().add_jm().format(_activeConfig!.lastSyncedAt)
                                        : 'Just now',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: (_isPushingUpdate || _isGenerating)
                                  ? null
                                  : () => _generateShareQrCode(isManualPush: true),
                              icon: _isPushingUpdate
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.cloud_upload_outlined, size: 16),
                              label: Text(_isPushingUpdate ? 'Pushing...' : 'Push Update Now'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Customize Shared Modules Accordion / Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ExpansionTile(
                    initiallyExpanded: _isEditingModules,
                    onExpansionChanged: (val) {
                      setState(() {
                        _isEditingModules = val;
                      });
                    },
                    leading: Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Shared Modules & Permissions', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Adjust which categories receiver can view', style: TextStyle(fontSize: 12)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              dense: true,
                              value: _options.includeChronicConditions,
                              onChanged: (val) => setState(() => _options = _options.copyWith(includeChronicConditions: val ?? true)),
                              title: const Text('Chronic Conditions'),
                            ),
                            CheckboxListTile(
                              dense: true,
                              value: _options.includeAllergies,
                              onChanged: (val) => setState(() => _options = _options.copyWith(includeAllergies: val ?? true)),
                              title: const Text('Allergies & Reactions'),
                            ),
                            CheckboxListTile(
                              dense: true,
                              value: _options.includeMedications,
                              onChanged: (val) => setState(() => _options = _options.copyWith(includeMedications: val ?? true)),
                              title: const Text('Medications & Dosages'),
                            ),
                            CheckboxListTile(
                              dense: true,
                              value: _options.includeVitals,
                              onChanged: (val) => setState(() => _options = _options.copyWith(includeVitals: val ?? true)),
                              title: const Text('Vital Signs & Logs'),
                            ),
                            CheckboxListTile(
                              dense: true,
                              value: _options.includeCheckups,
                              onChanged: (val) => setState(() => _options = _options.copyWith(includeCheckups: val ?? true)),
                              title: const Text('Doctor Checkups & Visits'),
                            ),
                            CheckboxListTile(
                              dense: true,
                              value: _options.includeHistory,
                              onChanged: (val) => setState(() => _options = _options.copyWith(includeHistory: val ?? true)),
                              title: const Text('Medical History'),
                            ),
                            CheckboxListTile(
                              dense: true,
                              value: _options.includeEmergency,
                              onChanged: (val) => setState(() => _options = _options.copyWith(includeEmergency: val ?? true)),
                              title: const Text('Emergency Info & Contacts'),
                            ),
                            if (profile.gender == Gender.female && profile.trackOvulation)
                              CheckboxListTile(
                                dense: true,
                                value: _options.includeFertility,
                                onChanged: (val) => setState(() => _options = _options.copyWith(includeFertility: val ?? true)),
                                title: const Text('Period & Fertility Tracker'),
                              ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (_isGenerating || _isPushingUpdate) ? null : () => _generateShareQrCode(isManualPush: true),
                                child: Text(_isGenerating ? 'Updating...' : 'Save & Update Shared Modules'),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Revoke Share Button Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: _isRevoking ? null : _revokeShare,
                        icon: _isRevoking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_forever),
                        label: const Text('Revoke Access & Delete from Drive'),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
