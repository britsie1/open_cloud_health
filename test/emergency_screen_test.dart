import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/repositories/allergies_repository.dart';
import 'package:open_cloud_health/repositories/emergency_repository.dart';
import 'package:open_cloud_health/repositories/medications_repository.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/repositories/shared_profiles_repository.dart';
import 'package:open_cloud_health/screens/emergency_settings.dart';
import 'package:open_cloud_health/services/notification_service.dart';

class MockProfilesRepository extends Mock implements ProfilesRepository {}
class MockSharedProfilesRepository extends Mock implements SharedProfilesRepository {}
class MockEmergencyRepository extends Mock implements EmergencyRepository {}
class MockAllergiesRepository extends Mock implements AllergiesRepository {}
class MockMedicationsRepository extends Mock implements MedicationsRepository {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('EmergencySettingsScreen renders settings, contacts, and no redundant Preview Emergency Card button', (tester) async {
    final mockProfilesRepo = MockProfilesRepository();
    final mockSharedRepo = MockSharedProfilesRepository();
    final mockEmergencyRepo = MockEmergencyRepository();
    final mockAllergiesRepo = MockAllergiesRepository();
    final mockMedsRepo = MockMedicationsRepository();
    final mockNotifService = MockNotificationService();

    final sampleProfile = Profile(
      id: 'p1',
      name: 'John',
      middleNames: 'William',
      surname: 'Doe',
      dateOfBirth: DateTime(1985, 5, 20),
      gender: Gender.male,
      bloodType: 'O+',
      isOrganDonor: true,
      chronicConditions: const ['Asthma', 'Hypertension'],
    );

    final sampleSettings = LockScreenSetting(
      profileId: 'p1',
      showName: true,
      showAge: true,
      showBloodType: true,
      showOrganDonor: true,
      showChronicConditions: true,
      showAllergies: true,
      showMedications: true,
      showContacts: true,
      showInsurance: true,
      isEnabled: true,
    );

    when(() => mockProfilesRepo.watchProfiles(includeArchived: any(named: 'includeArchived')))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockProfilesRepo.fetchProfiles(includeArchived: any(named: 'includeArchived')))
        .thenAnswer((_) async => [sampleProfile]);
    when(() => mockSharedRepo.getSharedProfiles())
        .thenAnswer((_) async => []);
    when(() => mockEmergencyRepo.watchLockScreenSetting('p1'))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockEmergencyRepo.getLockScreenSetting('p1'))
        .thenAnswer((_) async => sampleSettings);
    when(() => mockEmergencyRepo.watchEmergencyContacts('p1'))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockEmergencyRepo.getEmergencyContacts('p1'))
        .thenAnswer((_) async => [
              EmergencyContact(
                id: 'c1',
                profileId: 'p1',
                name: 'Jane Doe',
                relationship: 'Spouse',
                phoneNumber: '+1-555-123-4567',
              ),
            ]);
    when(() => mockEmergencyRepo.getPrimaryProfileId())
        .thenAnswer((_) async => 'p1');
    when(() => mockAllergiesRepo.watchAllergies('p1'))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAllergiesRepo.getAllergies('p1'))
        .thenAnswer((_) async => [
              Allergy(id: 'a1', profileId: 'p1', name: 'Penicillin', note: 'Severe shock'),
            ]);
    when(() => mockMedsRepo.watchMedications('p1'))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockMedsRepo.loadMedications('p1'))
        .thenAnswer((_) async => [
              Medication(
                id: 'm1',
                profileId: 'p1',
                name: 'Albuterol Inhaler',
                dosage: '90mcg 2 puffs',
                type: 'Inhaler',
                isActive: true,
              ),
            ]);
    when(() => mockNotifService.isEmergencyChannelEnabled())
        .thenAnswer((_) async => true);
    when(() => mockNotifService.isBatteryOptimizationDisabled())
        .thenAnswer((_) async => true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profilesRepositoryProvider.overrideWithValue(mockProfilesRepo),
          sharedProfilesRepositoryProvider.overrideWithValue(mockSharedRepo),
          emergencyRepositoryProvider.overrideWithValue(mockEmergencyRepo),
          allergiesRepositoryProvider.overrideWithValue(mockAllergiesRepo),
          medicationsRepositoryProvider.overrideWithValue(mockMedsRepo),
          notificationServiceProvider.overrideWithValue(mockNotifService),
        ],
        child: const MaterialApp(
          home: EmergencySettingsScreen(profileId: 'p1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Emergency ID'), findsOneWidget);
    expect(find.text('Lock Screen Medical ID'), findsOneWidget);
    expect(find.text('Preview Emergency Card'), findsNothing);
    expect(find.text('CHOOSE WHAT TO DISPLAY'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
  });
}
