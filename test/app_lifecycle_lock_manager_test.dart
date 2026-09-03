import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/services/app_lifecycle_lock_manager.dart';
import 'package:open_cloud_health/services/backup_scheduler_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';

class MockAppDatabase extends Mock implements AppDatabase {}
class MockSecureStorage extends Mock implements SecureStorage {}
class MockBackupSchedulerService extends Mock implements BackupSchedulerService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAppDatabase mockAppDatabase;
  late MockSecureStorage mockSecureStorage;
  late MockBackupSchedulerService mockBackupSchedulerService;
  late ProviderContainer container;

  setUp(() {
    mockAppDatabase = MockAppDatabase();
    mockSecureStorage = MockSecureStorage();
    mockBackupSchedulerService = MockBackupSchedulerService();

    // Mock platform channel for SecurityUtils
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.opencloudhealth.app/security'),
      (call) async {
        if (call.method == 'isDeviceSecure') return true;
        if (call.method == 'setSecureScreen') return null;
        return null;
      },
    );

    when(() => mockBackupSchedulerService.onAppResume()).thenReturn(null);

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(mockAppDatabase),
        secureStorageProvider.overrideWithValue(mockSecureStorage),
        backupSchedulerServiceProvider.overrideWithValue(mockBackupSchedulerService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.opencloudhealth.app/security'),
      null,
    );
  });

  group('AppLifecycleLockManager Lifecycle & Grace Period Tests', () {
    test('Locks app on resume when pause duration exceeds grace seconds', () async {
      when(() => mockAppDatabase.isLocalAuthEnabled()).thenAnswer((_) async => true);
      when(() => mockSecureStorage.getAutoLockGraceSeconds()).thenAnswer((_) async => 0); // Immediate lock

      final manager = container.read(appLifecycleLockManagerProvider);

      expect(container.read(isAppLockedProvider), isFalse);

      // Simulate app pausing
      manager.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future.delayed(const Duration(milliseconds: 20));

      // Simulate app resuming
      manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(container.read(isAppLockedProvider), isTrue);

      // Unlock
      manager.unlock();
      expect(container.read(isAppLockedProvider), isFalse);
    });

    test('Does not lock app on resume when pause duration is within grace seconds', () async {
      when(() => mockAppDatabase.isLocalAuthEnabled()).thenAnswer((_) async => true);
      when(() => mockSecureStorage.getAutoLockGraceSeconds()).thenAnswer((_) async => 60); // 60 seconds grace

      final manager = container.read(appLifecycleLockManagerProvider);

      expect(container.read(isAppLockedProvider), isFalse);

      // Simulate app pausing briefly
      manager.didChangeAppLifecycleState(AppLifecycleState.inactive);
      await Future.delayed(const Duration(milliseconds: 10));

      // Simulate app resuming
      manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(container.read(isAppLockedProvider), isFalse);
    });

    test('Does not lock app when local auth is disabled', () async {
      when(() => mockAppDatabase.isLocalAuthEnabled()).thenAnswer((_) async => false);
      when(() => mockSecureStorage.getAutoLockGraceSeconds()).thenAnswer((_) async => 0);

      final manager = container.read(appLifecycleLockManagerProvider);

      expect(container.read(isAppLockedProvider), isFalse);

      manager.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future.delayed(const Duration(milliseconds: 20));

      manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(container.read(isAppLockedProvider), isFalse);
    });

    test('Does not lock app when device is not secure', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.opencloudhealth.app/security'),
        (call) async {
          if (call.method == 'isDeviceSecure') return false;
          return null;
        },
      );

      when(() => mockAppDatabase.isLocalAuthEnabled()).thenAnswer((_) async => true);
      when(() => mockSecureStorage.getAutoLockGraceSeconds()).thenAnswer((_) async => 0);

      final manager = container.read(appLifecycleLockManagerProvider);

      manager.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future.delayed(const Duration(milliseconds: 20));

      manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(container.read(isAppLockedProvider), isFalse);
    });

    test('Resuming invokes backupSchedulerService.onAppResume', () async {
      when(() => mockAppDatabase.isLocalAuthEnabled()).thenAnswer((_) async => false);

      final manager = container.read(appLifecycleLockManagerProvider);

      manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 50));

      verify(() => mockBackupSchedulerService.onAppResume()).called(1);
    });
  });
}
