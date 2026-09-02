import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/utils/constants.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
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
              child: const Text('Decrypt & Restore'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleDriveRestore() async {
    _showLoading('Connecting to Google Drive...');
    try {
      final backupService = ref.read(backupServiceProvider);
      try {
        await backupService.restoreFromBackup();
      } on FormatException {
        _hideLoading();
        if (!mounted) return;

        final password = await _promptPasswordDialog(
          title: 'Encrypted Cloud Backup',
          subtitle:
              'This cloud backup is protected with an end-to-end encryption password or recovery key. Please enter it to decrypt and restore.',
          isRequired: true,
        );

        if (password == null || password.isEmpty) return;

        _showLoading('Decrypting cloud backup...');
        await backupService.restoreFromBackup(password: password);
      }

      await ref.read(profilesProvider.notifier).loadProfiles();
      _hideLoading();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Cloud backup restored successfully!'),
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
            content: Text('Restore error: $e'),
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.05),
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 48.0),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const Spacer(),
                            
                            // Beautiful Premium Logo/Icon Container
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                AppAssets.logo,
                                semanticLabel: 'Open Cloud Health Logo',
                                height: 80,
                                width: 80,
                              ),
                            ),
                            const SizedBox(height: 36),
                            
                            // Welcome Text
                            Text(
                              'Open Cloud Health',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onBackground,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Description Text
                            Text(
                              'A highly secure medical tracking companion. Your health timeline, prescriptions, cycle history, and vitals are stored on this device—completely under your control.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onBackground.withOpacity(0.6),
                                height: 1.5,
                              ),
                            ),
                            
                            const Spacer(),
                            const SizedBox(height: 24),
                            
                            // Primary action: Create New Profile
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        context.push(AppRoutes.profileDetail);
                                      },
                                icon: const Icon(Icons.person_add_outlined, size: 20),
                                label: const Text(
                                  'Create New Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            
                            // Secondary action: Import From File
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        context.push(AppRoutes.importProfile);
                                      },
                                icon: const Icon(Icons.folder_shared_outlined, size: 20),
                                label: const Text(
                                  'Import From File',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.4), width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Tertiary action: Scan QR Code Profile
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        context.push(AppRoutes.qrScanner);
                                      },
                                icon: const Icon(Icons.qr_code_scanner, size: 20),
                                label: const Text(
                                  'Scan Share QR Code',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.4), width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Restore / Migration action: Restore From Cloud Backup
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: TextButton.icon(
                                onPressed: _isLoading ? null : _handleGoogleDriveRestore,
                                icon: const Icon(Icons.cloud_download_outlined, size: 20),
                                label: const Text(
                                  'Restore From Cloud Backup',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
