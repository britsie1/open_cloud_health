import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/storage_info.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/screens/settings.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';

class MockBackupService extends Mock implements BackupService {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockSecureStorage extends Mock implements SecureStorage {}
class MockProfilesRepository extends Mock implements ProfilesRepository {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockBackupService mockBackupService;
  late MockDatabaseHelper mockDatabaseHelper;
  late MockSecureStorage mockSecureStorage;
  late MockProfilesRepository mockProfilesRepository;

  setUp(() {
    mockBackupService = MockBackupService();
    mockDatabaseHelper = MockDatabaseHelper();
    mockSecureStorage = MockSecureStorage();
    mockProfilesRepository = MockProfilesRepository();

    when(() => mockDatabaseHelper.getDatabaseSize())
        .thenAnswer((_) async => 1024 * 50); // 50 KB
    when(() => mockSecureStorage.getLastProfileId())
        .thenAnswer((_) async => 'profile-1');
  });

  testWidgets('SettingsScreen displays disconnected Google Drive backup state',
      (WidgetTester tester) async {
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
          databaseHelperProvider.overrideWithValue(mockDatabaseHelper),
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
    expect(find.text('Reset Database'), findsOneWidget);
  });

  testWidgets('SettingsScreen displays connected WhatsApp-style Google Storage metrics',
      (WidgetTester tester) async {
    final mockAccount = MockGoogleSignInAccount();
    when(() => mockAccount.email).thenReturn('jane.doe@gmail.com');
    when(() => mockAccount.displayName).thenReturn('Jane Doe');
    when(() => mockAccount.photoUrl).thenReturn(null);

    when(() => mockBackupService.getConnectedUser())
        .thenAnswer((_) async => mockAccount);
    when(() => mockProfilesRepository.fetchProfiles()).thenAnswer((_) async => []);

    const storageInfo = GoogleStorageInfo(
      totalBytes: 15 * 1024 * 1024 * 1024, // 15 GB
      usedBytes: 5 * 1024 * 1024 * 1024,  // 5 GB
      driveUsedBytes: 2 * 1024 * 1024 * 1024,
      trashUsedBytes: 100 * 1024 * 1024,
      appBackupBytes: 4 * 1024 * 1024,     // 4 MB
      userEmail: 'jane.doe@gmail.com',
      displayName: 'Jane Doe',
      lastBackupDateTime: '2026-08-17 08:30',
    );

    when(() => mockBackupService.getGoogleStorageInfo(interactive: false))
        .thenAnswer((_) async => storageInfo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupServiceProvider.overrideWithValue(mockBackupService),
          databaseHelperProvider.overrideWithValue(mockDatabaseHelper),
          secureStorageProvider.overrideWithValue(mockSecureStorage),
          profilesRepositoryProvider.overrideWithValue(mockProfilesRepository),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Account info
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('jane.doe@gmail.com'), findsOneWidget);

    // Verify WhatsApp-style storage bar
    expect(find.text('Google Storage'), findsOneWidget);
    expect(find.text('5.0 GB of 15.0 GB used'), findsOneWidget);
    expect(find.text('10.0 GB available'), findsOneWidget);
    expect(find.text('33.3%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Verify backup stats and buttons
    expect(find.text('Medical Data Backup Size'), findsOneWidget);
    expect(find.text('4.0 MB'), findsOneWidget);
    expect(find.text('Back Up Now'), findsOneWidget);
    expect(find.text('Manage Google Storage'), findsOneWidget);
    expect(find.text('Disconnect'), findsOneWidget);
  });
}
