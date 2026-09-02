import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/services/backup_encryption_service.dart';
import 'package:open_cloud_health/services/backup_scheduler_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/utils/security_utils.dart';
import 'package:open_cloud_health/widgets/emergency_card_view.dart';

final isAppLockedProvider = StateProvider<bool>((ref) => false);

class AppLifecycleLockManager with WidgetsBindingObserver {
  final Ref _ref;
  DateTime? _pausedAt;

  AppLifecycleLockManager(this._ref);

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    _applyInitialSecurity();
  }

  Future<void> _applyInitialSecurity() async {
    try {
      final isAuthEnabled = await _ref.read(appDatabaseProvider).isLocalAuthEnabled();
      final isDeviceSecure = await SecurityUtils.isDeviceSecure();
      if (isAuthEnabled && isDeviceSecure) {
        await SecurityUtils.setSecureScreen(true);
      }
    } catch (_) {}
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }

  Future<void> _handleAppResume() async {
    // 1. Opportunistically execute scheduled backups and share syncs if overdue
    try {
      _ref.read(backupSchedulerServiceProvider).onAppResume();
    } catch (_) {}

    final pausedTime = _pausedAt;
    _pausedAt = null;

    if (pausedTime == null) return;

    final isAuthEnabled = await _ref.read(appDatabaseProvider).isLocalAuthEnabled();
    final isDeviceSecure = await SecurityUtils.isDeviceSecure();

    // Sync FLAG_SECURE / screen privacy
    await SecurityUtils.setSecureScreen(isAuthEnabled && isDeviceSecure);

    if (!isAuthEnabled || !isDeviceSecure) {
      return;
    }

    final graceSeconds = await _ref.read(secureStorageProvider).getAutoLockGraceSeconds();
    final elapsedSeconds = DateTime.now().difference(pausedTime).inSeconds;

    if (elapsedSeconds >= graceSeconds) {
      _ref.read(isAppLockedProvider.notifier).state = true;
    }
  }

  void unlock() {
    _ref.read(isAppLockedProvider.notifier).state = false;
  }
}

final appLifecycleLockManagerProvider = Provider<AppLifecycleLockManager>((ref) {
  final manager = AppLifecycleLockManager(ref);
  manager.initialize();
  ref.onDispose(() => manager.dispose());
  return manager;
});

class AppLockOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockOverlay({super.key, required this.child});

  @override
  ConsumerState<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends ConsumerState<AppLockOverlay> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(isAppLockedProvider);

    return Stack(
      children: [
        widget.child,
        if (isLocked)
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 140,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Image.asset(
                          AppAssets.logo,
                          semanticLabel: 'Open Cloud Health Logo',
                        ),
                      ),
                      Text(
                        'Open Cloud Health',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'App locked for your privacy',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isAuthenticating ? null : _authenticateWithBiometrics,
                        icon: const Icon(Icons.fingerprint, size: 24),
                        label: const Text(
                          'Unlock App',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _promptMasterPasswordModal,
                        icon: const Icon(Icons.pin_outlined, size: 20),
                        label: const Text('Enter PIN / Password'),
                      ),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showEmergencyCard() async {
    final db = ref.read(appDatabaseProvider);
    final settingsData = await (db.select(db.lockScreenSettings)..where((tbl) => tbl.isEnabled.equals(true))).get();

    if (settingsData.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No emergency profiles enabled in settings.')),
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

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      final isStrict = await ref.read(secureStorageProvider).isStrictBiometricsOnly();
      final hasCustomPassword = await ref.read(secureStorageProvider).isE2eBackupEnabled();
      final enforceBiometricOnly = hasCustomPassword || isStrict;

      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;

      if (isSupported && canCheck) {
        final authenticated = await _auth.authenticate(
          localizedReason: 'Scan fingerprint or Face ID to unlock Open Cloud Health',
          options: AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: enforceBiometricOnly,
          ),
        );

        if (authenticated && mounted) {
          ref.read(isAppLockedProvider.notifier).state = false;
        } else if (hasCustomPassword && mounted) {
          _promptMasterPasswordModal();
        }
      } else if (hasCustomPassword && mounted) {
        _promptMasterPasswordModal();
      }
    } catch (e) {
      debugPrint('Biometric unlock error: $e');
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isRecoveryKeyMode ? Icons.key : Icons.lock_outline,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRecoveryKeyMode ? 'Enter Recovery Key' : 'Master Password / PIN',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    labelText: isRecoveryKeyMode ? '64-character Recovery Key' : 'Password or PIN',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: isRecoveryKeyMode
                        ? null
                        : IconButton(
                            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
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
                      isRecoveryKeyMode ? 'Use Password / PIN instead' : 'Use Recovery Key instead',
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
                  setModalState(() => errorMessage = 'Please enter your password or key.');
                  return;
                }

                final secureStorage = ref.read(secureStorageProvider);
                final storedHash = await secureStorage.getE2ePasswordHash();
                final storedSaltStr = await secureStorage.getE2eSalt();
                final storedRecoveryKey = await secureStorage.getE2eRecoveryKey();

                bool isCorrect = false;

                if (!isRecoveryKeyMode && storedHash != null && storedSaltStr != null) {
                  final salt = base64Decode(storedSaltStr);
                  isCorrect = BackupEncryptionService.verifyPassword(input, storedHash, salt);
                } else if (storedRecoveryKey != null) {
                  isCorrect = BackupEncryptionService.normalizeKey(input) ==
                      BackupEncryptionService.normalizeKey(storedRecoveryKey);
                }

                if (isCorrect) {
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                  ref.read(isAppLockedProvider.notifier).state = false;
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
}
