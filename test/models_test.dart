import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/attachment.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/utils/icon_utils.dart';
import 'package:healthicons_flutter/healthicons_flutter.dart';

void main() {
  group('Allergy Model Tests', () {
    test('Allergy generates a unique ID if none provided', () {
      final allergy = Allergy(profileId: 'p1', name: 'Peanuts', note: 'Severe');
      expect(allergy.id, isNotEmpty);
      expect(allergy.id, isA<String>());
    });

    test('Allergy uses provided ID', () {
      final allergy = Allergy(
          id: 'custom-id', profileId: 'p1', name: 'Dust', note: 'Mild');
      expect(allergy.id, 'custom-id');
    });
  });

  group('Profile Model Tests', () {
    test('Profile formattedDate returns correct format', () {
      final date = DateTime(1990, 5, 20);
      final profile = Profile(
        name: 'John',
        middleNames: 'Doe',
        surname: 'Smith',
        dateOfBirth: date,
        gender: Gender.male,
        bloodType: 'O+',
        isOrganDonor: true,
      );

      expect(profile.formattedDate, '1990-05-20');
    });

    test('Profile mapping parsing verification (like from DB)', () {
      final row = {
        'id': 'test-id-123',
        'name': 'Jane',
        'middleNames': '',
        'surname': 'Doe',
        'dateOfBirth': '1985-11-05',
        'bloodType': 'AB-',
        'gender': 'female',
        'isOrganDonor': 'false'
      };

      final profile = Profile(
        id: row['id'] as String,
        name: row['name'] as String,
        middleNames: row['middleNames'] as String,
        surname: row['surname'] as String,
        dateOfBirth: DateTime.parse(row['dateOfBirth'] as String),
        bloodType: row['bloodType'] as String,
        gender: Gender.values.byName(row['gender'] as String),
        isOrganDonor: bool.parse(row['isOrganDonor'] as String)
      );

      expect(profile.name, 'Jane');
      expect(profile.dateOfBirth.year, 1985);
      expect(profile.gender, Gender.female);
      expect(profile.isOrganDonor, false);
    });

    test('Profile age calculation works correctly', () {
      final dob = DateTime.now().subtract(const Duration(days: 365 * 30 + 10)); // ~30 years ago
      final profile = Profile(
        name: 'John',
        middleNames: '',
        surname: 'Doe',
        dateOfBirth: dob,
        gender: Gender.male,
        bloodType: 'O+',
        isOrganDonor: true,
      );
      expect(profile.age, 30);
    });

    test('Profile default archiving state should be false/null', () {
      final profile = Profile(
        name: 'John',
        middleNames: '',
        surname: 'Doe',
        dateOfBirth: DateTime(1990),
        gender: Gender.male,
        bloodType: 'O+',
        isOrganDonor: true,
      );
      expect(profile.isArchived, false);
      expect(profile.archivedAt, isNull);
    });
  });

  group('HistoryEvent Model Tests', () {
    test('HistoryEvent formattedDate returns correct format with time', () {
      final date = DateTime(2023, 10, 15, 14, 30);
      final event = HistoryEvent(
        profileId: 'profile-1',
        title: 'Checkup',
        description: 'Annual physical',
        date: date,
      );

      expect(event.formattedDate, '2023-10-15 14:30');
    });
  });

  group('Attachment Model Tests', () {
    test('Attachment formattedDate returns correct format with time', () {
      final date = DateTime(2023, 10, 15, 9, 5);
      final attachment = Attachment(
        historyId: 'event-1',
        filename: 'report.pdf',
        uploadDate: date,
        byteLength: 500,
      );

      expect(attachment.formattedDate, '2023-10-15 09:05');
    });

    test('Attachment fileSize calculates correctly', () {
      // Bytes
      var att = Attachment(historyId: '1', filename: 'f', uploadDate: DateTime.now(), byteLength: 500);
      expect(att.fileSize, '500bytes');

      // Kilobytes
      att = Attachment(historyId: '1', filename: 'f', uploadDate: DateTime.now(), byteLength: 1500);
      expect(att.fileSize, '1.46kB');

      // Megabytes
      att = Attachment(historyId: '1', filename: 'f', uploadDate: DateTime.now(), byteLength: 1500000);
      expect(att.fileSize, '1.43MB');
    });

    test('Attachment fileIcon maps extensions to correct Icons', () {
      var pdfAtt = Attachment(historyId: '1', filename: 'document.pdf', uploadDate: DateTime.now(), byteLength: 10);
      expect(pdfAtt.fileIcon, Icons.picture_as_pdf);

      var imgAtt = Attachment(historyId: '1', filename: 'photo.jpg', uploadDate: DateTime.now(), byteLength: 10);
      expect(imgAtt.fileIcon, Icons.image_outlined);

      var pngAtt = Attachment(historyId: '1', filename: 'image.png', uploadDate: DateTime.now(), byteLength: 10);
      expect(pngAtt.fileIcon, Icons.image_outlined);

      var unknownAtt = Attachment(historyId: '1', filename: 'data.txt', uploadDate: DateTime.now(), byteLength: 10);
      expect(unknownAtt.fileIcon, Icons.insert_drive_file_outlined);
    });
  });

  group('Medication Model Tests', () {
    test('Medication timeFormatted returns correct HH:mm string', () {
      final med1 = Medication(
        profileId: 'p1',
        name: 'Aspirin',
        dosage: '100mg',
        timeOfDay: const TimeOfDay(hour: 8, minute: 5),
      );
      expect(med1.timeFormatted, '08:05');

      final med2 = Medication(
        profileId: 'p1',
        name: 'Aspirin',
        dosage: '100mg',
        timeOfDay: const TimeOfDay(hour: 14, minute: 30),
      );
      expect(med2.timeFormatted, '14:30');
    });

    test('Medication defaults daysOfWeek and timesOfDay when none provided', () {
      final med = Medication(
        profileId: 'p1',
        name: 'Aspirin',
        dosage: '100mg',
        timeOfDay: const TimeOfDay(hour: 8, minute: 5),
      );
      expect(med.daysOfWeek, [1, 2, 3, 4, 5, 6, 7]);
      expect(med.timesOfDay.length, 1);
      expect(med.timesOfDay.first, const TimeOfDay(hour: 8, minute: 5));
    });

    test('Medication supports custom daysOfWeek and timesOfDay', () {
      final med = Medication(
        profileId: 'p1',
        name: 'Aspirin',
        dosage: '100mg',
        daysOfWeek: const [1, 3, 5],
        timesOfDay: const [
          TimeOfDay(hour: 8, minute: 0),
          TimeOfDay(hour: 20, minute: 0),
        ],
      );
      expect(med.daysOfWeek, [1, 3, 5]);
      expect(med.timesOfDay, const [
        TimeOfDay(hour: 8, minute: 0),
        TimeOfDay(hour: 20, minute: 0),
      ]);
      expect(med.timeOfDay, const TimeOfDay(hour: 8, minute: 0));
    });

    test('Medication copyWith duplicates correctly', () {
      final med = Medication(
        profileId: 'p1',
        name: 'Aspirin',
        dosage: '100mg',
        daysOfWeek: const [2, 4],
        timesOfDay: const [TimeOfDay(hour: 9, minute: 0)],
      );

      final copied = med.copyWith(
        name: 'Ibuprofen',
        daysOfWeek: const [1, 2, 3],
      );

      expect(copied.name, 'Ibuprofen');
      expect(copied.dosage, '100mg');
      expect(copied.daysOfWeek, [1, 2, 3]);
      expect(copied.timesOfDay.first, const TimeOfDay(hour: 9, minute: 0));
    });

    test('Medication supports PRN and stock inventory tracking fields', () {
      final med = Medication(
        profileId: 'p1',
        name: 'Insulin',
        dosage: '5 Units',
        isAsNeeded: true,
        trackInventory: true,
        stockQuantity: 100.0,
        lowStockThreshold: 10.0,
      );

      expect(med.isAsNeeded, true);
      expect(med.trackInventory, true);
      expect(med.stockQuantity, 100.0);
      expect(med.lowStockThreshold, 10.0);

      final copied = med.copyWith(stockQuantity: 95.0);
      expect(copied.stockQuantity, 95.0);
      expect(copied.isAsNeeded, true);
    });

    test('Medication parseDosageQuantity parses numeric values correctly', () {
      expect(parseDosageQuantity('2.5ml'), 2.5);
      expect(parseDosageQuantity('5 ml'), 5.0);
      expect(parseDosageQuantity('0.5 tablet'), 0.5);
      expect(parseDosageQuantity('Take 1 pill'), 1.0);
      expect(parseDosageQuantity('No numbers here'), 1.0);
      expect(parseDosageQuantity(''), 1.0);
    });

    test('Medication formatStockQuantity and formatted getters format values cleanly', () {
      final med = Medication(
        profileId: 'p1',
        name: 'Insulin',
        dosage: '2.5ml',
        trackInventory: true,
        stockQuantity: 47.50,
        lowStockThreshold: 10.0,
      );

      expect(med.stockQuantityFormatted, '47.5');
      expect(med.lowStockThresholdFormatted, '10');

      final med2 = med.copyWith(stockQuantity: 50.0);
      expect(med2.stockQuantityFormatted, '50');

      final med3 = med.copyWith(stockQuantity: 47.25);
      expect(med3.stockQuantityFormatted, '47.25');
    });
  });

  group('MedicationLog Model Tests', () {
    test('MedicationLog defaults to isTaken=true', () {
      final log = MedicationLog(medicationId: 'm1', timestamp: DateTime.now());
      expect(log.isTaken, true);
      expect(log.id, isNotEmpty);
    });

    test('MedicationLog supports custom dosage amount', () {
      final log = MedicationLog(
        medicationId: 'm1',
        timestamp: DateTime.now(),
        dosage: '5 Units',
      );
      expect(log.dosage, '5 Units');
      
      final copied = log.copyWith(dosage: '10 Units');
      expect(copied.dosage, '10 Units');
    });
  });

  group('Icon Utilities Tests', () {
    test('getCheckupIconWidget returns stethoscope for physical checkups', () {
      final widget = getCheckupIconWidget('some_old_icon', checkupName: 'Annual Physical Exam');
      expect(widget, isA<StethoscopeOutline>());
    });

    test('getCheckupIconWidget returns blood pressure for BP screening', () {
      final widget = getCheckupIconWidget(null, checkupName: 'Blood Pressure Screening');
      expect(widget, isA<BloodPressureOutline>());
    });

    test('getCheckupIconWidget returns sugar cubes for diabetes screening', () {
      final widget = getCheckupIconWidget('diabetes');
      expect(widget, isA<SugarOutline>());

      final widget2 = getCheckupIconWidget(null, checkupName: 'Diabetes Screening');
      expect(widget2, isA<SugarOutline>());
    });
  });
}
