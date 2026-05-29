import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/utils/security_utils.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Initialize Notifications in background
    await NotificationService().init();

    // 2. Check if local auth is enabled in settings
    final isAuthEnabled = await ref.read(databaseHelperProvider).isLocalAuthEnabled();
    final isDeviceSecure = await SecurityUtils.isDeviceSecure();

    if (isAuthEnabled && !isDeviceSecure) {
      // Auto-disable in database since the device lock was removed
      await ref.read(databaseHelperProvider).setLocalAuthEnabled(false);
    }

    if (!isAuthEnabled || !isDeviceSecure) {
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

      final lastProfileId = await ref.read(secureStorageProvider).getLastProfileId();
      if (!mounted) return;
      if (lastProfileId != null) {
        final lastProfile = profiles.where((p) => p.id == lastProfileId).firstOrNull;
        if (lastProfile != null) {
          context.go('${AppRoutes.home}/${lastProfile.id}', extra: lastProfile);
          return;
        }
      }

      if (profiles.length == 1) {
        await ref.read(secureStorageProvider).saveLastProfileId(profiles[0].id);
        if (!mounted) return;
        context.go('${AppRoutes.home}/${profiles[0].id}', extra: profiles[0]);
        return;
      }

      if (!mounted) return;
      context.go(AppRoutes.profiles);
      return;
    }

    // 3. Check Biometric Support (if enabled in DB)
    final isSupported = await auth.isDeviceSupported();
    if (!mounted) return;

    setState(() {
      _supportState =
          isSupported ? _SupportState.supported : _SupportState.unsupported;
    });

    await _checkBiometrics();

    if (!mounted) return;

    setState(() {
      _isInitializing = false;
    });

    // 4. Auto-authenticate if supported
    if (_supportState == _SupportState.supported && (_canCheckBiometrics ?? false)) {
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
    try {
      if (_supportState == _SupportState.supported && (_canCheckBiometrics ?? false)) {
        isAuthenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to access your health data',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Authentication failed.'),
          ),
        );
      }
    }

    if (isAuthenticated || _supportState == _SupportState.unsupported) {
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

      final lastProfileId = await ref.read(secureStorageProvider).getLastProfileId();
      if (lastProfileId != null) {
        final lastProfile = profiles.where((p) => p.id == lastProfileId).firstOrNull;
        if (lastProfile != null) {
          if (!mounted) return;
          context.go('${AppRoutes.home}/${lastProfile.id}', extra: lastProfile);
          return;
        }
      }

      if (profiles.length == 1) {
        await ref.read(secureStorageProvider).saveLastProfileId(profiles[0].id);
        if (!mounted) return;
        context.go('${AppRoutes.home}/${profiles[0].id}', extra: profiles[0]);
        return;
      }

      if (!mounted) return;
      context.go(AppRoutes.profiles);
    }
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
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.lock_open),
              label: Text(_supportState == _SupportState.unsupported ||
                      (_canCheckBiometrics == false)
                  ? 'Open anyway'
                  : 'Login'),
            ),
          ]),
        ),
      ),
    );
  }
}
