import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/repositories/shared_profiles_repository.dart';
import 'package:open_cloud_health/screens/welcome.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/utils/constants.dart';

class MockBackupService extends Mock implements BackupService {}
class MockAppDatabase extends Mock implements AppDatabase {}
class MockSecureStorage extends Mock implements SecureStorage {}
class MockProfilesRepository extends Mock implements ProfilesRepository {}
class MockSharedProfilesRepository extends Mock implements SharedProfilesRepository {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBackupService mockBackupService;
  late MockAppDatabase mockAppDatabase;
  late MockSecureStorage mockSecureStorage;
  late MockProfilesRepository mockProfilesRepository;
  late MockSharedProfilesRepository mockSharedProfilesRepository;
  late MockNotificationService mockNotificationService;

  final sampleProfile = Profile(
    id: 'test-profile-1',
    name: 'Jane',
    middleNames: '',
    surname: 'Doe',
    dateOfBirth: DateTime(1995, 5, 20),
    gender: Gender.female,
    bloodType: 'O+',
    isOrganDonor: true,
  );

  setUp(() {
    mockBackupService = MockBackupService();
    mockAppDatabase = MockAppDatabase();
    mockSecureStorage = MockSecureStorage();
    mockProfilesRepository = MockProfilesRepository();
    mockSharedProfilesRepository = MockSharedProfilesRepository();
    mockNotificationService = MockNotificationService();

    when(() => mockProfilesRepository.watchProfiles(includeArchived: any(named: 'includeArchived')))
        .thenAnswer((_) => Stream.value([sampleProfile]));
    when(() => mockProfilesRepository.watchProfiles())
        .thenAnswer((_) => Stream.value([sampleProfile]));
    when(() => mockProfilesRepository.fetchProfiles(includeArchived: any(named: 'includeArchived')))
        .thenAnswer((_) async => [sampleProfile]);
    when(() => mockProfilesRepository.fetchProfiles())
        .thenAnswer((_) async => [sampleProfile]);
    when(() => mockSharedProfilesRepository.getSharedProfiles())
        .thenAnswer((_) async => []);
    when(() => mockSecureStorage.getLastProfileId())
        .thenAnswer((_) async => sampleProfile.id);
    when(() => mockNotificationService.syncEmergencyNotification(any()))
        .thenAnswer((_) async => {});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.opencloudhealth.app/security'),
      (call) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => '.',
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.opencloudhealth.app/security'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  GoRouter createWelcomeTestRouter() {
    return GoRouter(
      initialLocation: AppRoutes.welcome,
      routes: [
        GoRoute(
          path: AppRoutes.welcome,
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileDetail,
          builder: (context, state) => const Scaffold(body: Text('Profile Detail Screen')),
        ),
        GoRoute(
          path: AppRoutes.importProfile,
          builder: (context, state) => const Scaffold(body: Text('Import Profile Screen')),
        ),
        GoRoute(
          path: AppRoutes.qrScanner,
          builder: (context, state) => const Scaffold(body: Text('QR Scanner Screen')),
        ),
        GoRoute(
          path: AppRoutes.homeBase,
          builder: (context, state) => const Scaffold(body: Text('Home Base Screen')),
        ),
        GoRoute(
          path: AppRoutes.profiles,
          builder: (context, state) => const Scaffold(body: Text('Profiles Screen')),
        ),
      ],
    );
  }

  Widget createWidgetUnderTest(GoRouter router) {
    return ProviderScope(
      overrides: [
        backupServiceProvider.overrideWithValue(mockBackupService),
        appDatabaseProvider.overrideWithValue(mockAppDatabase),
        secureStorageProvider.overrideWithValue(mockSecureStorage),
        profilesRepositoryProvider.overrideWithValue(mockProfilesRepository),
        sharedProfilesRepositoryProvider.overrideWithValue(mockSharedProfilesRepository),
        notificationServiceProvider.overrideWithValue(mockNotificationService),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('WelcomeScreen renders all UI elements and buttons correctly', (WidgetTester tester) async {
    final router = createWelcomeTestRouter();
    await tester.pumpWidget(createWidgetUnderTest(router));
    await tester.pumpAndSettle();

    expect(find.text('Open Cloud Health'), findsOneWidget);
    expect(find.text('Create New Profile'), findsOneWidget);
    expect(find.text('Import From File'), findsOneWidget);
    expect(find.text('Scan Share QR Code'), findsOneWidget);
    expect(find.text('Restore From Cloud Backup'), findsOneWidget);
  });

  testWidgets('Tapping Create New Profile navigates to profileDetail route', (WidgetTester tester) async {
    final router = createWelcomeTestRouter();
    await tester.pumpWidget(createWidgetUnderTest(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create New Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile Detail Screen'), findsOneWidget);
  });

  testWidgets('Tapping Import From File navigates to importProfile route', (WidgetTester tester) async {
    final router = createWelcomeTestRouter();
    await tester.pumpWidget(createWidgetUnderTest(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import From File'));
    await tester.pumpAndSettle();

    expect(find.text('Import Profile Screen'), findsOneWidget);
  });

  testWidgets('Tapping Scan Share QR Code navigates to qrScanner route', (WidgetTester tester) async {
    final router = createWelcomeTestRouter();
    await tester.pumpWidget(createWidgetUnderTest(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan Share QR Code'));
    await tester.pumpAndSettle();

    expect(find.text('QR Scanner Screen'), findsOneWidget);
  });

  testWidgets('Tapping Restore From Cloud Backup executes Google Drive restore and navigates to homeBase',
      (WidgetTester tester) async {
    final completer = Completer<void>();
    when(() => mockBackupService.restoreFromBackup()).thenAnswer((_) => completer.future);

    final router = createWelcomeTestRouter();
    await tester.pumpWidget(createWidgetUnderTest(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore From Cloud Backup'));
    await tester.pump();

    expect(find.text('Connecting to Google Drive...'), findsOneWidget);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    verify(() => mockBackupService.restoreFromBackup()).called(1);
    expect(find.text('Home Base Screen'), findsOneWidget);
    expect(find.text('🎉 Cloud backup restored successfully!'), findsOneWidget);
  });

  testWidgets('Tapping Restore From Cloud Backup prompts for password on FormatException and restores',
      (WidgetTester tester) async {
    when(() => mockBackupService.restoreFromBackup())
        .thenThrow(const FormatException('Encrypted'));
    final decryptCompleter = Completer<void>();
    when(() => mockBackupService.restoreFromBackup(password: 'secret123'))
        .thenAnswer((_) => decryptCompleter.future);

    final router = createWelcomeTestRouter();
    await tester.pumpWidget(createWidgetUnderTest(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore From Cloud Backup'));
    await tester.pumpAndSettle();

    expect(find.text('Encrypted Cloud Backup'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.tap(find.text('Decrypt & Restore'));
    await tester.pump();

    expect(find.text('Decrypting cloud backup...'), findsOneWidget);

    decryptCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    verify(() => mockBackupService.restoreFromBackup(password: 'secret123')).called(1);
    expect(find.text('Home Base Screen'), findsOneWidget);
  });

  testWidgets('Tapping Restore From Cloud Backup shows error snackbar on failure',
      (WidgetTester tester) async {
    when(() => mockBackupService.restoreFromBackup())
        .thenThrow(Exception('Google Drive connection failed'));

    final router = createWelcomeTestRouter();
    await tester.pumpWidget(createWidgetUnderTest(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore From Cloud Backup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Restore error: Exception: Google Drive connection failed'), findsOneWidget);
  });
}
