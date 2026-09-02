import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/profile_share_models.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/repositories/history_repository.dart';
import 'package:open_cloud_health/repositories/medications_repository.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/screens/share_import_screen.dart';
import 'package:open_cloud_health/screens/welcome.dart';
import 'package:open_cloud_health/services/backup_scheduler_service.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/utils/result.dart';
import 'package:open_cloud_health/utils/security_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockNotificationService extends Mock implements NotificationService {}
class MockMedicationsRepository extends Mock implements MedicationsRepository {}
class MockProfilesRepository extends Mock implements ProfilesRepository {}
class MockHistoryRepository extends Mock implements HistoryRepository {}
class MockFileService extends Mock implements FileService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MVP 1 Architecture & Security Tests', () {
    test('Database creates performance indices on key foreign keys and timestamps', () async {
      final inMemoryDb = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => await inMemoryDb.close());

      // Trigger beforeOpen by running a query
      await inMemoryDb.select(inMemoryDb.profiles).get();

      final result = await inMemoryDb.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
      ).get();

      final indexNames = result.map((r) => r.read<String>('name')).toList();

      expect(indexNames, contains('idx_medications_profileId'));
      expect(indexNames, contains('idx_medication_logs_medId_ts'));
      expect(indexNames, contains('idx_vital_logs_profileId_date'));
      expect(indexNames, contains('idx_history_profileId_date'));
      expect(indexNames, contains('idx_period_cycles_profileId'));
      expect(indexNames, contains('idx_period_logs_cycleId_date'));
      expect(indexNames, contains('idx_allergy_profileId'));
      expect(indexNames, contains('idx_attachments_historyId'));
      expect(indexNames, contains('idx_emergency_contacts_profileId'));
      expect(indexNames, contains('idx_insurance_profileId'));
    });

    test('NotificationService resolveScheduleMode returns valid schedule mode without crashing', () async {
      final service = NotificationService();
      final mode = await service.resolveScheduleMode();
      expect(mode, isA<AndroidScheduleMode>());
    });

    test('SecurityUtils setSecureScreen executes safely', () async {
      await expectLater(SecurityUtils.setSecureScreen(true), completes);
      await expectLater(SecurityUtils.setSecureScreen(false), completes);
    });

    test('ShareLinkPayload parses universal links and custom scheme URIs accurately', () {
      const universalUri =
          'https://opencloudhealth.app/share?fileId=drive_123&name=Jane+Doe&by=John#key=secret_aes_key_456';
      final payload = ShareLinkPayload.parse(universalUri);

      expect(payload, isNotNull);
      expect(payload!.fileId, equals('drive_123'));
      expect(payload.key, equals('secret_aes_key_456'));
      expect(payload.profileName, equals('Jane Doe'));
      expect(payload.sharedBy, equals('John'));

      const customUri =
          'opencloudhealth://share?fileId=custom_file_789&name=Baby+Doe#key=pass_999';
      final customPayload = ShareLinkPayload.parse(customUri);

      expect(customPayload, isNotNull);
      expect(customPayload!.fileId, equals('custom_file_789'));
      expect(customPayload.key, equals('pass_999'));
      expect(customPayload.profileName, equals('Baby Doe'));
    });

    test('BackupSchedulerService onAppResume executes without error', () async {
      final container = ProviderContainer();
      final scheduler = container.read(backupSchedulerServiceProvider);
      expect(() => scheduler.onAppResume(), returnsNormally);
      await Future.delayed(const Duration(milliseconds: 50));
      container.dispose();
    });

    test('ProfilesNotifier.deleteProfilePermanently cancels notifications for medications in that profile', () async {
      final mockProfilesRepo = MockProfilesRepository();
      final mockMedicationsRepo = MockMedicationsRepository();
      final mockNotifService = MockNotificationService();
      final mockHistoryRepo = MockHistoryRepository();
      final mockFileService = MockFileService();

      when(() => mockProfilesRepo.watchProfiles()).thenAnswer((_) => const Stream.empty());
      when(() => mockProfilesRepo.fetchProfiles(includeArchived: false)).thenAnswer((_) async => []);
      when(() => mockProfilesRepo.deleteProfile('p1')).thenAnswer((_) async {});
      when(() => mockNotifService.syncEmergencyNotification(any())).thenAnswer((_) async {});
      when(() => mockNotifService.cancelMedicationNotifications(any())).thenAnswer((_) async {});
      when(() => mockHistoryRepo.fetchEvents(any())).thenAnswer((_) async => []);
      when(() => mockFileService.deleteProfileFiles(any(), any())).thenAnswer((_) async {});
      when(() => mockFileService.localPath).thenAnswer((_) async => Directory.systemTemp.path);

      final testMed = Medication(
        id: 'med_123',
        profileId: 'p1',
        name: 'Aspirin',
        dosage: '100mg',
        type: 'Pill',
        notificationEnabled: true,
        alarmEnabled: false,
        timeOfDay: const TimeOfDay(hour: 8, minute: 0),
        isActive: true,
      );

      when(() => mockMedicationsRepo.fetchMedications('p1')).thenAnswer((_) async => [testMed]);

      final container = ProviderContainer(
        overrides: [
          profilesRepositoryProvider.overrideWithValue(mockProfilesRepo),
          medicationsRepositoryProvider.overrideWithValue(mockMedicationsRepo),
          notificationServiceProvider.overrideWithValue(mockNotifService),
          historyRepositoryProvider.overrideWithValue(mockHistoryRepo),
          fileServiceProvider.overrideWithValue(mockFileService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(profilesProvider.future);
      final result = await container.read(profilesProvider.notifier).deleteProfilePermanently('p1');

      expect(result, isA<Success<void, Exception>>());
      verify(() => mockMedicationsRepo.fetchMedications('p1')).called(1);
      verify(() => mockNotifService.cancelMedicationNotifications('med_123')).called(1);
      verify(() => mockProfilesRepo.deleteProfile('p1')).called(1);
    });

    testWidgets('WelcomeScreen displays informational medical disclaimer badge', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Informational tracking tool • Not a medical device'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('ShareImportScreen renders invitation card with payload information', (tester) async {
      final payload = ShareLinkPayload(
        fileId: 'test_file_id',
        key: 'test_key',
        profileName: 'Alice Smith',
        sharedBy: 'Dr. Bob',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ShareImportScreen(payload: payload),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shared Profile Invitation'), findsOneWidget);
      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Shared by Dr. Bob'), findsOneWidget);
      expect(find.text('Import Profile'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('ShareImportScreen renders invalid link state when payload is null', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ShareImportScreen(payload: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invalid Share Link'), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsOneWidget);
    });
  });
}
