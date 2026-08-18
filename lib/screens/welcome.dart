import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/utils/constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
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
                            height: 80,
                            width: 80,
                          ),
                        ),
                        const SizedBox(height: 36),
                        
                        // Welcome Text
                        Text(
                          'Your Health,\nPrivately Owned',
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
                          'A local-first, highly secure medical tracking companion. Your health timeline, prescriptions, cycle history, and vitals are stored on this device—completely under your control.',
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
                            onPressed: () {
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
                        
                        // Secondary action: Access Existing Profile
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.push(AppRoutes.profiles);
                            },
                            icon: const Icon(Icons.folder_shared_outlined, size: 20),
                            label: const Text(
                              'Access Existing Profile',
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
                        const SizedBox(height: 16),
                        
                        // Small security disclaimer at bottom
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Zero-knowledge architecture. No cloud login required.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onBackground.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
