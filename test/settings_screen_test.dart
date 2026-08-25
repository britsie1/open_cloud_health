import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/backup_frequency.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/storage_info.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/screens/security_setup.dart';
import 'package:open_cloud_health/screens/settings.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/utils/constants.dart';

class MockBackupService extends Mock implements BackupService {}
class MockAppDatabase extends Mock implements AppDatabase {}
class MockSecureStorage extends Mock implements SecureStorage {}
class MockProfilesRepository extends Mock implements ProfilesRepository {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockFileService extends Mock implements FileService {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockBackupService mockBackupService;
  late MockAppDatabase mockAppDatabase;
  late MockSecureStorage mockSecureStorage;
  late MockProfilesRepository mockProfilesRepository;
  late MockFileService mockFileService;
  late MockNotificationService mockNotificationService;

  setUpAll(() {
    registerFallbackValue(BackupFrequency.daily);
  });

  setUp(() {
    mockBackupService = MockBackupService();
    mockAppDatabase = MockAppDatabase();
    mockSecureStorage = MockSecureStorage();
    mockProfilesRepository = MockProfilesRepository();
    mockFileService = MockFileService();
    mockNotificationService = MockNotificationService();

    when(() => mockAppDatabase.getDatabaseSize())
        .thenAnswer((_) async => 1024 * 50); // 50 KB
    when(() => mockAppDatabase.resetDatabase())
        .thenAnswer((_) async => {});
    when(() => mockFileService.deleteAllLocalFiles())
        .thenAnswer((_) async => {});
    when(() => mockNotificationService.cancelAllNotifications())
        .thenAnswer((_) async => {});
    when(() => mockSecureStorage.clear())
        .thenAnswer((_) async => {});
    when(() => mockAppDatabase.isLocalAuthEnabled())
        .thenAnswer((_) async => false);
    when(() => mockAppDatabase.isSecurityBannerDismissed())
        .thenAnswer((_) async => false);
    when(() => mockSecureStorage.getLastProfileId())
        .thenAnswer((_) async => 'profile-1');
    when(() => mockSecureStorage.isE2eBackupEnabled())
        .thenAnswer((_) async => false);
    when(() => mockSecureStorage.getE2eRecoveryKey())
        .thenAnswer((_) async => '12345678-12345678-12345678-12345678-12345678-12345678-12345678-12345678');
    when(() => mockSecureStorage.getBackupFrequency())
        .thenAnswer((_) async => BackupFrequency.daily);
    when(() => mockSecureStorage.getBackupWifiOnly())
        .thenAnswer((_) async => true);
    when(() => mockSecureStorage.setBackupFrequency(any()))
        .thenAnswer((_) async {});
    when(() => mockSecureStorage.setBackupWifiOnly(any()))
        .thenAnswer((_) async {});
    when(() => mockProfilesRepository.watchProfiles())
        .thenAnswer((_) => const Stream.empty());
    when(() => mockSecureStorage.isStrictBiometricsOnly())
        .thenAnswer((_) async => false);
    when(() => mockSecureStorage.setStrictBiometricsOnly(any()))
        .thenAnswer((_) async {});
    when(() => mockSecureStorage.getAutoLockGraceSeconds())
        .thenAnswer((_) async => 30);
    when(() => mockSecureStorage.setAutoLockGraceSeconds(any()))
        .thenAnswer((_) async {});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.opencloudhealth.app/security'),
      (call) async => true,
    );
  });

  testWidgets('SettingsScreen displays disconnected Google Drive backup state',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    when(() => mockBackupService.getConnectedUser()).thenAnswer((_) async => null);
    when(() => mockProfilesRepository.fetchProfiles()).thenAnswer((_) async => [
          Profile(
            id: 'profile-1',
            name: 'Alice',
            middleNames: '',
            surname: 'Smith',
            dateOfBirth: DateTime(1990, 1, 1),
            gender: Gender.female,
            bloodType: 'O+',
            isOrganDonor: true,
          ),
        ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupServiceProvider.overrideWithValue(mockBackupService),
          appDatabaseProvider.overrideWithValue(mockAppDatabase),
          secureStorageProvider.overrideWithValue(mockSecureStorage),
          profilesRepositoryProvider.overrideWithValue(mockProfilesRepository),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Google Drive Backup'), findsOneWidget);
    expect(find.text('Connect to Google Drive'), findsOneWidget);
    expect(find.text('App Lock & Security'), findsOneWidget);
    expect(find.text('Emergency Lock Screen Info'), findsOneWidget);
    expect(find.text('Export Local Backup (.ochbackup)'), findsOneWidget);
    expect(find.text('Import Local Backup'), findsOneWidget);
    expect(find.text('Reset Database'), findsOneWidget);
  });

  testWidgets('SettingsScreen displays connected WhatsApp-style Google Storage metrics & Auto-Backup settings',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockAccount = MockGoogleSignInAccount();
    when(() => mockAccount.email).thenReturn('jane.doe@gmail.com');
    when(() => mockAccount.displayName).thenReturn('Jane Doe');
    when(() => mockAccount.photoUrl).thenReturn(null);

    when(() => mockBackupService.getConnectedUser()).thenAnswer((_) async => mockAccount);
    when(() => mockBackupService.getGoogleStorageInfo(interactive: false)).thenAnswer(
      (_) async => const GoogleStorageInfo(
        usedBytes: 1024 * 1024 * 500, // 500 MB
        totalBytes: 1024 * 1024 * 1024 * 15, // 15 GB
        driveUsedBytes: 1024 * 1024 * 200,
        trashUsedBytes: 0,
        appBackupBytes: 1024 * 512, // 512 KB
        userEmail: 'jane.doe@gmail.com',
        displayName: 'Jane Doe',
        lastBackupDateTime: '2026-08-17 03:00',
        isE2eEncrypted: true,
      ),
    );
    when(() => mockProfilesRepository.fetchProfiles()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupServiceProvider.overrideWithValue(mockBackupService),
          appDatabaseProvider.overrideWithValue(mockAppDatabase),
          secureStorageProvider.overrideWithValue(mockSecureStorage),
          profilesRepositoryProvider.overrideWithValue(mockProfilesRepository),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('jane.doe@gmail.com'), findsOneWidget);
    expect(find.text('Google Storage'), findsOneWidget);
    expect(find.text('500.0 MB of 15.0 GB used'), findsOneWidget);
    expect(find.text('Encrypted Backup Size'), findsOneWidget);
    expect(find.text('512.0 KB'), findsOneWidget);
    expect(find.text('Last Cloud Backup'), findsOneWidget);
    expect(find.text('2026-08-17 03:00'), findsOneWidget);
    expect(find.text('Back up to Google Drive'), findsOneWidget);
    expect(find.text('Back up over Wi-Fi only'), findsOneWidget);

    // Tap frequency selector
    await tester.tap(find.text('Back up to Google Drive'));
    await tester.pumpAndSettle();

    expect(find.text('Idle Hours Auto-Backup'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
  });

  testWidgets('SecuritySetupScreen displays universal encryption at rest setting',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    when(() => mockSecureStorage.isE2eBackupEnabled())
        .thenAnswer((_) async => false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupServiceProvider.overrideWithValue(mockBackupService),
          appDatabaseProvider.overrideWithValue(mockAppDatabase),
          secureStorageProvider.overrideWithValue(mockSecureStorage),
        ],
        child: const MaterialApp(
          home: SecuritySetupScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('App Lock & Security'), findsOneWidget);
    expect(find.text('Backup Encryption at Rest'), findsOneWidget);
    expect(find.text('Active • Hardware & Account-bound AES-256'), findsOneWidget);
    expect(find.text('ENCRYPTED'), findsOneWidget);
  });

  testWidgets('SecuritySetupScreen opens and dismisses Backup Encryption at Rest setup sheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    when(() => mockSecureStorage.isE2eBackupEnabled())
        .thenAnswer((_) async => false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupServiceProvider.overrideWithValue(mockBackupService),
          appDatabaseProvider.overrideWithValue(mockAppDatabase),
          secureStorageProvider.overrideWithValue(mockSecureStorage),
        ],
        child: const MaterialApp(
          home: SecuritySetupScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Backup Encryption at Rest
    await tester.tap(find.text('Backup Encryption at Rest'));
    await tester.pumpAndSettle();

    expect(find.text('End-to-End Encrypted Backup'), findsOneWidget);
    expect(find.text('Zero-Knowledge Medical Data Shield'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Tap Cancel to dismiss
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('End-to-End Encrypted Backup'), findsNothing);
    expect(find.text('App Lock & Security'), findsOneWidget);
  });

  testWidgets('SecuritySetupScreen opens and dismisses Manage E2E Encryption sheet with Close button',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    when(() => mockSecureStorage.isE2eBackupEnabled())
        .thenAnswer((_) async => true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupServiceProvider.overrideWithValue(mockBackupService),
          appDatabaseProvider.overrideWithValue(mockAppDatabase),
          secureStorageProvider.overrideWithValue(mockSecureStorage),
        ],
        child: const MaterialApp(
          home: SecuritySetupScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Backup Encryption at Rest (active E2E)
    await tester.tap(find.text('Backup Encryption at Rest'));
    await tester.pumpAndSettle();

    expect(find.text('End-to-End Encryption Active'), findsOneWidget);
    expect(find.text('View 64-Digit Recovery Key'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    // Tap Close button to dismiss
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('End-to-End Encryption Active'), findsNothing);
    expect(find.text('App Lock & Security'), findsOneWidget);
  });

  testWidgets('SettingsScreen Reset All Data triggers full teardown and wipe',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    when(() => mockBackupService.getConnectedUser()).thenAnswer((_) async => null);
    when(() => mockProfilesRepository.fetchProfiles()).thenAnswer((_) async => []);

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.welcome,
          builder: (context, state) => const Scaffold(body: Text('Welcome Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupServiceProvider.overrideWithValue(mockBackupService),
          appDatabaseProvider.overrideWithValue(mockAppDatabase),
          secureStorageProvider.overrideWithValue(mockSecureStorage),
          profilesRepositoryProvider.overrideWithValue(mockProfilesRepository),
          fileServiceProvider.overrideWithValue(mockFileService),
          notificationServiceProvider.overrideWithValue(mockNotificationService),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find and tap "Reset Database"
    final resetFinder = find.text('Reset Database');
    await tester.scrollUntilVisible(resetFinder, 500);
    expect(resetFinder, findsOneWidget);
    await tester.tap(resetFinder);
    await tester.pumpAndSettle();

    // Verify confirmation modal appears
    expect(find.text('Reset Everything'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap "Reset Everything"
    await tester.tap(find.text('Reset Everything'));
    await tester.pumpAndSettle();

    // Verify teardown actions were called
    verify(() => mockNotificationService.cancelAllNotifications()).called(1);
    verify(() => mockFileService.deleteAllLocalFiles()).called(1);
    verify(() => mockAppDatabase.resetDatabase()).called(1);
    verify(() => mockSecureStorage.clear()).called(1);
    expect(find.text('Welcome Screen'), findsOneWidget);
  });
}
