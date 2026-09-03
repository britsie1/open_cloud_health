import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/checkup.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/insurance_policy.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/profile_share_models.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/repositories/shared_profiles_repository.dart';
import 'package:open_cloud_health/services/file_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late FileService fileService;
  late SharedProfilesRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('shared_profiles_test_');
    fileService = FileService(baseDirectory: tempDir);
    repository = SharedProfilesRepository(fileService);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SharedProfilesRepository Tests', () {
    test('Empty repository returns empty lists and nulls for non-existent profiles', () async {
      expect(await repository.getSharedProfiles(), isEmpty);
      expect(await repository.isSharedProfile('none-existent'), isFalse);
      expect(await repository.getSharedProfileBundle('none-existent'), isNull);
      expect(await repository.getSharedProfileMeta('none-existent'), isNull);
      expect(await repository.getSharedProfileImagePath('none-existent'), isEmpty);
      expect(await repository.getAllergies('none-existent'), isEmpty);
      expect(await repository.getMedications('none-existent'), isEmpty);
      expect(await repository.getVitals('none-existent'), isEmpty);
      expect(await repository.getHistoryEvents('none-existent'), isEmpty);
      expect(await repository.getEmergencyContacts('none-existent'), isEmpty);
      expect(await repository.getInsurance('none-existent'), isNull);
      expect(await repository.getCheckups('none-existent'), isEmpty);
      expect(await repository.getPeriodCycles('none-existent'), isEmpty);
      expect(await repository.getPeriodLogs('none-existent'), isEmpty);
    });

    test('saveSharedProfileBundle stores bundle, metadata, and cached profile photo', () async {
      final sampleProfile = Profile(
        id: 'shared-p1',
        name: 'Shared',
        middleNames: 'User',
        surname: 'One',
        dateOfBirth: DateTime(1992, 3, 15),
        gender: Gender.female,
        bloodType: 'O+',
        isOrganDonor: true,
        chronicConditions: const ['Hypertension'],
      );

      final fakeImageBytes = [137, 80, 78, 71, 13, 10, 26, 10]; // PNG header dummy bytes
      final base64Image = base64Encode(fakeImageBytes);

      final bundle = SharedProfileBundle(
        profile: sampleProfile,
        sharedBy: 'Dr. Jane Smith',
        sharedAt: DateTime(2026, 3, 1, 10, 0),
        profileImageBase64: base64Image,
        moduleOptions: const ShareModuleOptions(),
        allergies: [
          Allergy(id: 'alg-1', profileId: 'shared-p1', name: 'Penicillin', note: 'Severe'),
        ],
        medications: [
          MedicationShareBundle(
            medication: Medication(
              id: 'med-1',
              profileId: 'shared-p1',
              name: 'Lisinopril',
              dosage: '10mg',
              timeOfDay: const TimeOfDay(hour: 8, minute: 0),
            ),
            logs: [],
          ),
        ],
        vitals: [
          VitalLog(
            id: 'vit-1',
            profileId: 'shared-p1',
            type: VitalType.bloodPressure,
            date: DateTime(2026, 3, 1, 9, 0),
            value1: 120,
            value2: 80,
            unit: 'mmHg',
          ),
        ],
        historyEvents: [
          HistoryEvent(
            id: 'hist-1',
            profileId: 'shared-p1',
            title: 'Cardiology Review',
            description: 'Stable vitals',
            date: DateTime(2026, 2, 28),
          ),
        ],
        emergencyContacts: [
          EmergencyContact(
            id: 'emg-1',
            profileId: 'shared-p1',
            name: 'Emergency Contact',
            relationship: 'Spouse',
            phoneNumber: '+1-555-0100',
          ),
        ],
        insurance: InsurancePolicy(
          id: 'ins-1',
          profileId: 'shared-p1',
          provider: 'Blue Cross',
          planName: 'Gold Advantage',
          policyNumber: 'BC-123456',
        ),
        checkups: [
          CheckupShareBundle(
            checkup: Checkup(
              id: 'chk-1',
              profileId: 'shared-p1',
              name: 'Annual Wellness Exam',
              frequencyInMonths: 12,
            ),
            logs: [],
          ),
        ],
        periodCycles: [
          PeriodCycleShareBundle(
            cycle: PeriodCycle(
              id: 'pc-1',
              profileId: 'shared-p1',
              startDate: DateTime(2026, 2, 1),
              endDate: DateTime(2026, 2, 5),
            ),
            logs: [
              PeriodLog(
                id: 'pl-1',
                cycleId: 'pc-1',
                date: DateTime(2026, 2, 1),
                flowLevel: FlowLevel.medium,
              ),
            ],
          ),
        ],
      );

      // Save shared profile
      await repository.saveSharedProfileBundle(
        bundle,
        fileId: 'drive-file-abc-123',
        encryptionKey: 'secret-share-key-456',
      );

      // 1. Verify existence
      expect(await repository.isSharedProfile('shared-p1'), isTrue);

      // 2. Verify getSharedProfiles()
      final sharedProfiles = await repository.getSharedProfiles();
      expect(sharedProfiles.length, 1);
      final fetched = sharedProfiles.first;
      expect(fetched.id, 'shared-p1');
      expect(fetched.name, 'Shared');
      expect(fetched.isShared, isTrue);
      expect(fetched.isReadOnly, isTrue);
      expect(fetched.sharedBy, 'Dr. Jane Smith');
      expect(fetched.shareFileId, 'drive-file-abc-123');
      expect(fetched.shareEncryptionKey, 'secret-share-key-456');

      // 3. Verify getSharedProfileBundle()
      final fetchedBundle = await repository.getSharedProfileBundle('shared-p1');
      expect(fetchedBundle, isNotNull);
      expect(fetchedBundle!.sharedBy, 'Dr. Jane Smith');
      expect(fetchedBundle.allergies.length, 1);
      expect(fetchedBundle.allergies.first.name, 'Penicillin');
      expect(fetchedBundle.medications.length, 1);
      expect(fetchedBundle.medications.first.medication.name, 'Lisinopril');
      expect(fetchedBundle.vitals.length, 1);
      expect(fetchedBundle.historyEvents.length, 1);
      expect(fetchedBundle.emergencyContacts.length, 1);
      expect(fetchedBundle.insurance?.provider, 'Blue Cross');
      expect(fetchedBundle.checkups.length, 1);
      expect(fetchedBundle.periodCycles.length, 1);

      // 4. Verify getSharedProfileMeta()
      final meta = await repository.getSharedProfileMeta('shared-p1');
      expect(meta, isNotNull);
      expect(meta!.profileId, 'shared-p1');
      expect(meta.fileId, 'drive-file-abc-123');
      expect(meta.encryptionKey, 'secret-share-key-456');
      expect(meta.sharedBy, 'Dr. Jane Smith');

      // 5. Verify getSharedProfileImagePath()
      final photoPath = await repository.getSharedProfileImagePath('shared-p1');
      expect(photoPath, isNotEmpty);
      expect(await File(photoPath).exists(), isTrue);
      expect(await File(photoPath).readAsBytes(), equals(fakeImageBytes));

      // 6. Verify granular queries
      final allergies = await repository.getAllergies('shared-p1');
      expect(allergies.length, 1);
      expect(allergies.first.name, 'Penicillin');

      final medications = await repository.getMedications('shared-p1');
      expect(medications.length, 1);
      expect(medications.first.name, 'Lisinopril');

      final vitals = await repository.getVitals('shared-p1');
      expect(vitals.length, 1);
      expect(vitals.first.value1, 120);

      final history = await repository.getHistoryEvents('shared-p1');
      expect(history.length, 1);
      expect(history.first.title, 'Cardiology Review');

      final contacts = await repository.getEmergencyContacts('shared-p1');
      expect(contacts.length, 1);
      expect(contacts.first.name, 'Emergency Contact');

      final insurance = await repository.getInsurance('shared-p1');
      expect(insurance, isNotNull);
      expect(insurance!.policyNumber, 'BC-123456');

      final checkups = await repository.getCheckups('shared-p1');
      expect(checkups.length, 1);
      expect(checkups.first.name, 'Annual Wellness Exam');

      final cycles = await repository.getPeriodCycles('shared-p1');
      expect(cycles.length, 1);
      expect(cycles.first.id, 'pc-1');

      final logs = await repository.getPeriodLogs('pc-1');
      expect(logs.length, 1);
      expect(logs.first.id, 'pl-1');
      expect(logs.first.flowLevel, FlowLevel.medium);

      // 7. Remove shared profile completely
      await repository.removeSharedProfile('shared-p1');

      expect(await repository.isSharedProfile('shared-p1'), isFalse);
      expect(await repository.getSharedProfiles(), isEmpty);
      expect(await repository.getSharedProfileBundle('shared-p1'), isNull);
      expect(await repository.getSharedProfileMeta('shared-p1'), isNull);
      expect(await repository.getSharedProfileImagePath('shared-p1'), isEmpty);
      expect(await File(photoPath).exists(), isFalse);
    });
  });
}
