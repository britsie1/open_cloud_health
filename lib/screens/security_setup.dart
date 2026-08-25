import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/services/backup_encryption_service.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/utils/security_utils.dart';

class SecuritySetupScreen extends ConsumerStatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  ConsumerState<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends ConsumerState<SecuritySetupScreen> with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isDeviceSecure = false;
  bool _isLocalAuthEnabled = false;
  bool _isBannerDismissed = false;
  bool _isE2eEnabled = false;
  bool _isStrictBiometrics = false;
  int _autoLockGraceSeconds = 30;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCapabilitiesAndLoadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkCapabilitiesAndLoadSettings();
    }
  }

  Future<void> _checkCapabilitiesAndLoadSettings() async {
    try {
      final isDeviceSecure = await SecurityUtils.isDeviceSecure();
      var isEnabled = await ref.read(appDatabaseProvider).isLocalAuthEnabled();
      final isDismissed = await ref.read(appDatabaseProvider).isSecurityBannerDismissed();
      final isE2e = await ref.read(secureStorageProvider).isE2eBackupEnabled();
      final isStrict = await ref.read(secureStorageProvider).isStrictBiometricsOnly();
      int graceSeconds = 30;
      try {
        graceSeconds = await ref.read(secureStorageProvider).getAutoLockGraceSeconds();
      } catch (_) {}

      if (isEnabled && !isDeviceSecure) {
        // Auto-disable in database since the device lock was removed
        await ref.read(appDatabaseProvider).setLocalAuthEnabled(false);
        isEnabled = false;
      }

      if (mounted) {
        setState(() {
          _isDeviceSecure = isDeviceSecure;
          _isLocalAuthEnabled = isEnabled;
          _isBannerDismissed = isDismissed;
          _isE2eEnabled = isE2e;
          _isStrictBiometrics = isStrict;
          _autoLockGraceSeconds = graceSeconds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading capabilities: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLocalAuth(bool value) async {
    if (value) {
      // Trying to enable App Lock: run a challenge to verify it works!
      if (!_isDeviceSecure) {
        _showSetUpSettingsDialog();
        return;
      }

      try {
        final isE2e =
            await ref.read(secureStorageProvider).isE2eBackupEnabled();
        final authenticated = await _auth.authenticate(
          localizedReason: 'Authenticate to enable App Lock protection',
          options: AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: isE2e,
          ),
        );

        if (authenticated) {
          await ref.read(appDatabaseProvider).setLocalAuthEnabled(true);
          setState(() {
            _isLocalAuthEnabled = true;
          });
          _showSnackbar('App Lock enabled successfully!');
        }
      } on PlatformException catch (e) {
        debugPrint(e.toString());
        _showSecurityAlert(
          title: 'Authentication Error',
          message: 'Could not authenticate. Please verify your device lock settings and try again.',
        );
      }
    } else {
      // Disabling App Lock
      try {
        final authenticated = await _auth.authenticate(
          localizedReason: 'Authenticate to turn off App Lock protection',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        if (authenticated) {
          await ref.read(appDatabaseProvider).setLocalAuthEnabled(false);
          setState(() {
            _isLocalAuthEnabled = false;
          });
          _showSnackbar('App Lock disabled.');
        }
      } on PlatformException catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  Future<void> _toggleStrictBiometrics(bool value) async {
    if (value) {
      // Explain benefits and risks before turning strict biometrics ON
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.fingerprint, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Strict Biometrics Only',
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
                // Benefits box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 16, color: Colors.blue.shade900),
                          const SizedBox(width: 6),
                          Text(
                            'Why Turn This On?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Hides the "Use Pattern / PIN" fallback button on the biometric prompt.\n'
                        '• Prevents kids, friends, or family who know your phone screen pattern from opening Open Cloud Health.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                            height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Risks box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 16, color: Colors.amber.shade900),
                          const SizedBox(width: 6),
                          Text(
                            'Important Risk',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• If your biometric sensor cracks, your finger is bandaged, or biometrics are removed in phone settings, the app will not accept your phone unlock pattern.\n'
                        '• Tip: You can set a Master Password / PIN in Backup Encryption as a reliable in-app fallback secret.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                            height: 1.3),
                      ),
                    ],
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
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Enable Strict Biometrics'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          final authenticated = await _auth.authenticate(
            localizedReason:
                'Verify fingerprint or Face ID to enable Strict Biometrics',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: true,
            ),
          );

          if (authenticated) {
            await ref
                .read(secureStorageProvider)
                .setStrictBiometricsOnly(true);
            if (mounted) {
              setState(() => _isStrictBiometrics = true);
              _showSnackbar(
                  'Strict biometrics enabled: Screen pattern fallback disabled.');
            }
          }
        } on PlatformException catch (e) {
          debugPrint('Strict biometrics test failed: $e');
          _showSecurityAlert(
            title: 'Biometric Check Failed',
            message:
                'Could not verify your fingerprint or Face ID. Please ensure biometrics are registered in device settings.',
          );
        }
      }
    } else {
      await ref
          .read(secureStorageProvider)
          .setStrictBiometricsOnly(false);
      if (mounted) {
        setState(() => _isStrictBiometrics = false);
        _showSnackbar('Screen pattern/PIN fallback re-enabled.');
      }
    }
  }

  Future<void> _toggleBannerDismissed(bool value) async {
    await ref.read(appDatabaseProvider).setSecurityBannerDismissed(value);
    setState(() {
      _isBannerDismissed = value;
    });
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSecurityAlert({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSetUpSettingsDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Set Up Secure Lock',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'Secure App Lock requires a passcode, PIN, pattern, or biometrics configured on your device.\n\nWould you like to open your device security settings to configure it now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                if (Platform.isAndroid) {
                  const intent = AndroidIntent(
                    action: 'android.settings.SECURITY_SETTINGS',
                  );
                  await intent.launch();
                } else {
                  _showSecurityAlert(
                    title: 'System Settings',
                    message: 'Please open your device\'s system Settings -> Face ID & Passcode to configure security.',
                  );
                }
              } catch (e) {
                _showSecurityAlert(
                  title: 'Error',
                  message: 'Could not open device settings automatically. Please open your device Settings manually.',
                );
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // End-to-End Encryption Handlers
  // ---------------------------------------------------------------------------

  void _showE2eBackupDialog() {
    if (_isE2eEnabled) {
      _showManageE2eDialog();
    } else {
      _showEnableE2eDialog();
    }
  }

  void _showEnableE2eDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final recoveryKey = BackupEncryptionService.generateRecoveryKey();
    bool obscurePassword = true;
    bool hasAcceptedRisk = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => PopScope(
        canPop: true,
        child: StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.enhanced_encryption,
                                color: Colors.green.shade700, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End-to-End Encrypted Backup',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Zero-Knowledge Medical Data Shield',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
                      const Divider(height: 24),

                      // Benefits Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.shield_outlined,
                                    size: 18, color: Colors.blue.shade800),
                                const SizedBox(width: 6),
                                Text(
                                  'Benefits',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• Your medical logs, prescriptions, and attachments are encrypted locally before upload.\n'
                              '• Neither Google, the developers, nor third parties can read your health records.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.blue.shade900),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Risks Warning Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    size: 18, color: Colors.amber.shade900),
                                const SizedBox(width: 6),
                                Text(
                                  'Important Risk',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• There is NO password reset mechanism. If you lose your phone and forget both your password and recovery key, your backup CANNOT be recovered.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.amber.shade900),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Step 1: Create Password or PIN
                      const Text(
                        '1. Create Master Password or PIN',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password or PIN (min 4 chars/digits)',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setModalState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: confirmController,
                        obscureText: obscurePassword,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password or PIN',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Step 2: 64-Digit Recovery Key
                      const Text(
                        '2. Emergency 64-Digit Recovery Key',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Save this recovery key in a safe place. You can use it to restore your medical data if you ever forget your password.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                recoveryKey,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              tooltip: 'Copy Recovery Key',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: recoveryKey));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Recovery key copied to clipboard!'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Checkbox acknowledging risk
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: hasAcceptedRisk,
                        title: const Text(
                          'I understand that if I lose my password and recovery key, my medical backup cannot be restored.',
                          style: TextStyle(fontSize: 12),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (val) {
                          setModalState(() {
                            hasAcceptedRisk = val ?? false;
                          });
                        },
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.lock_outline),
                              label: const Text('Turn On E2E'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: !hasAcceptedRisk
                                  ? null
                                  : () async {
                                      final pass = passwordController.text;
                                      final confirm = confirmController.text;

                                      if (pass.length < 4) {
                                        setModalState(() {
                                          errorMessage =
                                              'Password or PIN must be at least 4 characters/digits long.';
                                        });
                                        return;
                                      }

                                      if (pass != confirm) {
                                        setModalState(() {
                                          errorMessage = 'Passwords do not match.';
                                        });
                                        return;
                                      }

                                      final secureStorage =
                                          ref.read(secureStorageProvider);
                                      final salt =
                                          BackupEncryptionService.generateSalt();
                                      final saltHex = salt
                                          .map((b) => b.toRadixString(16).padLeft(2, '0'))
                                          .join();
                                      final hash = BackupEncryptionService.hashPassword(
                                          pass, salt);

                                      await secureStorage.setE2eBackupEnabled(true);
                                      await secureStorage.setE2eSalt(saltHex);
                                      await secureStorage.setE2ePasswordHash(hash);
                                      await secureStorage
                                          .setE2eRecoveryKey(recoveryKey);
                                      await secureStorage.setE2eCachedPassword(pass);

                                      if (mounted && ctx.mounted) {
                                        setState(() => _isE2eEnabled = true);
                                        Navigator.of(ctx).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'End-to-End Encrypted Backup is now ON 🔒'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );

                                        // Auto trigger an encrypted backup if user is connected
                                        try {
                                          ref.read(backupServiceProvider).backupToGoogleDrive();
                                        } catch (e) {
                                          debugPrint('Auto backup triggered error: $e');
                                        }
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showManageE2eDialog() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => PopScope(
        canPop: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified_user,
                        color: Colors.green.shade700, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End-to-End Encryption Active',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Protected with password & 64-digit key',
                          style: TextStyle(fontSize: 12, color: Colors.green),
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
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.key_outlined, color: Colors.blue),
                title: const Text('View 64-Digit Recovery Key'),
                subtitle: const Text('Copy or backup your emergency hex key'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  _showRecoveryKeyViewDialog();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_reset, color: Colors.indigo),
                title: const Text('Change Backup Password'),
                subtitle: const Text('Update your encryption password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showChangePasswordDialog();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_open, color: Colors.red),
                title: const Text(
                  'Switch Back to Standard Backup',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text('Disable E2E password encryption'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showDisableE2eDialog();
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecoveryKeyViewDialog() async {
    final key = await ref.read(secureStorageProvider).getE2eRecoveryKey() ??
        'No recovery key found.';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '64-Digit Recovery Key',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This emergency recovery key can restore your encrypted medical backup if you ever forget your password:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                key,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Key'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: key));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recovery key copied to clipboard!'),
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Backup Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPassController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password (min 6 chars)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 10),
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
            FilledButton(
              onPressed: () async {
                final current = currentPassController.text;
                final next = newPassController.text;
                final confirm = confirmPassController.text;

                final secureStorage = ref.read(secureStorageProvider);
                final storedHash =
                    await secureStorage.getE2ePasswordHash();
                final storedSaltHex = await secureStorage.getE2eSalt();

                if (storedHash != null && storedSaltHex != null) {
                  final saltBytes = Uint8List.fromList(
                    List<int>.generate(
                      storedSaltHex.length ~/ 2,
                      (i) => int.parse(
                          storedSaltHex.substring(i * 2, i * 2 + 2),
                          radix: 16),
                    ),
                  );

                  if (!BackupEncryptionService.verifyPassword(
                      current, storedHash, saltBytes)) {
                    setDialogState(() {
                      errorMessage = 'Incorrect current password.';
                    });
                    return;
                  }
                }

                if (next.length < 6) {
                  setDialogState(() {
                    errorMessage =
                        'New password must be at least 6 characters.';
                  });
                  return;
                }

                if (next != confirm) {
                  setDialogState(() {
                    errorMessage = 'New passwords do not match.';
                  });
                  return;
                }

                final newSalt = BackupEncryptionService.generateSalt();
                final newSaltHex = newSalt
                    .map((b) => b.toRadixString(16).padLeft(2, '0'))
                    .join();
                final newHash =
                    BackupEncryptionService.hashPassword(next, newSalt);

                await secureStorage.setE2eSalt(newSaltHex);
                await secureStorage.setE2ePasswordHash(newHash);
                await secureStorage.setE2eCachedPassword(next);

                if (mounted && ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup password updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDisableE2eDialog() {
    final passwordController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Switch Back to Standard Backup',
                  overflow: TextOverflow.ellipsis,
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
                  'Switching back removes client-side password protection from your cloud backups.\n\n'
                  'Your future backups will use standard Google Drive App Data protection, and anyone signed into your Google Account will be able to restore your medical data without a secondary password.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Enter Current Password or Recovery Key',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
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
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final input = passwordController.text;
                final secureStorage = ref.read(secureStorageProvider);
                final storedHash =
                    await secureStorage.getE2ePasswordHash();
                final storedSaltHex = await secureStorage.getE2eSalt();
                final storedRecoveryKey =
                    await secureStorage.getE2eRecoveryKey();

                bool isMatch = false;

                // Check against password hash
                if (storedHash != null && storedSaltHex != null) {
                  final saltBytes = Uint8List.fromList(
                    List<int>.generate(
                      storedSaltHex.length ~/ 2,
                      (i) => int.parse(
                          storedSaltHex.substring(i * 2, i * 2 + 2),
                          radix: 16),
                    ),
                  );

                  if (BackupEncryptionService.verifyPassword(
                      input, storedHash, saltBytes)) {
                    isMatch = true;
                  }
                }

                // Check against recovery key
                if (!isMatch && storedRecoveryKey != null) {
                  final cleanInput = input.replaceAll('-', '').trim();
                  final cleanKey =
                      storedRecoveryKey.replaceAll('-', '').trim();
                  if (cleanInput.toLowerCase() == cleanKey.toLowerCase()) {
                    isMatch = true;
                  }
                }

                if (!isMatch) {
                  setDialogState(() {
                    errorMessage =
                        'Incorrect password or recovery key. Please try again.';
                  });
                  return;
                }

                // Clear E2E settings
                await secureStorage.clearE2eSettings();

                if (mounted && ctx.mounted) {
                  setState(() => _isE2eEnabled = false);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Switched back to standard Google Drive backup.'),
                    ),
                  );
                }
              },
              child: const Text('Turn Off E2E'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDeviceSecure = _isDeviceSecure;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Lock & Security'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Protective Icon/Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDeviceSecure ? Icons.lock_outline : Icons.gpp_maybe_outlined,
                        size: 48,
                        color: isDeviceSecure ? theme.colorScheme.primary : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Secure App Lock',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Require authentication to open Open Cloud Health.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Educational context box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDeviceSecure 
                      ? theme.colorScheme.primary.withOpacity(0.05) 
                      : Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDeviceSecure 
                        ? theme.colorScheme.primary.withOpacity(0.1) 
                        : Colors.orange.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDeviceSecure ? Icons.info_outline : Icons.warning_amber_outlined,
                          color: isDeviceSecure ? theme.colorScheme.primary : Colors.orange.shade800,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDeviceSecure ? 'Secure Device Settings Detected' : 'Unsecured Device Warning',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDeviceSecure ? theme.colorScheme.primary : Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isDeviceSecure
                          ? 'Enable App Lock to require Face ID, Touch ID, or a device PIN specifically for this app. This ensures your medical timeline, cycle logs, and prescriptions remain strictly confidential, even if you hand your unlocked device to a friend or family member.'
                          : 'We highly recommend setting up a screen lock (passcode, password, or biometrics) in your device\'s system settings. Without device-level security, your private health record is vulnerable to physical theft or unauthorized physical access.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDeviceSecure ? theme.colorScheme.onBackground.withOpacity(0.8) : Colors.orange.shade900.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Security Toggles Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable App Lock'),
                      subtitle: Text(
                        _isLocalAuthEnabled 
                            ? 'Requires authentication on launch' 
                            : 'App is currently unprotected',
                      ),
                      secondary: Icon(
                        _isLocalAuthEnabled ? Icons.security : Icons.security_outlined,
                        color: _isLocalAuthEnabled ? Colors.green : Colors.grey,
                      ),
                      value: _isLocalAuthEnabled,
                      onChanged: _toggleLocalAuth,
                    ),
                    if (_isLocalAuthEnabled) ...[
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Strict Biometrics Only'),
                        subtitle: Text(
                          _isStrictBiometrics
                              ? 'Hides screen pattern/PIN (Fingerprint/Face ID required)'
                              : 'Allows phone lock screen pattern/PIN fallback',
                        ),
                        secondary: Icon(
                          _isStrictBiometrics ? Icons.fingerprint : Icons.pattern,
                          color: _isStrictBiometrics ? Colors.blue : Colors.grey,
                        ),
                        value: _isStrictBiometrics,
                        onChanged: _toggleStrictBiometrics,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.timer_outlined, color: Colors.blue),
                        title: const Text('Auto-Lock Timeout'),
                        subtitle: Text(
                          _autoLockGraceSeconds == 0
                              ? 'Immediately when leaving app'
                              : _autoLockGraceSeconds < 60
                                  ? '$_autoLockGraceSeconds seconds of background inactivity'
                                  : '${_autoLockGraceSeconds ~/ 60} minute(s) of background inactivity',
                        ),
                        trailing: DropdownButton<int>(
                          value: _autoLockGraceSeconds,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Immediately')),
                            DropdownMenuItem(value: 30, child: Text('30s')),
                            DropdownMenuItem(value: 60, child: Text('1m')),
                            DropdownMenuItem(value: 300, child: Text('5m')),
                          ],
                          onChanged: (val) async {
                            if (val != null) {
                              await ref.read(secureStorageProvider).setAutoLockGraceSeconds(val);
                              setState(() => _autoLockGraceSeconds = val);
                            }
                          },
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Show Warning on Home Screen'),
                      subtitle: const Text('Reminds you if App Lock is off'),
                      secondary: const Icon(Icons.notification_important_outlined),
                      value: !_isBannerDismissed,
                      onChanged: (val) => _toggleBannerDismissed(!val),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.enhanced_encryption_outlined,
                        color: Colors.green.shade700,
                      ),
                      title: const Text('Backup Encryption at Rest'),
                      subtitle: Text(
                        _isE2eEnabled
                            ? 'Custom Password • Zero-knowledge protection'
                            : 'Active • Hardware & Account-bound AES-256',
                        style: TextStyle(
                          color: _isE2eEnabled
                              ? Colors.purple.shade800
                              : Colors.green.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _isE2eEnabled
                                  ? Colors.purple.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isE2eEnabled
                                    ? Colors.purple.shade300
                                    : Colors.green.shade300,
                              ),
                            ),
                            child: Text(
                              _isE2eEnabled ? 'CUSTOM KEY' : 'ENCRYPTED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _isE2eEnabled
                                    ? Colors.purple.shade800
                                    : Colors.green.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: _showE2eBackupDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
