import 'dart:io';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/services/backup_encryption_service.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late File sourceDbFile;
  late Directory avatarsDir;
  late Directory attachmentsDir;
  late Directory restoredDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('drift_backup_test_');
    sourceDbFile = File(path.join(tempDir.path, 'source_opencloudhealth.db'));
    avatarsDir = Directory(path.join(tempDir.path, 'avatars'))..createSync();
    attachmentsDir = Directory(path.join(tempDir.path, 'attachments'))..createSync();
    restoredDir = Directory(path.join(tempDir.path, 'restored'))..createSync();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Drift Backup & Restore Encryption Integration Pipeline', () {
    test('Full multi-table relational backup, AES-256 encryption, decryption, and restore roundtrip', () async {
      const password = 'SuperSecurePatientBackupKey2026!';

      // 1. Initialize and populate the source Drift database
      final sourceDb = AppDatabase(NativeDatabase(sourceDbFile));

      final dob = DateTime(1920, 7, 25);
      final eventDate = DateTime(1952, 5, 1, 10, 0);
      final uploadDate = DateTime(1952, 5, 1);
      final logTime = DateTime(1952, 5, 1, 9, 0);
      final checkupDate = DateTime(1952, 1, 15, 10, 0);
      final cycleStart = DateTime(1952, 4, 20);
      final cycleEnd = DateTime(1952, 4, 25);
      final vitalDate = DateTime(1952, 5, 1, 8, 0);

      // Populate Profiles
      await sourceDb.into(sourceDb.profiles).insert(
            ProfileEntry(
              id: 'prof-restore-1',
              name: 'Rosalind',
              middleNames: 'Elsie',
              surname: 'Franklin',
              dateOfBirth: dob,
              bloodType: 'O+',
              gender: 'female',
              isOrganDonor: true,
              trackOvulation: true,
              isArchived: false,
              archivedAt: null,
              chronicConditions: 'Ovarian Cancer,Asthma',
            ),
          );

      // Populate History
      await sourceDb.into(sourceDb.history).insert(
            HistoryEntry(
              id: 'hist-restore-1',
              profileId: 'prof-restore-1',
              title: 'X-ray Crystallography Discovery',
              description: 'Photo 51 experimental session',
              date: eventDate,
              eventType: 'other',
              hasTime: true,
              provider: 'King\'s College London',
              facility: 'Biophysics Lab',
            ),
          );

      // Populate Attachments
      await sourceDb.into(sourceDb.attachments).insert(
            AttachmentEntry(
              id: 'att-restore-1',
              historyId: 'hist-restore-1',
              filename: 'photo_51.tiff',
              uploadDate: uploadDate,
              byteLength: 1048576,
            ),
          );

      // Populate Allergy
      await sourceDb.into(sourceDb.allergy).insert(
            const AllergyEntry(
              id: 'all-restore-1',
              profileId: 'prof-restore-1',
              name: 'Radiation',
              note: 'High sensitivity',
            ),
          );

      // Populate Medications
      await sourceDb.into(sourceDb.medications).insert(
            MedicationsCompanion.insert(
              id: 'med-restore-1',
              profileId: 'prof-restore-1',
              name: 'Pain Management Analgesic',
              dosage: '50 mg',
              type: const drift.Value('Tablet'),
              notificationEnabled: const drift.Value(true),
              alarmEnabled: const drift.Value(false),
              timeOfDay: '09:00',
              isActive: const drift.Value(true),
              daysOfWeek: const drift.Value('[1,2,3,4,5,6,7]'),
              timesOfDay: const drift.Value('["09:00","21:00"]'),
              isAsNeeded: const drift.Value(false),
              trackInventory: const drift.Value(true),
              stockQuantity: const drift.Value(45.0),
              lowStockThreshold: const drift.Value(10.0),
            ),
          );

      // Populate Medication Logs
      await sourceDb.into(sourceDb.medicationLogs).insert(
            MedicationLogEntry(
              id: 'mlog-restore-1',
              medicationId: 'med-restore-1',
              timestamp: logTime,
              isTaken: true,
              dosage: '50 mg',
            ),
          );

      // Populate Checkups
      await sourceDb.into(sourceDb.checkups).insert(
            CheckupsCompanion.insert(
              id: 'chk-restore-1',
              profileId: 'prof-restore-1',
              name: 'Annual Biophysics Health Screening',
              frequencyInMonths: 6,
              iconName: const drift.Value('shield'),
              isCustomInterval: const drift.Value(false),
              isActive: const drift.Value(true),
            ),
          );

      // Populate Checkup Logs
      await sourceDb.into(sourceDb.checkupLogs).insert(
            CheckupLogEntry(
              id: 'chkl-restore-1',
              checkupId: 'chk-restore-1',
              dateCompleted: checkupDate,
              location: 'London Medical Center',
              doctorName: 'Dr. Physician',
              notes: 'Follow up in 6 months.',
            ),
          );

      // Populate Period Cycles & Logs
      await sourceDb.into(sourceDb.periodCycles).insert(
            PeriodCycleEntry(
              id: 'cyc-restore-1',
              profileId: 'prof-restore-1',
              startDate: cycleStart,
              endDate: cycleEnd,
            ),
          );
      await sourceDb.into(sourceDb.periodLogs).insert(
            PeriodLogEntry(
              id: 'plog-restore-1',
              cycleId: 'cyc-restore-1',
              date: cycleStart,
              flowLevel: 'medium',
              moods: 'fatigue',
              physicalSymptoms: 'cramps',
            ),
          );

      // Populate Vital Logs
      await sourceDb.into(sourceDb.vitalLogs).insert(
            VitalLogEntry(
              id: 'vital-restore-1',
              profileId: 'prof-restore-1',
              type: 'bloodPressure',
              date: vitalDate,
              value1: 115.0,
              value2: 75.0,
              unit: 'mmHg',
              note: 'Normal baseline',
            ),
          );

      // Populate Settings
      await sourceDb.setLocalAuthEnabled(true);
      await sourceDb.setSecurityBannerDismissed(true);
      await sourceDb.setPrimaryProfileId('prof-restore-1');

      // Populate Emergency Contacts & Lock Screen Settings
      await sourceDb.into(sourceDb.emergencyContacts).insert(
            const EmergencyContactEntry(
              id: 'emg-restore-1',
              profileId: 'prof-restore-1',
              name: 'Ellis Franklin',
              relationship: 'Father',
              phoneNumber: '+44-20-7946-0912',
            ),
          );
      await sourceDb.into(sourceDb.lockScreenSettings).insert(
            const LockScreenSettingsCompanion(
              profileId: drift.Value('prof-restore-1'),
              showName: drift.Value(true),
              showContacts: drift.Value(true),
              showAllergies: drift.Value(true),
              showMedications: drift.Value(true),
              showChronicConditions: drift.Value(true),
              isEnabled: drift.Value(true),
            ),
          );

      // Write physical file assets
      final avatarFile = File(path.join(avatarsDir.path, 'prof-restore-1.jpg'));
      await avatarFile.writeAsString('BINARY_AVATAR_IMAGE_DATA_1952');

      final attachmentFile = File(path.join(attachmentsDir.path, 'photo_51.tiff'));
      await attachmentFile.writeAsString('BINARY_CRYSTALLOGRAPHY_TIFF_DATA_1952');

      // Flush and close the source database before archiving
      await sourceDb.close();

      // 2. Package database and file assets into a ZIP archive
      final archive = Archive();

      final dbBytes = await sourceDbFile.readAsBytes();
      archive.addFile(ArchiveFile('app_database.sqlite', dbBytes.length, dbBytes));

      final avatarBytes = await avatarFile.readAsBytes();
      archive.addFile(ArchiveFile('avatars/prof-restore-1.jpg', avatarBytes.length, avatarBytes));

      final attachBytes = await attachmentFile.readAsBytes();
      archive.addFile(ArchiveFile('attachments/photo_51.tiff', attachBytes.length, attachBytes));

      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);
      expect(zipBytes, isNotNull);

      // 3. Encrypt ZIP bundle using BackupEncryptionService (AES-256)
      final encryptedBundle = BackupEncryptionService.encryptBundle(zipBytes!, password);
      expect(encryptedBundle.length, greaterThan(zipBytes.length));

      // 4. Verify rejection when decrypting with incorrect password
      expect(
        () => BackupEncryptionService.decryptBundle(encryptedBundle, 'WrongPassword123!'),
        throwsA(isA<FormatException>()),
      );

      // 5. Decrypt ZIP bundle with the correct password
      final decryptedBytes = BackupEncryptionService.decryptBundle(encryptedBundle, password);
      expect(decryptedBytes, equals(zipBytes));

      // 6. Extract archive into restored directory
      final zipDecoder = ZipDecoder();
      final restoredArchive = zipDecoder.decodeBytes(decryptedBytes);

      for (final file in restoredArchive) {
        final filePath = path.join(restoredDir.path, file.name);
        if (file.isFile) {
          final outFile = File(filePath);
          outFile.parent.createSync(recursive: true);
          outFile.writeAsBytesSync(file.content as List<int>);
        }
      }

      // 7. Verify physical files were restored
      final restoredAvatar = File(path.join(restoredDir.path, 'avatars', 'prof-restore-1.jpg'));
      expect(restoredAvatar.existsSync(), isTrue);
      expect(await restoredAvatar.readAsString(), 'BINARY_AVATAR_IMAGE_DATA_1952');

      final restoredAttach = File(path.join(restoredDir.path, 'attachments', 'photo_51.tiff'));
      expect(restoredAttach.existsSync(), isTrue);
      expect(await restoredAttach.readAsString(), 'BINARY_CRYSTALLOGRAPHY_TIFF_DATA_1952');

      // 8. Open restored SQLite database with a new AppDatabase instance and verify all 14 tables
      final restoredDbFile = File(path.join(restoredDir.path, 'app_database.sqlite'));
      expect(restoredDbFile.existsSync(), isTrue);

      final restoredDb = AppDatabase(NativeDatabase(restoredDbFile));

      // Assert Profiles
      final profiles = await restoredDb.select(restoredDb.profiles).get();
      expect(profiles.length, 1);
      expect(profiles.first.name, 'Rosalind');
      expect(profiles.first.surname, 'Franklin');
      expect(profiles.first.chronicConditions, 'Ovarian Cancer,Asthma');
      expect(profiles.first.isOrganDonor, true);

      // Assert History & Attachments
      final history = await restoredDb.select(restoredDb.history).get();
      expect(history.length, 1);
      expect(history.first.title, 'X-ray Crystallography Discovery');

      final attachments = await restoredDb.select(restoredDb.attachments).get();
      expect(attachments.length, 1);
      expect(attachments.first.filename, 'photo_51.tiff');

      // Assert Allergy
      final allergies = await restoredDb.select(restoredDb.allergy).get();
      expect(allergies.length, 1);
      expect(allergies.first.name, 'Radiation');

      // Assert Medications & Medication Logs
      final medications = await restoredDb.select(restoredDb.medications).get();
      expect(medications.length, 1);
      expect(medications.first.name, 'Pain Management Analgesic');
      expect(medications.first.stockQuantity, 45.0);
      expect(medications.first.notificationEnabled, true);

      final medLogs = await restoredDb.select(restoredDb.medicationLogs).get();
      expect(medLogs.length, 1);
      expect(medLogs.first.dosage, '50 mg');
      expect(medLogs.first.isTaken, true);

      // Assert Checkups & Checkup Logs
      final checkups = await restoredDb.select(restoredDb.checkups).get();
      expect(checkups.length, 1);
      expect(checkups.first.name, 'Annual Biophysics Health Screening');
      expect(checkups.first.isActive, true);

      final checkupLogs = await restoredDb.select(restoredDb.checkupLogs).get();
      expect(checkupLogs.length, 1);
      expect(checkupLogs.first.notes, 'Follow up in 6 months.');

      // Assert Period Cycles & Logs
      final cycles = await restoredDb.select(restoredDb.periodCycles).get();
      expect(cycles.length, 1);
      expect(cycles.first.startDate, cycleStart);
      expect(cycles.first.endDate, cycleEnd);

      final periodLogs = await restoredDb.select(restoredDb.periodLogs).get();
      expect(periodLogs.length, 1);
      expect(periodLogs.first.moods, 'fatigue');
      expect(periodLogs.first.date, cycleStart);

      // Assert Vitals
      final vitals = await restoredDb.select(restoredDb.vitalLogs).get();
      expect(vitals.length, 1);
      expect(vitals.first.value1, 115.0);
      expect(vitals.first.value2, 75.0);
      expect(vitals.first.date, vitalDate);

      // Assert Settings
      expect(await restoredDb.isLocalAuthEnabled(), isTrue);
      expect(await restoredDb.isSecurityBannerDismissed(), isTrue);
      expect(await restoredDb.getPrimaryProfileId(), 'prof-restore-1');

      // Assert Emergency Contacts & Lock Screen Settings
      final contacts = await restoredDb.select(restoredDb.emergencyContacts).get();
      expect(contacts.length, 1);
      expect(contacts.first.name, 'Ellis Franklin');

      final lockSettings = await (restoredDb.select(restoredDb.lockScreenSettings)
            ..where((tbl) => tbl.profileId.equals('prof-restore-1')))
          .getSingle();
      expect(lockSettings.isEnabled, true);
      expect(lockSettings.showChronicConditions, true);

      await restoredDb.close();
    });
  });
}
