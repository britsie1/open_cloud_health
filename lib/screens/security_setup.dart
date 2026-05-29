import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:open_cloud_health/database/database_helper.dart';
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
      var isEnabled = await ref.read(databaseHelperProvider).isLocalAuthEnabled();
      final isDismissed = await ref.read(databaseHelperProvider).isSecurityBannerDismissed();

      if (isEnabled && !isDeviceSecure) {
        // Auto-disable in database since the device lock was removed
        await ref.read(databaseHelperProvider).setLocalAuthEnabled(false);
        isEnabled = false;
      }

      if (mounted) {
        setState(() {
          _isDeviceSecure = isDeviceSecure;
          _isLocalAuthEnabled = isEnabled;
          _isBannerDismissed = isDismissed;
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
        final authenticated = await _auth.authenticate(
          localizedReason: 'Authenticate to enable App Lock protection',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        if (authenticated) {
          await ref.read(databaseHelperProvider).setLocalAuthEnabled(true);
          setState(() {
            _isLocalAuthEnabled = true;
          });
          _showSnackbar('App Lock enabled successfully!');
        }
      } on PlatformException catch (e) {
        debugPrint(e.toString());
        _showSecurityAlert(
          title: 'Authentication Error',
          message: e.message ?? 'Failed to authenticate.',
        );
      }
    } else {
      // Disabling App Lock: simply update
      await ref.read(databaseHelperProvider).setLocalAuthEnabled(false);
      setState(() {
        _isLocalAuthEnabled = false;
      });
      _showSnackbar('App Lock disabled.');
    }
  }

  Future<void> _toggleBannerDismissed(bool value) async {
    await ref.read(databaseHelperProvider).setSecurityBannerDismissed(value);
    setState(() {
      _isBannerDismissed = value;
    });
    _showSnackbar(value ? 'Warning banner hidden from Home.' : 'Warning banner will show on Home.');
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _showSecurityAlert({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
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
            Text('Set Up Secure Lock'),
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

              // Educational context box (Rich dynamic warning)
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
                      enabled: false,
                      title: const Text('App Password Lock (Coming Soon)'),
                      subtitle: const Text('Configure a unique app-specific password'),
                      leading: const Icon(Icons.password_outlined),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PLACEHOLDER',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ),
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
