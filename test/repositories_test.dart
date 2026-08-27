import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/repositories/allergies_repository.dart';
import 'package:open_cloud_health/repositories/history_repository.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/repositories/emergency_repository.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/insurance_policy.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/repositories/insurance_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    // Pre-populate standard test profiles p1 and p2 so foreign keys are satisfied
    final profRepo = ProfilesRepository(db);
    await profRepo.addProfile(Profile(
      id: 'p1',
      name: 'Primary',
      middleNames: '',
      surname: 'User',
      dateOfBirth: DateTime(1990, 1, 1),
      gender: Gender.male,
      bloodType: 'O+',
      isOrganDonor: true,
    ));
    await profRepo.addProfile(Profile(
      id: 'p2',
      name: 'Secondary',
      middleNames: '',
      surname: 'User',
      dateOfBirth: DateTime(1992, 2, 2),
      gender: Gender.female,
      bloodType: 'A+',
      isOrganDonor: false,
    ));
  });

  tearDown(() async {
    await db.close();
  });

  group('ProfilesRepository Tests', () {
    test('addProfile should insert profile into database', () async {
      final repository = ProfilesRepository(db);
      final profile = Profile(
        id: '1',
        name: 'John',
        middleNames: '',
        surname: 'Doe',
        dateOfBirth: DateTime(1990),
        gender: Gender.male,
        bloodType: 'O+',
        isOrganDonor: true,
      );

      await repository.addProfile(profile);

      final result = await repository.fetchProfiles();
      expect(result.any((p) => p.name == 'John'), isTrue);
    });

    test('watchProfiles emits reactive stream updates', () async {
      final repository = ProfilesRepository(db);
      final profile = Profile(
        id: '1',
        name: 'John',
        middleNames: '',
        surname: 'Doe',
        dateOfBirth: DateTime(1990),
        gender: Gender.male,
        bloodType: 'O+',
        isOrganDonor: true,
      );

      final stream = repository.watchProfiles();
      final expectation = expectLater(
        stream,
        emitsThrough(predicate<List<Profile>>((list) => list.any((p) => p.name == 'John'))),
      );

      await repository.addProfile(profile);
      await expectation;
    });
  });

  group('HistoryRepository Tests', () {
    test('addEvent should insert event into database', () async {
      final repository = HistoryRepository(db);
      final event = HistoryEvent(
        id: 'e1',
        profileId: 'p1',
        title: 'Checkup',
        description: 'Routine',
        date: DateTime(2023, 10, 10),
      );

      await repository.addEvent(event);

      final result = await repository.fetchEvents('p1');
      expect(result.length, 1);
      expect(result.first.title, 'Checkup');
    });

    test('fetchEvents should return events for specific profile', () async {
      final repository = HistoryRepository(db);
      await repository.addEvent(HistoryEvent(
        id: 'e1',
        profileId: 'p1',
        title: 'Event 1',
        description: '',
        date: DateTime(2023, 10, 10, 10, 0),
      ));
      await repository.addEvent(HistoryEvent(
        id: 'e2',
        profileId: 'p2',
        title: 'Event 2',
        description: '',
        date: DateTime(2023, 10, 11, 10, 0),
      ));

      final events = await repository.fetchEvents('p1');
      expect(events.length, 1);
      expect(events.first.id, 'e1');
    });
  });

  group('AllergiesRepository Tests', () {
    test('addAllergy should insert allergy into database', () async {
      final repository = AllergiesRepository(db);
      final allergy = Allergy(
        id: 'a1',
        profileId: 'p1',
        name: 'Peanuts',
        note: 'Severe',
      );

      await repository.addAllergy(allergy);

      final result = await repository.getAllergies('p1');
      expect(result.length, 1);
      expect(result.first.name, 'Peanuts');
    });

    test('setAllergies should replace existing allergies atomically', () async {
      final repository = AllergiesRepository(db);
      await repository.addAllergy(Allergy(id: 'old-1', profileId: 'p1', name: 'Dust', note: 'Mild'));

      final newAllergies = [
        Allergy(id: 'new-1', profileId: 'p1', name: 'Penicillin', note: 'Hives'),
        Allergy(id: 'new-2', profileId: 'p1', name: 'Latex', note: 'Rash'),
      ];

      await repository.setAllergies('p1', newAllergies);

      final result = await repository.getAllergies('p1');
      expect(result.length, 2);
      expect(result.map((a) => a.name), containsAll(['Penicillin', 'Latex']));
      expect(result.any((a) => a.name == 'Dust'), isFalse);
    });
  });

  group('EmergencyRepository Tests', () {
    test('addEmergencyContact should insert contact into database', () async {
      final repository = EmergencyRepository(db);
      final contact = EmergencyContact(
        id: 'c1',
        profileId: 'p1',
        name: 'Jane Doe',
        relationship: 'Spouse',
        phoneNumber: '123-456-7890',
      );

      await repository.addEmergencyContact(contact);

      final result = await repository.getEmergencyContacts('p1');
      expect(result.length, 1);
      expect(result.first.id, 'c1');
      expect(result.first.name, 'Jane Doe');
    });

    test('getEmergencyContacts should return contacts for specific profile', () async {
      final repository = EmergencyRepository(db);
      await repository.addEmergencyContact(EmergencyContact(
        id: 'c1',
        profileId: 'p1',
        name: 'Jane Doe',
        relationship: 'Spouse',
        phoneNumber: '123-456-7890',
      ));
      await repository.addEmergencyContact(EmergencyContact(
        id: 'c2',
        profileId: 'p2',
        name: 'John Smith',
        relationship: 'Friend',
        phoneNumber: '987-654-3210',
      ));

      final contacts = await repository.getEmergencyContacts('p1');
      expect(contacts.length, 1);
      expect(contacts.first.id, 'c1');
      expect(contacts.first.name, 'Jane Doe');
    });

    test('deleteEmergencyContact should remove contact from database', () async {
      final repository = EmergencyRepository(db);
      await repository.addEmergencyContact(EmergencyContact(
        id: 'c1',
        profileId: 'p1',
        name: 'Jane Doe',
        relationship: 'Spouse',
        phoneNumber: '123-456-7890',
      ));

      await repository.deleteEmergencyContact('c1');

      final result = await repository.getEmergencyContacts('p1');
      expect(result.isEmpty, true);
    });

    test('getLockScreenSetting should return default values if no row exists', () async {
      final repository = EmergencyRepository(db);
      final setting = await repository.getLockScreenSetting('p1');
      expect(setting.profileId, 'p1');
      expect(setting.showName, true);
      expect(setting.isEnabled, false);
    });

    test('saveLockScreenSetting and getLockScreenSetting should save and retrieve setting', () async {
      final repository = EmergencyRepository(db);
      final setting = LockScreenSetting(
        profileId: 'p1',
        showName: false,
        isEnabled: true,
      );

      await repository.saveLockScreenSetting(setting);

      final retrieved = await repository.getLockScreenSetting('p1');
      expect(retrieved.profileId, 'p1');
      expect(retrieved.showName, false);
      expect(retrieved.showAge, true);
      expect(retrieved.isEnabled, true);
    });

    test('getPrimaryProfileId and setPrimaryProfileId should save and retrieve primary profile id', () async {
      final repository = EmergencyRepository(db);
      
      expect(await repository.getPrimaryProfileId(), isNull);
      
      await repository.setPrimaryProfileId('p1');
      expect(await repository.getPrimaryProfileId(), 'p1');
      
      await repository.setPrimaryProfileId(null);
      expect(await repository.getPrimaryProfileId(), isNull);
    });
  });

  group('InsuranceRepository Tests', () {
    test('saveInsurance, getInsurance, watchInsurance, and deleteInsurance', () async {
      final repository = InsuranceRepository(db);

      // Initially null
      expect(await repository.getInsurance('p1'), isNull);

      final policy = InsurancePolicy(
        profileId: 'p1',
        provider: 'Blue Cross Blue Shield',
        planName: 'Gold Preferred',
        policyNumber: 'BCBS-998877',
        groupNumber: 'GRP-100',
        subscriberName: 'Primary User',
        memberId: '01',
        emergencyPhone: '1-800-555-1234',
        frontCardImagePath: '/path/to/front.jpg',
        backCardImagePath: '/path/to/back.jpg',
        notes: 'In-network copay \$20',
      );

      // Save policy
      await repository.saveInsurance(policy);

      // Retrieve policy
      final retrieved = await repository.getInsurance('p1');
      expect(retrieved, isNotNull);
      expect(retrieved!.provider, 'Blue Cross Blue Shield');
      expect(retrieved.planName, 'Gold Preferred');
      expect(retrieved.policyNumber, 'BCBS-998877');
      expect(retrieved.emergencyPhone, '1-800-555-1234');
      expect(retrieved.notes, 'In-network copay \$20');

      // Update policy
      final updatedPolicy = retrieved.copyWith(planName: 'Platinum PPO');
      await repository.saveInsurance(updatedPolicy);
      final updated = await repository.getInsurance('p1');
      expect(updated!.planName, 'Platinum PPO');

      // Delete policy
      await repository.deleteInsurance(retrieved.id);
      expect(await repository.getInsurance('p1'), isNull);
    });
  });
}
