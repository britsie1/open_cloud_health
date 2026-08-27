import 'dart:ffi';
import 'dart:io';

import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/providers/theme_provider.dart';
import 'package:open_cloud_health/routing/app_router.dart';
import 'package:open_cloud_health/services/app_lifecycle_lock_manager.dart';
import 'package:open_cloud_health/services/backup_scheduler_service.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:sqlite3/open.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, () => DynamicLibrary.open('libsqlcipher.so'));
  }

  await NotificationService().init();
  final container = ProviderContainer();
  container.read(backupSchedulerServiceProvider).initialize();
  container.read(appLifecycleLockManagerProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'Open Cloud Health',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        Widget content = child ?? const SizedBox.shrink();
        if (!kReleaseMode) {
          content = AccessibilityTools(
            child: content,
          );
        }
        return AppLockOverlay(child: content);
      },
    );
  }
}
