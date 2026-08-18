import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/services/backup_encryption_service.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/utils/security_utils.dart';
import 'package:open_cloud_health/widgets/emergency_card_view.dart';

enum _SupportState {
  unknown,
  supported,
  unsupported,
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;
  bool? _canCheckBiometrics;
  bool _isInitializing = true;
  bool _hasCustomPassword = false;
  bool _isStrictBiometrics = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Initialize Notifications in background
    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint('Notification initialization: $e');
    }

    // 2. Check if local auth is enabled in settings
    final isAuthEnabled =
        await ref.read(appDatabaseProvider).isLocalAuthEnabled();
    final isDeviceSecure = await SecurityUtils.isDeviceSecure();

    if (isAuthEnabled && !isDeviceSecure) {
      // Auto-disable in database since the device lock was removed
      await ref.read(appDatabaseProvider).setLocalAuthEnabled(false);
    }

    if (!isAuthEnabled || !isDeviceSecure) {
      await _onAuthenticatedSuccessfully();
      return;
    }

    // 3. Check custom password and strict biometric settings
    final hasPass =
        await ref.read(secureStorageProvider).isE2eBackupEnabled();
    final isStrict =
        await ref.read(secureStorageProvider).isStrictBiometricsOnly();

    // 4. Check device biometric capabilities
    final isSupported = await auth.isDeviceSupported();
    if (!mounted) return;

    setState(() {
      _hasCustomPassword = hasPass;
      _isStrictBiometrics = isStrict;
      _supportState =
          isSupported ? _SupportState.supported : _SupportState.unsupported;
    });

    await _checkBiometrics();

    if (!mounted) return;

    setState(() {
      _isInitializing = false;
    });

    // 5. Auto-authenticate if supported
    if (_supportState == _SupportState.supported &&
        (_canCheckBiometrics ?? false)) {
      _authenticate();
    }
  }

  Future<void> _checkBiometrics() async {
    late bool canCheckBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      canCheckBiometrics = false;
      debugPrint(e.toString());
    }
    if (!mounted) {
      return;
    }
    _canCheckBiometrics = canCheckBiometrics;
  }

  void _authenticate() async {
    bool isAuthenticated = false;
    final hasCustomPassword =
        await ref.read(secureStorageProvider).isE2eBackupEnabled();
    final isStrict =
        await ref.read(secureStorageProvider).isStrictBiometricsOnly();
    final enforceBiometricOnly = hasCustomPassword || isStrict;

    try {
      if (_supportState == _SupportState.supported &&
          (_canCheckBiometrics ?? false)) {
        // Enforce strict biometrics to block OS lock screen pattern when enabled or custom password active
        isAuthenticated = await auth.authenticate(
          localizedReason:
              'Scan fingerprint or Face ID to open Open Cloud Health',
          options: AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: enforceBiometricOnly,
          ),
        );
      }
    } on PlatformException catch (error) {
      debugPrint('Biometric authentication error: $error');
    }

    if (isAuthenticated || _supportState == _SupportState.unsupported) {
      await _onAuthenticatedSuccessfully();
    } else if (hasCustomPassword && mounted) {
      // Biometric scan was canceled, failed, or sensor is broken: fallback to in-app Password/PIN
      _promptMasterPasswordModal();
    } else if (isStrict && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Strict Biometrics: Fingerprint or Face ID required.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _promptMasterPasswordModal() async {
    final passwordController = TextEditingController();
    bool isRecoveryKeyMode = false;
    bool obscureText = true;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isRecoveryKeyMode ? Icons.key : Icons.lock_outline,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRecoveryKeyMode
                      ? 'Enter Recovery Key'
                      : 'Master Password / PIN',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
                  isRecoveryKeyMode
                      ? 'Enter your 64-character emergency recovery key to unlock the app:'
                      : 'Enter your Master Password or PIN to unlock your medical records:',
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: isRecoveryKeyMode ? false : obscureText,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: isRecoveryKeyMode
                        ? '64-character Recovery Key'
                        : 'Password or PIN',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: isRecoveryKeyMode
                        ? null
                        : IconButton(
                            icon: Icon(obscureText
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setModalState(() {
                                obscureText = !obscureText;
                              });
                            },
                          ),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setModalState(() {
                        isRecoveryKeyMode = !isRecoveryKeyMode;
                        passwordController.clear();
                        errorMessage = null;
                      });
                    },
                    child: Text(
                      isRecoveryKeyMode
                          ? 'Use Password / PIN instead'
                          : 'Use Recovery Key instead',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final input = passwordController.text.trim();
                if (input.isEmpty) {
                  setModalState(
                      () => errorMessage = 'Please enter your password or key.');
                  return;
                }

                final secureStorage = ref.read(secureStorageProvider);
                final storedHash =
                    await secureStorage.getE2ePasswordHash();
                final storedSaltStr = await secureStorage.getE2eSalt();
                final storedRecoveryKey =
                    await secureStorage.getE2eRecoveryKey();

                bool isCorrect = false;

                if (!isRecoveryKeyMode &&
                    storedHash != null &&
                    storedSaltStr != null) {
                  final salt = base64Decode(storedSaltStr);
                  isCorrect = BackupEncryptionService.verifyPassword(
                      input, storedHash, salt);
                } else if (storedRecoveryKey != null) {
                  isCorrect = BackupEncryptionService.normalizeKey(input) ==
                      BackupEncryptionService.normalizeKey(storedRecoveryKey);
                }

                if (isCorrect) {
                  Navigator.of(ctx).pop();
                  await _onAuthenticatedSuccessfully();
                } else {
                  setModalState(() {
                    errorMessage = isRecoveryKeyMode
                        ? 'Invalid recovery key. Please check and try again.'
                        : 'Incorrect password or PIN. Please try again.';
                  });
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAuthenticatedSuccessfully() async {
    await ref.read(profilesProvider.notifier).checkAndDeleteExpiredProfiles();
    await ref.read(profilesProvider.notifier).loadProfiles();

    if (!mounted) {
      return;
    }

    final profiles = ref.read(profilesProvider).value ?? [];

    if (profiles.isEmpty) {
      context.go(AppRoutes.welcome);
      return;
    }

    final lastProfileId =
        await ref.read(secureStorageProvider).getLastProfileId();
    if (lastProfileId != null) {
      final lastProfile =
          profiles.where((p) => p.id == lastProfileId).firstOrNull;
      if (lastProfile != null) {
        if (!mounted) return;
        context.go('${AppRoutes.home}/${lastProfile.id}', extra: lastProfile);
        return;
      }
    }

    if (profiles.length == 1) {
      await ref
          .read(secureStorageProvider)
          .saveLastProfileId(profiles[0].id);
      if (!mounted) return;
      context.go('${AppRoutes.home}/${profiles[0].id}', extra: profiles[0]);
      return;
    }

    if (!mounted) return;
    context.go(AppRoutes.profiles);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AppAssets.logo, width: 200),
              const SizedBox(height: 40),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              margin: const EdgeInsets.only(
                top: 30,
                bottom: 40,
                left: 20,
                right: 20,
              ),
              width: 230,
              child: Image.asset(AppAssets.logo),
            ),
            Text(
              'OpenCloudHealth',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 20,
            ),
            if (_supportState == _SupportState.unsupported ||
                (_canCheckBiometrics == false))
              Container(
                margin: const EdgeInsets.all(20),
                child: Card(
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(
                            width: 20,
                          ),
                          Flexible(
                            child: Text(
                              'Biometric authentication is not available or not set up on this device.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Builder(builder: (context) {
              final isBiometricMode = _hasCustomPassword || _isStrictBiometrics;
              return ElevatedButton.icon(
                onPressed: _authenticate,
                icon: Icon(isBiometricMode
                    ? Icons.fingerprint
                    : Icons.lock_open),
                label: Text(isBiometricMode
                    ? 'Unlock with Biometrics'
                    : (_supportState == _SupportState.unsupported ||
                            (_canCheckBiometrics == false)
                        ? 'Open anyway'
                        : 'Login')),
              );
            }),
            if (_hasCustomPassword) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _promptMasterPasswordModal,
                icon: const Icon(Icons.pin_outlined),
                label: const Text('Enter Master Password / PIN'),
              ),
            ],
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _showEmergencyCard,
              icon: const Icon(Icons.emergency, color: Colors.red),
              label: const Text(
                'Emergency Medical ID',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _showEmergencyCard() async {
    final db = ref.read(appDatabaseProvider);

    // Check if there are any active settings enabled
    final settingsData = await (db.select(db.lockScreenSettings)..where((tbl) => tbl.isEnabled.equals('true'))).get();

    if (settingsData.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No emergency profiles enabled in settings.')),
        );
      }
      return;
    }

    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Emergency Card',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const EmergencyCardView();
      },
    );
  }
}
