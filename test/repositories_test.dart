import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/repositories/allergies_repository.dart';
import 'package:open_cloud_health/repositories/history_repository.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/repositories/emergency_repository.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late Database db;
  late MockDatabaseHelper mockDbHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath, version: 1,
        onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE profiles(
          id TEXT PRIMARY KEY, 
          name TEXT, 
          middleNames TEXT,
          surname TEXT, 
          dateOfBirth TEXT,
          bloodType TEXT, 
          gender TEXT,
          isOrganDonor TEXT,
          trackOvulation TEXT,
          isArchived TEXT DEFAULT 'false',
          archivedAt TEXT,
          chronicConditions TEXT DEFAULT ''
        )''');
      await db.execute('''
        CREATE TABLE history(
          id TEXT PRIMARY KEY,
          profileId TEXT,
          title TEXT,
          description TEXT,
          date TEXT,
          eventType TEXT DEFAULT 'other',
          hasTime TEXT DEFAULT 'true',
          provider TEXT,
          facility TEXT
        )''');
      await db.execute('''
        CREATE TABLE attachments(
          id TEXT PRIMARY KEY,
          historyId TEXT,
          filename TEXT,
          uploadDate TEXT,
          byteLength INTEGER
        )''');
      await db.execute('''
        CREATE TABLE allergy(
          id TEXT PRIMARY KEY,
          profileId TEXT,
          name TEXT,
          note TEXT
        )''');
      await db.execute('''
        CREATE TABLE emergency_contacts(
          id TEXT PRIMARY KEY,
          profileId TEXT,
          name TEXT,
          relationship TEXT,
          phoneNumber TEXT
        )''');
      await db.execute('''
        CREATE TABLE lock_screen_settings(
          profileId TEXT PRIMARY KEY,
          showName TEXT DEFAULT 'true',
          showAge TEXT DEFAULT 'true',
          showBloodType TEXT DEFAULT 'true',
          showOrganDonor TEXT DEFAULT 'true',
          showChronicConditions TEXT DEFAULT 'true',
          showAllergies TEXT DEFAULT 'true',
          showMedications TEXT DEFAULT 'true',
          showContacts TEXT DEFAULT 'true',
          isEnabled TEXT DEFAULT 'false'
        )''');
      await db.execute('''
        CREATE TABLE settings(
          key TEXT PRIMARY KEY,
          value TEXT
        )''');
    });

    mockDbHelper = MockDatabaseHelper();
    when(() => mockDbHelper.getDatabase()).thenAnswer((_) async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ProfilesRepository Tests', () {
    test('addProfile should insert profile into database', () async {
      final repository = ProfilesRepository(mockDbHelper);
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

      final result = await db.query('profiles');
      expect(result.length, 1);
      expect(result.first['name'], 'John');
    });
  });

  group('HistoryRepository Tests', () {
    test('addEvent should insert event into database', () async {
      final repository = HistoryRepository(mockDbHelper);
      final event = HistoryEvent(
        id: 'e1',
        profileId: 'p1',
        title: 'Checkup',
        description: 'Routine',
        date: DateTime(2023, 10, 10),
      );

      await repository.addEvent(event);

      final result = await db.query('history');
      expect(result.length, 1);
      expect(result.first['title'], 'Checkup');
    });

    test('fetchEvents should return events for specific profile', () async {
      final repository = HistoryRepository(mockDbHelper);
      await db.insert('history', {
        'id': 'e1',
        'profileId': 'p1',
        'title': 'Event 1',
        'description': '',
        'date': '2023-10-10 10:00:00'
      });
      await db.insert('history', {
        'id': 'e2',
        'profileId': 'p2',
        'title': 'Event 2',
        'description': '',
        'date': '2023-10-11 10:00:00'
      });

      final events = await repository.fetchEvents('p1');
      expect(events.length, 1);
      expect(events.first.id, 'e1');
    });
  });

  group('AllergiesRepository Tests', () {
    test('addAllergy should insert allergy into database', () async {
      final repository = AllergiesRepository(mockDbHelper);
      final allergy = Allergy(
        id: 'a1',
        profileId: 'p1',
        name: 'Peanuts',
        note: 'Severe',
      );

      await repository.addAllergy(allergy);

      final result = await db.query('allergy');
      expect(result.length, 1);
      expect(result.first['name'], 'Peanuts');
    });
  });

  group('EmergencyRepository Tests', () {
    test('addEmergencyContact should insert contact into database', () async {
      final repository = EmergencyRepository(mockDbHelper);
      final contact = EmergencyContact(
        id: 'c1',
        profileId: 'p1',
        name: 'Jane Doe',
        relationship: 'Spouse',
        phoneNumber: '123-456-7890',
      );

      await repository.addEmergencyContact(contact);

      final result = await db.query('emergency_contacts');
      expect(result.length, 1);
      expect(result.first['id'], 'c1');
      expect(result.first['name'], 'Jane Doe');
    });

    test('getEmergencyContacts should return contacts for specific profile', () async {
      final repository = EmergencyRepository(mockDbHelper);
      await db.insert('emergency_contacts', {
        'id': 'c1',
        'profileId': 'p1',
        'name': 'Jane Doe',
        'relationship': 'Spouse',
        'phoneNumber': '123-456-7890',
      });
      await db.insert('emergency_contacts', {
        'id': 'c2',
        'profileId': 'p2',
        'name': 'John Smith',
        'relationship': 'Friend',
        'phoneNumber': '987-654-3210',
      });

      final contacts = await repository.getEmergencyContacts('p1');
      expect(contacts.length, 1);
      expect(contacts.first.id, 'c1');
      expect(contacts.first.name, 'Jane Doe');
    });

    test('deleteEmergencyContact should remove contact from database', () async {
      final repository = EmergencyRepository(mockDbHelper);
      await db.insert('emergency_contacts', {
        'id': 'c1',
        'profileId': 'p1',
        'name': 'Jane Doe',
        'relationship': 'Spouse',
        'phoneNumber': '123-456-7890',
      });

      await repository.deleteEmergencyContact('c1');

      final result = await db.query('emergency_contacts');
      expect(result.isEmpty, true);
    });

    test('getLockScreenSetting should return default values if no row exists', () async {
      final repository = EmergencyRepository(mockDbHelper);
      final setting = await repository.getLockScreenSetting('p1');
      expect(setting.profileId, 'p1');
      expect(setting.showName, true);
      expect(setting.isEnabled, false);
    });

    test('saveLockScreenSetting and getLockScreenSetting should save and retrieve setting', () async {
      final repository = EmergencyRepository(mockDbHelper);
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
      final repository = EmergencyRepository(mockDbHelper);
      
      String? primaryId;
      when(() => mockDbHelper.getPrimaryProfileId()).thenAnswer((_) async => primaryId);
      when(() => mockDbHelper.setPrimaryProfileId(any())).thenAnswer((invocation) async {
        primaryId = invocation.positionalArguments[0] as String?;
      });

      expect(await repository.getPrimaryProfileId(), isNull);
      
      await repository.setPrimaryProfileId('p1');
      expect(await repository.getPrimaryProfileId(), 'p1');
      
      await repository.setPrimaryProfileId(null);
      expect(await repository.getPrimaryProfileId(), isNull);
    });
  });
}
