import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/profile_share_config.dart';
import 'package:open_cloud_health/models/profile_share_models.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/checkup.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/services/backup_encryption_service.dart';

void main() {
  group('Profile Sharing Models & Cryptography Tests', () {
    final sampleProfile = Profile(
      id: 'test-profile-123',
      name: 'Alice',
      middleNames: 'Marie',
      surname: 'Smith',
      dateOfBirth: DateTime(1990, 5, 15),
      gender: Gender.female,
      bloodType: 'O+',
      isOrganDonor: true,
      trackOvulation: true,
      chronicConditions: ['Asthma', 'Hypertension'],
    );

    test('ShareLinkPayload parses URL format with fragment key', () {
      const url = 'https://opencloudhealth.app/share?fileId=1AbC_xyz123#key=secretPassKey123';
      final payload = ShareLinkPayload.parse(url);

      expect(payload, isNotNull);
      expect(payload!.fileId, '1AbC_xyz123');
      expect(payload.encryptionKey, 'secretPassKey123');
      expect(payload.toUniversalUriString(), contains('fileId=1AbC_xyz123'));
    });

    test('ShareLinkPayload parses JSON format', () {
      final jsonStr = jsonEncode({
        'fileId': 'drive-file-456',
        'key': 'recoverySecretKey',
      });

      final payload = ShareLinkPayload.parse(jsonStr);
      expect(payload, isNotNull);
      expect(payload!.fileId, 'drive-file-456');
      expect(payload.encryptionKey, 'recoverySecretKey');
    });

    test('ShareModuleOptions serialization and deserialization', () {
      const options = ShareModuleOptions(
        includeMedications: true,
        includeVitals: false,
        includeAllergies: true,
        includeHistory: false,
      );

      final map = options.toJson();
      final recovered = ShareModuleOptions.fromJson(map);

      expect(recovered.includeMedications, isTrue);
      expect(recovered.includeVitals, isFalse);
      expect(recovered.includeAllergies, isTrue);
      expect(recovered.includeHistory, isFalse);
    });

    test('SharedProfileBundle packages and unpacks full health records accurately', () {
      final bundle = SharedProfileBundle(
        profile: sampleProfile,
        sharedBy: 'Alice Smith',
        sharedAt: DateTime.now(),
        moduleOptions: const ShareModuleOptions(),
        allergies: [
          Allergy(id: 'a1', profileId: 'test-profile-123', name: 'Penicillin', note: 'Rash'),
        ],
        medications: [
          MedicationShareBundle(
            medication: Medication(
              id: 'm1',
              profileId: 'test-profile-123',
              name: 'Ventolin',
              dosage: '2 puffs',
              stockQuantity: 10,
              trackInventory: true,
            ),
            logs: [],
          ),
        ],
        vitals: [
          VitalLog(
            id: 'v1',
            profileId: 'test-profile-123',
            type: VitalType.bloodPressure,
            date: DateTime(2026, 1, 1),
            value1: 120,
            value2: 80,
            unit: 'mmHg',
          ),
        ],
        checkups: [
          CheckupShareBundle(
            checkup: Checkup(
              id: 'c1',
              profileId: 'test-profile-123',
              name: 'Dental',
              frequencyInMonths: 6,
            ),
            logs: [],
          ),
        ],
        historyEvents: [
          HistoryEvent(
            id: 'h1',
            profileId: 'test-profile-123',
            title: 'Annual Checkup',
            description: 'Routine general visit',
            date: DateTime(2025, 12, 1),
          ),
        ],
        emergencyContacts: [
          EmergencyContact(
            id: 'e1',
            profileId: 'test-profile-123',
            name: 'Bob Smith',
            relationship: 'Spouse',
            phoneNumber: '+123456789',
          ),
        ],
        periodCycles: [],
      );

      final jsonMap = bundle.toJson();
      final reconstituted = SharedProfileBundle.fromJson(jsonMap);

      expect(reconstituted.profile.name, 'Alice');
      expect(reconstituted.profile.surname, 'Smith');
      expect(reconstituted.allergies.length, 1);
      expect(reconstituted.allergies.first.name, 'Penicillin');
      expect(reconstituted.profile.chronicConditions, contains('Asthma'));
      expect(reconstituted.medications.length, 1);
      expect(reconstituted.medications.first.medication.name, 'Ventolin');
      expect(reconstituted.vitals.length, 1);
      expect(reconstituted.vitals.first.value1, 120);
      expect(reconstituted.checkups.length, 1);
      expect(reconstituted.historyEvents.length, 1);
      expect(reconstituted.emergencyContacts.length, 1);
      expect(reconstituted.emergencyContacts.first.name, 'Bob Smith');
      expect(reconstituted.sharedBy, 'Alice Smith');
    });

    test('AES-256 E2EE encrypts and decrypts bundle payload with recovery key', () {
      final recoveryKey = BackupEncryptionService.generateRecoveryKey();

      final bundle = SharedProfileBundle(
        profile: sampleProfile,
        sharedBy: 'Alice Smith',
        sharedAt: DateTime.now(),
        moduleOptions: const ShareModuleOptions(),
        allergies: [],
        medications: [],
        vitals: [],
        checkups: [],
        historyEvents: [],
        emergencyContacts: [],
        periodCycles: [],
      );

      final rawBytes = utf8.encode(jsonEncode(bundle.toJson()));
      final encryptedBytes = BackupEncryptionService.encryptBundle(rawBytes, recoveryKey);

      // Verify data is encrypted and ciphertext is not plaintext
      expect(encryptedBytes, isNot(equals(rawBytes)));

      // Decrypt
      final decryptedBytes = BackupEncryptionService.decryptBundle(encryptedBytes, recoveryKey);
      final decryptedString = utf8.decode(decryptedBytes);
      final parsedJson = jsonDecode(decryptedString) as Map<String, dynamic>;
      final decryptedBundle = SharedProfileBundle.fromJson(parsedJson);

      expect(decryptedBundle.profile.name, 'Alice');
      expect(decryptedBundle.profile.chronicConditions, contains('Asthma'));
      expect(decryptedBundle.sharedBy, 'Alice Smith');
    });

    test('ActiveShareConfig serializes and deserializes accurately', () {
      final config = ActiveShareConfig(
        profileId: 'p-100',
        driveFileId: 'drive-file-abc',
        encryptionKey: 'sec-key-123',
        options: const ShareModuleOptions(includeMedications: true, includeVitals: false),
        createdAt: DateTime(2026, 1, 1, 10, 0),
        lastSyncedAt: DateTime(2026, 1, 2, 12, 0),
        sharedBy: 'Doctor Bob',
        profileName: 'Alice Smith',
      );

      final jsonStr = config.encodeToJsonString();
      final recovered = ActiveShareConfig.decodeFromJsonString(jsonStr);

      expect(recovered, isNotNull);
      expect(recovered!.profileId, 'p-100');
      expect(recovered.driveFileId, 'drive-file-abc');
      expect(recovered.encryptionKey, 'sec-key-123');
      expect(recovered.options.includeMedications, isTrue);
      expect(recovered.options.includeVitals, isFalse);
      expect(recovered.sharedBy, 'Doctor Bob');
      expect(recovered.profileName, 'Alice Smith');
    });

    test('ShareSyncFrequency isDue scheduling logic', () {
      // Manual frequency is never due
      expect(ShareSyncFrequency.manual.isDue(lastSync: null), isFalse);
      expect(ShareSyncFrequency.manual.isDue(lastSync: DateTime.now().subtract(const Duration(days: 10))), isFalse);

      // Daily frequency during idle hours (3 AM)
      final idleTime = DateTime(2026, 8, 20, 3, 0);
      final nonIdleTime = DateTime(2026, 8, 20, 14, 0);

      // Never synced before: due during idle hours
      expect(ShareSyncFrequency.daily.isDue(lastSync: null, now: idleTime), isTrue);
      expect(ShareSyncFrequency.daily.isDue(lastSync: null, now: nonIdleTime), isFalse);
      expect(ShareSyncFrequency.daily.isDue(lastSync: null, now: nonIdleTime, enforceIdleHours: false), isTrue);

      // Last synced 12 hours ago: not due yet
      final twelveHoursAgo = DateTime(2026, 8, 19, 15, 0);
      expect(ShareSyncFrequency.daily.isDue(lastSync: twelveHoursAgo, now: idleTime), isFalse);

      // Last synced 25 hours ago: due during idle window
      final yesterday = DateTime(2026, 8, 19, 2, 0);
      expect(ShareSyncFrequency.daily.isDue(lastSync: yesterday, now: idleTime), isTrue);
      expect(ShareSyncFrequency.daily.isDue(lastSync: yesterday, now: nonIdleTime), isFalse);

      // Overdue by 3 days (> 2x daily interval): runs immediately even outside idle hours
      final threeDaysAgo = DateTime(2026, 8, 17, 10, 0);
      expect(ShareSyncFrequency.daily.isDue(lastSync: threeDaysAgo, now: nonIdleTime), isTrue);

      // Weekly frequency
      expect(ShareSyncFrequency.weekly.isDue(lastSync: yesterday, now: idleTime), isFalse);
      final eightDaysAgo = DateTime(2026, 8, 12, 2, 0);
      expect(ShareSyncFrequency.weekly.isDue(lastSync: eightDaysAgo, now: idleTime), isTrue);
    });
  });
}

