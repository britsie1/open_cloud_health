import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/routing/app_router.dart';
import 'package:open_cloud_health/services/backup_scheduler_service.dart';
import 'package:open_cloud_health/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  final container = ProviderContainer();
  container.read(backupSchedulerServiceProvider).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'Open Cloud Health',
      builder: (context, child) {
        if (kReleaseMode || child == null) {
          return child ?? const SizedBox.shrink();
        }
        return AccessibilityTools(
          child: child,
        );
      },
      theme: ThemeData().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
