import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/providers/allergies_provider.dart';
import 'package:open_cloud_health/providers/history_provider.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/repositories/allergies_repository.dart';
import 'package:open_cloud_health/repositories/attachment_repository.dart';
import 'package:open_cloud_health/repositories/checkups_repository.dart';
import 'package:open_cloud_health/repositories/history_repository.dart';
import 'package:open_cloud_health/repositories/medications_repository.dart';
import 'package:open_cloud_health/repositories/period_repository.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/providers/emergency_provider.dart';
import 'package:open_cloud_health/repositories/emergency_repository.dart';
import 'package:open_cloud_health/utils/result.dart';

class MockProfilesRepository extends Mock implements ProfilesRepository {}

class FakeProfile extends Fake implements Profile {}

class MockHistoryRepository extends Mock implements HistoryRepository {}

class FakeHistoryEvent extends Fake implements HistoryEvent {}

class MockMedicationsRepository extends Mock implements MedicationsRepository {}

class FakeMedication extends Fake implements Medication {}

class FakeMedicationLog extends Fake implements MedicationLog {}

class MockNotificationService extends Mock implements NotificationService {}

class MockAllergiesRepository extends Mock implements AllergiesRepository {}

class FakeAllergy extends Fake implements Allergy {}

class MockAttachmentRepository extends Mock implements AttachmentRepository {}

class MockFileService extends Mock implements FileService {}

class MockPeriodRepository extends Mock implements PeriodRepository {}

class MockCheckupsRepository extends Mock implements CheckupsRepository {}

class MockEmergencyRepository extends Mock implements EmergencyRepository {}

void main() {
  late MockProfilesRepository mockProfilesRepository;
  late MockHistoryRepository mockHistoryRepository;
  late MockMedicationsRepository mockMedicationsRepository;
  late MockNotificationService mockNotificationService;
  late MockAllergiesRepository mockAllergiesRepository;
  late MockAttachmentRepository mockAttachmentRepository;
  late MockFileService mockFileService;
  late MockPeriodRepository mockPeriodRepository;
  late MockCheckupsRepository mockCheckupsRepository;
  late MockEmergencyRepository mockEmergencyRepository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeProfile());
    registerFallbackValue(FakeHistoryEvent());
    registerFallbackValue(FakeMedication());
    registerFallbackValue(FakeMedicationLog());
    registerFallbackValue(FakeAllergy());
    registerFallbackValue(const TimeOfDay(hour: 0, minute: 0));
  });

  setUp(() {
    mockProfilesRepository = MockProfilesRepository();
    mockHistoryRepository = MockHistoryRepository();
    mockMedicationsRepository = MockMedicationsRepository();
    mockNotificationService = MockNotificationService();
    mockAllergiesRepository = MockAllergiesRepository();
    mockAttachmentRepository = MockAttachmentRepository();
    mockFileService = MockFileService();
    mockPeriodRepository = MockPeriodRepository();
    mockCheckupsRepository = MockCheckupsRepository();
    mockEmergencyRepository = MockEmergencyRepository();

    when(() => mockNotificationService.cancelNotification(any()))
        .thenAnswer((_) async => {});
    when(() => mockNotificationService.cancelMedicationNotifications(any()))
        .thenAnswer((_) async => {});
    when(() => mockNotificationService.syncEmergencyNotification(any()))
        .thenAnswer((_) async => {});
    when(() => mockNotificationService.scheduleDailyNotification(
            any(), any(), any(), any(), any()))
        .thenAnswer((_) async => {});
    when(() => mockNotificationService.scheduleWeeklyNotification(
            any(), any(), any(), any(), any(), any()))
        .thenAnswer((_) async => {});
    when(() => mockNotificationService.setSystemAlarm(
            any(), any(), any()))
        .thenAnswer((_) async => {});
    when(() => mockNotificationService.onMedicationMarkedTaken)
        .thenReturn(StreamController<String>.broadcast());
    when(() => mockFileService.localPath)
        .thenAnswer((_) async => Directory.systemTemp.path);
    when(() => mockPeriodRepository.getCycles(any()))
        .thenAnswer((_) async => []);
    when(() => mockCheckupsRepository.loadCheckups(any()))
        .thenAnswer((_) async => []);
    when(() => mockCheckupsRepository.loadAllLogsForProfile(any()))
        .thenAnswer((_) async => []);
    when(() => mockProfilesRepository.watchProfiles())
        .thenAnswer((_) => const Stream.empty());
    when(() => mockHistoryRepository.watchEvents(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockMedicationsRepository.watchMedications(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockMedicationsRepository.watchLogsForDate(any(), any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockMedicationsRepository.watchAllLogs(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAllergiesRepository.watchAllergies(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAttachmentRepository.watchAttachments(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPeriodRepository.watchCycles(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPeriodRepository.watchLogsForCycle(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockCheckupsRepository.watchCheckups(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockEmergencyRepository.watchEmergencyContacts(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockEmergencyRepository.watchLockScreenSetting(any()))
        .thenAnswer((_) => const Stream.empty());

    container = ProviderContainer(
      overrides: [
        profilesRepositoryProvider.overrideWithValue(mockProfilesRepository),
        historyRepositoryProvider.overrideWithValue(mockHistoryRepository),
        medicationsRepositoryProvider
            .overrideWithValue(mockMedicationsRepository),
        notificationServiceProvider.overrideWithValue(mockNotificationService),
        allergiesRepositoryProvider.overrideWithValue(mockAllergiesRepository),
        attachmentRepositoryProvider.overrideWithValue(mockAttachmentRepository),
        fileServiceProvider.overrideWithValue(mockFileService),
        periodRepositoryProvider.overrideWithValue(mockPeriodRepository),
        checkupsRepositoryProvider.overrideWithValue(mockCheckupsRepository),
        emergencyRepositoryProvider.overrideWithValue(mockEmergencyRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ProfilesProvider Tests', () {
    final tProfiles = [
      Profile(
        id: '1',
        name: 'John',
        middleNames: '',
        surname: 'Doe',
        dateOfBirth: DateTime(1990),
        gender: Gender.male,
        bloodType: 'O+',
        isOrganDonor: true,
      ),
    ];

    test('initial state should be data from repository', () async {
      when(() => mockProfilesRepository.fetchProfiles())
          .thenAnswer((_) async => tProfiles);

      await container.read(profilesProvider.future);

      expect(container.read(profilesProvider).value, tProfiles);
      verify(() => mockProfilesRepository.fetchProfiles()).called(1);
    });

    test('addProfile should call repository and update state', () async {
      when(() => mockProfilesRepository.fetchProfiles())
          .thenAnswer((_) async => []);
      when(() => mockProfilesRepository.addProfile(any()))
          .thenAnswer((_) async => {});

      await container.read(profilesProvider.future);

      final notifier = container.read(profilesProvider.notifier);
      
      // Update mock for the refresh call
      final profileAdded = Profile(
        name: 'Jane',
        middleNames: '',
        surname: 'Doe',
        dateOfBirth: DateTime(1995),
        gender: Gender.female,
        bloodType: 'A-',
        isOrganDonor: false,
      );
      when(() => mockProfilesRepository.fetchProfiles())
          .thenAnswer((_) async => [profileAdded]);

      final result = await notifier.addProfile(
          'Jane', '', 'Doe', DateTime(1995), Gender.female, 'A-', false);

      expect(result, isA<Success<String, Exception>>());

      expect(container.read(profilesProvider).value!.length, 1);
      expect(container.read(profilesProvider).value!.first.name, 'Jane');
      verify(() => mockProfilesRepository.addProfile(any())).called(1);
    });

    test('updateProfile should call repository and update state', () async {
      when(() => mockProfilesRepository.fetchProfiles())
          .thenAnswer((_) async => tProfiles);
      when(() => mockProfilesRepository.updateProfile(any()))
          .thenAnswer((_) async => {});

      await container.read(profilesProvider.future);

      final updatedProfile = Profile(
        id: '1',
        name: 'John Updated',
        middleNames: '',
        surname: 'Doe',
        dateOfBirth: DateTime(1990),
        gender: Gender.male,
        bloodType: 'O+',
        isOrganDonor: true,
      );
      
      // Update mock for the refresh call
      when(() => mockProfilesRepository.fetchProfiles())
          .thenAnswer((_) async => [updatedProfile]);

      final result = await container
          .read(profilesProvider.notifier)
          .updateProfile(updatedProfile);

      expect(result, isA<Success<void, Exception>>());
      verify(() => mockProfilesRepository.updateProfile(any())).called(1);
      expect(container.read(profilesProvider).value!.first.name, 'John Updated');
    });

    test('archiveProfile should archive profile and refresh state', () async {
      when(() => mockProfilesRepository.fetchProfiles(includeArchived: any(named: 'includeArchived')))
          .thenAnswer((_) async => tProfiles);
      when(() => mockProfilesRepository.updateProfile(any()))
          .thenAnswer((_) async => {});

      await container.read(profilesProvider.future);

      final notifier = container.read(profilesProvider.notifier);

      // After archiving, fetchProfiles (which by default gets active profiles) returns empty
      when(() => mockProfilesRepository.fetchProfiles(includeArchived: false))
          .thenAnswer((_) async => []);

      final result = await notifier.archiveProfile('1');

      expect(result, isA<Success<void, Exception>>());
      verify(() => mockProfilesRepository.updateProfile(any())).called(1);
      expect(container.read(profilesProvider).value!.isEmpty, true);
    });

    test('restoreProfile should restore archived profile and refresh state', () async {
      final archivedProfile = Profile(
        id: '1',
        name: 'John',
        middleNames: '',
        surname: 'Doe',
        dateOfBirth: DateTime(1990),
        gender: Gender.male,
        bloodType: 'O+',
        isOrganDonor: true,
        isArchived: true,
        archivedAt: DateTime.now(),
      );

      when(() => mockProfilesRepository.fetchProfiles(includeArchived: true))
          .thenAnswer((_) async => [archivedProfile]);
      when(() => mockProfilesRepository.fetchProfiles(includeArchived: false))
          .thenAnswer((_) async => []);
      when(() => mockProfilesRepository.updateProfile(any()))
          .thenAnswer((_) async => {});

      await container.read(profilesProvider.future);

      final notifier = container.read(profilesProvider.notifier);

      // After restoring, fetchProfiles(includeArchived: false) returns restored profile
      final restoredProfile = Profile(
        id: '1',
        name: 'John',
        middleNames: '',
        surname: 'Doe',
        dateOfBirth: DateTime(1990),
        gender: Gender.male,
        bloodType: 'O+',
        isOrganDonor: true,
        isArchived: false,
        archivedAt: null,
      );
      when(() => mockProfilesRepository.fetchProfiles(includeArchived: false))
          .thenAnswer((_) async => [restoredProfile]);

      final result = await notifier.restoreProfile('1');

      expect(result, isA<Success<void, Exception>>());
      verify(() => mockProfilesRepository.updateProfile(any())).called(1);
      expect(container.read(profilesProvider).value!.first.isArchived, false);
    });

    test('deleteProfilePermanently should delete profile from repository and refresh state', () async {
      when(() => mockProfilesRepository.fetchProfiles(includeArchived: false))
          .thenAnswer((_) async => tProfiles);
      when(() => mockProfilesRepository.deleteProfile('1'))
          .thenAnswer((_) async => {});

      await container.read(profilesProvider.future);

      final notifier = container.read(profilesProvider.notifier);

      when(() => mockProfilesRepository.fetchProfiles(includeArchived: false))
          .thenAnswer((_) async => []);

      final result = await notifier.deleteProfilePermanently('1');

      expect(result, isA<Success<void, Exception>>());
      verify(() => mockProfilesRepository.deleteProfile('1')).called(1);
      expect(container.read(profilesProvider).value!.isEmpty, true);
    });

    test('checkAndDeleteExpiredProfiles should delete expired profiles', () async {
      final expiredProfile = Profile(
        id: '1',
        name: 'Expired',
        middleNames: '',
        surname: 'Doe',
        dateOfBirth: DateTime(1990),
        gender: Gender.male,
        bloodType: 'O+',
        isOrganDonor: true,
        isArchived: true,
        archivedAt: DateTime.now().subtract(const Duration(days: 35)),
      );

      final activeProfile = Profile(
        id: '2',
        name: 'Active',
        middleNames: '',
        surname: 'Doe',
        dateOfBirth: DateTime(1990),
        gender: Gender.male,
        bloodType: 'O+',
        isOrganDonor: true,
        isArchived: true,
        archivedAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      when(() => mockProfilesRepository.fetchProfiles(includeArchived: true))
          .thenAnswer((_) async => [expiredProfile, activeProfile]);
      when(() => mockProfilesRepository.fetchProfiles(includeArchived: false))
          .thenAnswer((_) async => []);
      when(() => mockProfilesRepository.deleteProfile('1'))
          .thenAnswer((_) async => {});

      final notifier = container.read(profilesProvider.notifier);

      await notifier.checkAndDeleteExpiredProfiles();

      verify(() => mockProfilesRepository.deleteProfile('1')).called(1);
      verifyNever(() => mockProfilesRepository.deleteProfile('2'));
    });
  });

  group('HistoryProvider Tests', () {
    final tEvents = [
      HistoryEvent(
        id: 'e1',
        profileId: 'p1',
        title: 'Fever',
        description: 'High temp',
        date: DateTime(2023, 10, 10),
      ),
    ];

    test('initial state should fetch events for profile', () async {
      when(() => mockHistoryRepository.fetchEvents('p1'))
          .thenAnswer((_) async => tEvents);

      await container.read(historyProvider('p1').future);

      expect(container.read(historyProvider('p1')).value, tEvents);
      verify(() => mockHistoryRepository.fetchEvents('p1')).called(1);
    });

    test('addEvent should call repository and update state', () async {
      when(() => mockHistoryRepository.fetchEvents('p1'))
          .thenAnswer((_) async => []);
      when(() => mockHistoryRepository.addEvent(any()))
          .thenAnswer((_) async => {});
      when(() => mockAttachmentRepository.getAttachments(any()))
          .thenAnswer((_) async => []);

      await container.read(historyProvider('p1').future);

      final notifier = container.read(historyProvider('p1').notifier);
      
      // Update mock for the refresh call
      final eventAdded = HistoryEvent(
        profileId: 'p1',
        title: 'Cough',
        description: 'Dry cough',
        date: DateTime(2023, 10, 11),
      );
      when(() => mockHistoryRepository.fetchEvents('p1'))
          .thenAnswer((_) async => [eventAdded]);

      final result = await notifier.saveEventWithAttachments(
        profileId: 'p1',
        title: 'Cough',
        description: 'Dry cough',
        date: DateTime(2023, 10, 11),
        eventType: EventType.other,
        hasTime: true,
        attachments: [],
      );

      expect(result, isA<Success<String, Exception>>());
      expect(container.read(historyProvider('p1')).value!.length, 1);
      expect(container.read(historyProvider('p1')).value!.first.title, 'Cough');
      verify(() => mockHistoryRepository.addEvent(any())).called(1);
    });

    test('deleteEvent should call repository and update state', () async {
      when(() => mockHistoryRepository.fetchEvents('p1'))
          .thenAnswer((_) async => List.from(tEvents));
      when(() => mockHistoryRepository.deleteEvent('e1'))
          .thenAnswer((_) async => {});
      when(() => mockAttachmentRepository.getAttachments('e1'))
          .thenAnswer((_) async => []);
      when(() => mockAttachmentRepository.deleteAttachments(any()))
          .thenAnswer((_) async => {});

      await container.read(historyProvider('p1').future);
      
      // Update mock for the refresh call
      when(() => mockHistoryRepository.fetchEvents('p1'))
          .thenAnswer((_) async => []);

      await container.read(historyProvider('p1').notifier).deleteEvent('e1');

      expect(container.read(historyProvider('p1')).value!.isEmpty, true);
      verify(() => mockHistoryRepository.deleteEvent('e1')).called(1);
    });

    test('fetchEvents should group consecutive period logs into a single HistoryEvent', () async {
      final now = DateTime(2026, 5, 20);
      final cycle = PeriodCycle(id: 'c1', profileId: 'p1', startDate: now);
      final logs = [
        PeriodLog(id: 'l1', cycleId: 'c1', date: now, flowLevel: FlowLevel.light, moods: [Mood.happy]),
        PeriodLog(id: 'l2', cycleId: 'c1', date: now.add(const Duration(days: 1)), flowLevel: FlowLevel.medium, moods: [Mood.calm], physicalSymptoms: [PhysicalSymptom.cramps]),
        PeriodLog(id: 'l3', cycleId: 'c1', date: now.add(const Duration(days: 2)), flowLevel: FlowLevel.medium, moods: [Mood.irritable]),
      ];

      when(() => mockHistoryRepository.fetchEvents('p1'))
          .thenAnswer((_) async => []);
      when(() => mockPeriodRepository.getCycles('p1'))
          .thenAnswer((_) async => [cycle]);
      when(() => mockPeriodRepository.getLogsForCycle('c1'))
          .thenAnswer((_) async => logs);

      final events = await container.read(historyProvider('p1').future);

      expect(events.length, 1);
      final periodEvent = events.first;
      expect(periodEvent.eventType, EventType.period);
      expect(periodEvent.title, 'Period (3 days)');
      expect(periodEvent.hasTime, false);
      expect(periodEvent.description, contains('3 consecutive days'));
      expect(periodEvent.description, contains('Flow: light, medium'));
      expect(periodEvent.description, contains('Moods: happy, calm, irritable'));
      expect(periodEvent.description, contains('Symptoms: cramps'));
    });

    test('fetchEvents should not group non-consecutive period logs (gap handling)', () async {
      final now = DateTime(2026, 5, 20);
      final cycle = PeriodCycle(id: 'c1', profileId: 'p1', startDate: now);
      final logs = [
        PeriodLog(id: 'l1', cycleId: 'c1', date: now, flowLevel: FlowLevel.light),
        PeriodLog(id: 'l3', cycleId: 'c1', date: now.add(const Duration(days: 2)), flowLevel: FlowLevel.medium),
      ];

      when(() => mockHistoryRepository.fetchEvents('p1'))
          .thenAnswer((_) async => []);
      when(() => mockPeriodRepository.getCycles('p1'))
          .thenAnswer((_) async => [cycle]);
      when(() => mockPeriodRepository.getLogsForCycle('c1'))
          .thenAnswer((_) async => logs);

      final events = await container.read(historyProvider('p1').future);

      expect(events.length, 2);
      expect(events[0].title, 'Period');
      expect(events[1].title, 'Period');
    });
  });

  group('MedicationsProvider Tests', () {
    final tMeds = [
      Medication(
        id: 'm1',
        profileId: 'p1',
        name: 'Aspirin',
        dosage: '100mg',
        timeOfDay: const TimeOfDay(hour: 8, minute: 0),
        isActive: true,
      ),
    ];

    test('initial state should fetch medications for profile', () async {
      when(() => mockMedicationsRepository.loadMedications('p1'))
          .thenAnswer((_) async => tMeds);

      await container.read(medicationsProvider('p1').future);

      expect(container.read(medicationsProvider('p1')).value, tMeds);
      verify(() => mockMedicationsRepository.loadMedications('p1')).called(1);
    });

    test('toggleIsActive should update repository, notifications and state',
        () async {
      when(() => mockMedicationsRepository.loadMedications('p1'))
          .thenAnswer((_) async => List.from(tMeds));
      when(() => mockMedicationsRepository.toggleIsActive(any(), any()))
          .thenAnswer((_) async => {});

      await container.read(medicationsProvider('p1').future);

      final medToggled = Medication(
        id: 'm1',
        profileId: 'p1',
        name: 'Aspirin',
        dosage: '100mg',
        timeOfDay: const TimeOfDay(hour: 8, minute: 0),
        isActive: false,
      );
      // Update mock for the refresh call
      when(() => mockMedicationsRepository.loadMedications('p1'))
          .thenAnswer((_) async => [medToggled]);

      await container
          .read(medicationsProvider('p1').notifier)
          .toggleIsActive(tMeds[0]);

      expect(container.read(medicationsProvider('p1')).value!.first.isActive,
          false);
      verify(() => mockMedicationsRepository.toggleIsActive('m1', false))
          .called(1);
      verify(() => mockNotificationService.cancelMedicationNotifications('m1')).called(1);
    });

    test('addMedication with isAsNeeded = true (PRN) should NOT schedule notifications or alarms', () async {
      final prnMed = Medication(
        id: 'm2',
        profileId: 'p1',
        name: 'Insulin',
        dosage: '5 Units',
        timeOfDay: const TimeOfDay(hour: 8, minute: 0),
        isActive: true,
        isAsNeeded: true,
        notificationEnabled: true,
        alarmEnabled: true,
      );

      when(() => mockMedicationsRepository.addMedication(any()))
          .thenAnswer((_) async => {});
      when(() => mockMedicationsRepository.loadMedications('p1'))
          .thenAnswer((_) async => [prnMed]);

      await container.read(medicationsProvider('p1').future);

      final result = await container
          .read(medicationsProvider('p1').notifier)
          .addMedication(prnMed);

      expect(result, isA<Success<void, Exception>>());
      verify(() => mockMedicationsRepository.addMedication(any())).called(1);
      verifyNever(() => mockNotificationService.scheduleWeeklyNotification(
            any(), any(), any(), any(), any(), any()));
      verifyNever(() => mockNotificationService.setSystemAlarm(
            any(), any(), any()));
    });
  });

  group('MedicationLogsProvider Tests', () {
    test('initial state should fetch logs for date', () async {
      final now = DateTime.now();
      final tLogs = [
        MedicationLog(id: 'l1', medicationId: 'm1', timestamp: now),
      ];

      when(() => mockMedicationsRepository.loadLogsForDate(any(), 'p1'))
          .thenAnswer((_) async => tLogs);

      await container.read(medicationLogsProvider('p1').future);

      expect(container.read(medicationLogsProvider('p1')).value, tLogs);
    });

    test('addLog should trigger repository addLog, refresh medications with decremented inventory stock', () async {
      final now = DateTime.now();
      final log = MedicationLog(id: 'l2', medicationId: 'm1', timestamp: now);
      final initialMed = Medication(
        id: 'm1',
        profileId: 'p1',
        name: 'Aspirin',
        dosage: '100mg',
        timeOfDay: const TimeOfDay(hour: 8, minute: 0),
        isActive: true,
        trackInventory: true,
        stockQuantity: 10.0,
      );
      final updatedMed = initialMed.copyWith(stockQuantity: 9.0);

      when(() => mockMedicationsRepository.addLog(any()))
          .thenAnswer((_) async => {});
      when(() => mockMedicationsRepository.loadLogsForDate(any(), 'p1'))
          .thenAnswer((_) async => [log]);
      
      var loadCount = 0;
      when(() => mockMedicationsRepository.loadMedications('p1'))
          .thenAnswer((_) async {
            loadCount++;
            return loadCount == 1 ? [initialMed] : [updatedMed];
          });

      // Load initial state
      await container.read(medicationsProvider('p1').future);
      await container.read(medicationLogsProvider('p1').future);

      expect(container.read(medicationsProvider('p1')).value!.first.stockQuantity, 10.0);

      // Perform addLog
      final result = await container
          .read(medicationLogsProvider('p1').notifier)
          .addLog(log);

      expect(result, isA<Success<void, Exception>>());
      verify(() => mockMedicationsRepository.addLog(any())).called(1);
      
      // Verify medicationsProvider was invalidated and loaded the updated stock quantity
      final medsState = await container.read(medicationsProvider('p1').future);
      expect(medsState.first.stockQuantity, 9.0);
    });

    test('removeLog should trigger repository removeLog, refresh medications with incremented inventory stock', () async {
      final now = DateTime.now();
      final medInitial = Medication(
        id: 'm1',
        profileId: 'p1',
        name: 'Aspirin',
        dosage: '100mg',
        timeOfDay: const TimeOfDay(hour: 8, minute: 0),
        isActive: true,
        trackInventory: true,
        stockQuantity: 9.0,
      );
      final medUpdated = medInitial.copyWith(stockQuantity: 10.0);

      when(() => mockMedicationsRepository.removeLog(any(), any(), time: any(named: 'time')))
          .thenAnswer((_) async => {});
      when(() => mockMedicationsRepository.loadLogsForDate(any(), 'p1'))
          .thenAnswer((_) async => []);

      var loadCount = 0;
      when(() => mockMedicationsRepository.loadMedications('p1'))
          .thenAnswer((_) async {
            loadCount++;
            return loadCount == 1 ? [medInitial] : [medUpdated];
          });

      // Load initial state
      await container.read(medicationsProvider('p1').future);
      await container.read(medicationLogsProvider('p1').future);

      expect(container.read(medicationsProvider('p1')).value!.first.stockQuantity, 9.0);

      // Perform removeLog
      final result = await container
          .read(medicationLogsProvider('p1').notifier)
          .removeLog('m1', now);

      expect(result, isA<Success<void, Exception>>());
      verify(() => mockMedicationsRepository.removeLog('m1', any(), time: any(named: 'time'))).called(1);

      // Verify medicationsProvider was invalidated and updated
      final medsState = await container.read(medicationsProvider('p1').future);
      expect(medsState.first.stockQuantity, 10.0);
    });
  });

  group('AllergiesProvider Tests', () {
    final tAllergies = [
      Allergy(id: 'a1', profileId: 'p1', name: 'Peanuts', note: 'Severe'),
    ];

    test('initial state should fetch allergies for profile', () async {
      when(() => mockAllergiesRepository.getAllergies('p1'))
          .thenAnswer((_) async => tAllergies);

      await container.read(allergiesProvider('p1').future);

      expect(container.read(allergiesProvider('p1')).value, tAllergies);
      verify(() => mockAllergiesRepository.getAllergies('p1')).called(1);
    });

    test('addAllergy should call repository and update state', () async {
      when(() => mockAllergiesRepository.getAllergies('p1'))
          .thenAnswer((_) async => []);
      when(() => mockAllergiesRepository.addAllergy(any()))
          .thenAnswer((_) async => {});

      await container.read(allergiesProvider('p1').future);

      final newAllergy = Allergy(id: 'a2', profileId: 'p1', name: 'Dust', note: '');
      // Update mock for the refresh call
      when(() => mockAllergiesRepository.getAllergies('p1'))
          .thenAnswer((_) async => [newAllergy]);

      final result = await container
          .read(allergiesProvider('p1').notifier)
          .addAllergy(newAllergy);

      expect(result, isA<Success<void, Exception>>());
      expect(container.read(allergiesProvider('p1')).value!.length, 1);
      expect(container.read(allergiesProvider('p1')).value!.first.name, 'Dust');
      verify(() => mockAllergiesRepository.addAllergy(any())).called(1);
      verify(() => mockNotificationService.syncEmergencyNotification('p1')).called(1);
    });

    test('deleteAllergy should call repository, update state and sync notification', () async {
      final initialAllergies = [
        Allergy(id: 'a1', profileId: 'p1', name: 'Peanuts', note: 'Severe'),
      ];
      when(() => mockAllergiesRepository.getAllergies('p1'))
          .thenAnswer((_) async => initialAllergies);
      when(() => mockAllergiesRepository.deleteAllergy(any()))
          .thenAnswer((_) async => {});

      await container.read(allergiesProvider('p1').future);

      // Update mock for the refresh call
      when(() => mockAllergiesRepository.getAllergies('p1'))
          .thenAnswer((_) async => []);

      final result = await container
          .read(allergiesProvider('p1').notifier)
          .deleteAllergy('a1');

      expect(result, isA<Success<void, Exception>>());
      expect(container.read(allergiesProvider('p1')).value!.length, 0);
      verify(() => mockAllergiesRepository.deleteAllergy('a1')).called(1);
      verify(() => mockNotificationService.syncEmergencyNotification('p1')).called(1);
    });
  });

  group('MedicationAdherenceProvider Tests', () {
    test('should calculate 100% adherence and 0 streak when there are no expected medications', () async {
      when(() => mockMedicationsRepository.loadMedications('p1'))
          .thenAnswer((_) async => []);
      when(() => mockMedicationsRepository.loadAllLogs('p1', limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => []);

      await container.read(medicationsProvider('p1').future);
      await container.read(allMedicationLogsProvider('p1').future);

      final adherence = await container.read(medicationAdherenceProvider('p1').future);

      expect(adherence.adherenceRate, 1.0);
      expect(adherence.streakDays, 0);
      expect(adherence.dailyAdherence.length, 7);
    });

    test('should calculate correct adherence rate and streak for 7-day period', () async {
      final today = DateTime.now();
      final scheduledMed = Medication(
        id: 'm1',
        profileId: 'p1',
        name: 'Aspirin',
        dosage: '100mg',
        timeOfDay: const TimeOfDay(hour: 8, minute: 0),
        isActive: true,
        isAsNeeded: false,
        daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
        timesOfDay: const [TimeOfDay(hour: 8, minute: 0)],
      );

      final logs = [
        MedicationLog(
          id: 'l1',
          medicationId: 'm1',
          timestamp: today,
          isTaken: true,
        ),
        MedicationLog(
          id: 'l2',
          medicationId: 'm1',
          timestamp: today.subtract(const Duration(days: 1)),
          isTaken: true,
        ),
        MedicationLog(
          id: 'l3',
          medicationId: 'm1',
          timestamp: today.subtract(const Duration(days: 2)),
          isTaken: true,
        ),
        MedicationLog(
          id: 'l4',
          medicationId: 'm1',
          timestamp: today.subtract(const Duration(days: 4)),
          isTaken: true,
        ),
        MedicationLog(
          id: 'l5',
          medicationId: 'm1',
          timestamp: today.subtract(const Duration(days: 5)),
          isTaken: true,
        ),
      ];

      when(() => mockMedicationsRepository.loadMedications('p1'))
          .thenAnswer((_) async => [scheduledMed]);
      when(() => mockMedicationsRepository.loadAllLogs('p1', limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => logs);

      await container.read(medicationsProvider('p1').future);
      await container.read(allMedicationLogsProvider('p1').future);

      final adherence = await container.read(medicationAdherenceProvider('p1').future);

      expect(adherence.adherenceRate, 5 / 7);
      expect(adherence.streakDays, 3);
    });

    test('should exclude PRN (as-needed) medications from expected dose calculations', () async {
      final prnMed = Medication(
        id: 'm2',
        profileId: 'p1',
        name: 'Insulin',
        dosage: '5 Units',
        timeOfDay: const TimeOfDay(hour: 12, minute: 0),
        isActive: true,
        isAsNeeded: true,
        notificationEnabled: true,
      );

      final scheduledMed = Medication(
        id: 'm1',
        profileId: 'p1',
        name: 'Aspirin',
        dosage: '100mg',
        timeOfDay: const TimeOfDay(hour: 8, minute: 0),
        isActive: true,
        isAsNeeded: false,
        daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
        timesOfDay: const [TimeOfDay(hour: 8, minute: 0)],
      );

      final logs = [
        MedicationLog(
          id: 'l1',
          medicationId: 'm2',
          timestamp: DateTime.now(),
          isTaken: true,
        ),
      ];

      when(() => mockMedicationsRepository.loadMedications('p1'))
          .thenAnswer((_) async => [prnMed, scheduledMed]);
      when(() => mockMedicationsRepository.loadAllLogs('p1', limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => logs);

      await container.read(medicationsProvider('p1').future);
      await container.read(allMedicationLogsProvider('p1').future);

      final adherence = await container.read(medicationAdherenceProvider('p1').future);

      expect(adherence.adherenceRate, 0.0);
      expect(adherence.streakDays, 0);
    });
  });

  group('PrimaryProfileIdProvider Tests', () {
    test('initial state should fetch primary profile id from repository', () async {
      when(() => mockEmergencyRepository.getPrimaryProfileId())
          .thenAnswer((_) async => 'p1');

      final value = await container.read(primaryProfileIdProvider.future);
      expect(value, 'p1');
      verify(() => mockEmergencyRepository.getPrimaryProfileId()).called(1);
    });

    test('setPrimaryProfileId should update repository and state', () async {
      when(() => mockEmergencyRepository.getPrimaryProfileId())
          .thenAnswer((_) async => null);
      when(() => mockEmergencyRepository.setPrimaryProfileId(any()))
          .thenAnswer((_) async => {});

      final initial = await container.read(primaryProfileIdProvider.future);
      expect(initial, isNull);

      final notifier = container.read(primaryProfileIdProvider.notifier);
      await notifier.setPrimaryProfileId('p2');

      verify(() => mockEmergencyRepository.setPrimaryProfileId('p2')).called(1);
      expect(container.read(primaryProfileIdProvider).value, 'p2');
    });
  });
}
