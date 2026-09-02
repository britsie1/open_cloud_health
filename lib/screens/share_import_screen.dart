import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/profile_share_models.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/utils/constants.dart';

class ShareImportScreen extends ConsumerStatefulWidget {
  final ShareLinkPayload? payload;

  const ShareImportScreen({super.key, this.payload});

  @override
  ConsumerState<ShareImportScreen> createState() => _ShareImportScreenState();
}

class _ShareImportScreenState extends ConsumerState<ShareImportScreen> {
  bool _isImporting = false;
  String? _errorMessage;

  Future<void> _importProfile() async {
    if (widget.payload == null || _isImporting) return;

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      final profile = await ref.read(profilesProvider.notifier).importSharedProfile(widget.payload!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported "${profile.name} ${profile.surname}"!'),
            backgroundColor: Colors.teal,
          ),
        );
        context.go('${AppRoutes.home}/${profile.id}', extra: profile);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _errorMessage = e.toString().replaceAll('FormatException: ', '').replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payload = widget.payload;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Health Profile'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: payload == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_off, size: 72, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Invalid Share Link',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This link appears to be incomplete or missing security keys.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go(AppRoutes.auth),
                        child: const Text('Go to Home'),
                      ),
                    ],
                  )
                : Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.share_outlined, size: 48, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Shared Profile Invitation',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            payload.profileName ?? 'Medical Profile',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (payload.sharedBy != null && payload.sharedBy!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Shared by ${payload.sharedBy}',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 20, color: Colors.green.shade700),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'End-to-End Encrypted: Decrypted on device with owner\'s key.',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.sync, size: 20, color: Colors.blue.shade700),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Read-only access: Synchronizes securely with owner\'s cloud updates.',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          if (_isImporting)
                            const Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('Downloading and decrypting profile records...'),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => context.go(AppRoutes.auth),
                                    child: const Text('Decline'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _importProfile,
                                    child: const Text('Import Profile'),
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
    );
  }
}
