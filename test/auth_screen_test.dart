import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/screens/auth.dart';
import 'package:open_cloud_health/services/backup_encryption_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/utils/constants.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockSecureStorage extends Mock implements SecureStorage {}
class MockProfilesRepository extends Mock implements ProfilesRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDatabaseHelper mockDatabaseHelper;
  late MockSecureStorage mockSecureStorage;
  late MockProfilesRepository mockProfilesRepository;

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    mockSecureStorage = MockSecureStorage();
    mockProfilesRepository = MockProfilesRepository();

    when(() => mockDatabaseHelper.isLocalAuthEnabled())
        .thenAnswer((_) async => true);
    when(() => mockSecureStorage.getLastProfileId())
        .thenAnswer((_) async => 'profile-1');
    when(() => mockSecureStorage.isStrictBiometricsOnly())
        .thenAnswer((_) async => false);
    when(() => mockProfilesRepository.fetchProfiles(includeArchived: any(named: 'includeArchived'))).thenAnswer((_) async => [
          Profile(
            id: 'profile-1',
            name: 'John',
            middleNames: '',
            surname: 'Doe',
            dateOfBirth: DateTime(1990, 1, 1),
            gender: Gender.male,
            bloodType: 'A+',
            isOrganDonor: true,
          ),
        ]);

    // Mock local_auth method channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/local_auth'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'isDeviceSupported') return true;
        if (methodCall.method == 'canCheckBiometrics') return true;
        if (methodCall.method == 'getAvailableBiometrics') {
          return ['fingerprint'];
        }
        if (methodCall.method == 'authenticate') return false; // simulated cancelled/failed
        return null;
      },
    );

    // Mock security integrity channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.opencloudhealth.app/security'),
      (call) async => true,
    );

    // Mock notifications and timezone channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (call) async => 'UTC',
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/local_auth'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.opencloudhealth.app/security'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      null,
    );
  });

  GoRouter createTestRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '${AppRoutes.home}/:id',
          builder: (context, state) => const Scaffold(body: Text('Home Screen')),
        ),
        GoRoute(
          path: AppRoutes.profiles,
          builder: (context, state) => const Scaffold(body: Text('Profiles Screen')),
        ),
        GoRoute(
          path: AppRoutes.welcome,
          builder: (context, state) => const Scaffold(body: Text('Welcome Screen')),
        ),
      ],
    );
  }

  testWidgets('AuthScreen displays standard login when custom password is NOT enabled',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    when(() => mockSecureStorage.isE2eBackupEnabled())
        .thenAnswer((_) async => false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseHelperProvider.overrideWithValue(mockDatabaseHelper),
          secureStorageProvider.overrideWithValue(mockSecureStorage),
          profilesRepositoryProvider.overrideWithValue(mockProfilesRepository),
        ],
        child: MaterialApp.router(
          routerConfig: createTestRouter(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('OpenCloudHealth'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Emergency Medical ID'), findsOneWidget);
    expect(find.text('Enter Master Password / PIN'), findsNothing);
  });

  testWidgets('AuthScreen displays biometric fast pass and Master Password / PIN option when enabled',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const testPassword = '1234';
    final salt = BackupEncryptionService.generateSalt();
    final hash = BackupEncryptionService.hashPassword(testPassword, salt);

    when(() => mockSecureStorage.isE2eBackupEnabled())
        .thenAnswer((_) async => true);
    when(() => mockSecureStorage.getE2ePasswordHash())
        .thenAnswer((_) async => hash);
    when(() => mockSecureStorage.getE2eSalt())
        .thenAnswer((_) async => base64Encode(salt));
    when(() => mockSecureStorage.getE2eRecoveryKey())
        .thenAnswer((_) async => '11111111-22222222-33333333-44444444-55555555-66666666-77777777-88888888');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseHelperProvider.overrideWithValue(mockDatabaseHelper),
          secureStorageProvider.overrideWithValue(mockSecureStorage),
          profilesRepositoryProvider.overrideWithValue(mockProfilesRepository),
        ],
        child: MaterialApp.router(
          routerConfig: createTestRouter(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Unlock with Biometrics'), findsOneWidget);
    expect(find.text('Enter Master Password / PIN'), findsOneWidget);

    // Tap Enter Master Password / PIN
    await tester.tap(find.text('Enter Master Password / PIN'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Master Password / PIN'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Enter wrong password
    await tester.enterText(find.byType(TextField), '9999');
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Incorrect password or PIN. Please try again.'), findsOneWidget);

    // Enter correct PIN
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // After success, it navigates to Home Screen
    expect(find.text('Home Screen'), findsOneWidget);
  });

  testWidgets('AuthScreen displays Unlock with Biometrics when strict biometrics is toggled ON without password',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    when(() => mockSecureStorage.isE2eBackupEnabled())
        .thenAnswer((_) async => false);
    when(() => mockSecureStorage.isStrictBiometricsOnly())
        .thenAnswer((_) async => true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseHelperProvider.overrideWithValue(mockDatabaseHelper),
          secureStorageProvider.overrideWithValue(mockSecureStorage),
          profilesRepositoryProvider.overrideWithValue(mockProfilesRepository),
        ],
        child: MaterialApp.router(
          routerConfig: createTestRouter(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Unlock with Biometrics'), findsOneWidget);
    expect(find.text('Enter Master Password / PIN'), findsNothing);
  });
}
