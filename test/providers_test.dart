import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/allergies_provider.dart';
import 'package:open_cloud_health/providers/history_provider.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/repositories/allergies_repository.dart';
import 'package:open_cloud_health/repositories/history_repository.dart';
import 'package:open_cloud_health/repositories/medications_repository.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/services/notification_service.dart';

class MockProfilesRepository extends Mock implements ProfilesRepository {}

class FakeProfile extends Fake implements Profile {}

class MockHistoryRepository extends Mock implements HistoryRepository {}

class FakeHistoryEvent extends Fake implements HistoryEvent {}

class MockMedicationsRepository extends Mock implements MedicationsRepository {}

class FakeMedication extends Fake implements Medication {}

class MockNotificationService extends Mock implements NotificationService {}

class MockAllergiesRepository extends Mock implements AllergiesRepository {}

class FakeAllergy extends Fake implements Allergy {}

void main() {
  late MockProfilesRepository mockProfilesRepository;
  late MockHistoryRepository mockHistoryRepository;
  late MockMedicationsRepository mockMedicationsRepository;
  late MockNotificationService mockNotificationService;
  late MockAllergiesRepository mockAllergiesRepository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeProfile());
    registerFallbackValue(FakeHistoryEvent());
    registerFallbackValue(FakeMedication());
    registerFallbackValue(FakeAllergy());
    registerFallbackValue(const TimeOfDay(hour: 0, minute: 0));
  });

  setUp(() {
    mockProfilesRepository = MockProfilesRepository();
    mockHistoryRepository = MockHistoryRepository();
    mockMedicationsRepository = MockMedicationsRepository();
    mockNotificationService = MockNotificationService();
    mockAllergiesRepository = MockAllergiesRepository();

    when(() => mockNotificationService.cancelNotification(any()))
        .thenAnswer((_) async => {});
    when(() => mockNotificationService.scheduleDailyNotification(
            any(), any(), any(), any()))
        .thenAnswer((_) async => {});

    container = ProviderContainer(
      overrides: [
        profilesRepositoryProvider.overrideWithValue(mockProfilesRepository),
        historyRepositoryProvider.overrideWithValue(mockHistoryRepository),
        medicationsRepositoryProvider
            .overrideWithValue(mockMedicationsRepository),
        notificationServiceProvider.overrideWithValue(mockNotificationService),
        allergiesRepositoryProvider.overrideWithValue(mockAllergiesRepository),
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
      final newId = await notifier.addProfile(
          'Jane', '', 'Doe', DateTime(1995), Gender.female, 'A-', false);

      expect(newId, isNotEmpty);
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

      await container
          .read(profilesProvider.notifier)
          .updateProfile(updatedProfile);

      verify(() => mockProfilesRepository.updateProfile(any())).called(1);
      expect(container.read(profilesProvider).value!.first.name, 'John Updated');
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

      await container.read(historyProvider('p1').future);

      final notifier = container.read(historyProvider('p1').notifier);
      final newId = await notifier.addEvent(
          'p1', 'Cough', 'Dry cough', DateTime(2023, 10, 11), 0);

      expect(newId, isNotEmpty);
      expect(container.read(historyProvider('p1')).value!.length, 1);
      expect(container.read(historyProvider('p1')).value!.first.title, 'Cough');
      verify(() => mockHistoryRepository.addEvent(any())).called(1);
    });

    test('deleteEvent should call repository and update state', () async {
      when(() => mockHistoryRepository.fetchEvents('p1'))
          .thenAnswer((_) async => List.from(tEvents));
      when(() => mockHistoryRepository.deleteEvent('e1'))
          .thenAnswer((_) async => {});

      await container.read(historyProvider('p1').future);

      await container.read(historyProvider('p1').notifier).deleteEvent('e1');

      expect(container.read(historyProvider('p1')).value!.isEmpty, true);
      verify(() => mockHistoryRepository.deleteEvent('e1')).called(1);
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

      await container
          .read(medicationsProvider('p1').notifier)
          .toggleIsActive(tMeds[0]);

      expect(container.read(medicationsProvider('p1')).value!.first.isActive,
          false);
      verify(() => mockMedicationsRepository.toggleIsActive('m1', false))
          .called(1);
      verify(() => mockNotificationService.cancelNotification(any())).called(1);
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

      final newAllergy = Allergy(profileId: 'p1', name: 'Dust', note: '');
      await container
          .read(allergiesProvider('p1').notifier)
          .addAllergy(newAllergy);

      expect(container.read(allergiesProvider('p1')).value!.length, 1);
      expect(container.read(allergiesProvider('p1')).value!.first.name, 'Dust');
      verify(() => mockAllergiesRepository.addAllergy(any())).called(1);
    });
  });
}
