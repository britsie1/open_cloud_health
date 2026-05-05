import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/attachment.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';

import 'package:open_cloud_health/models/allergy.dart';

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
  });

  group('MedicationLog Model Tests', () {
    test('MedicationLog defaults to isTaken=true', () {
      final log = MedicationLog(medicationId: 'm1', timestamp: DateTime.now());
      expect(log.isTaken, true);
      expect(log.id, isNotEmpty);
    });
  });
}
