import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/checkup.dart';
import 'package:open_cloud_health/models/checkup_log.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/providers/medical_pdf_provider.dart';

void main() {
  group('MedicalPdfExportOptions & Date Filters Tests', () {
    test('PdfDateRangeFilter cutoff dates calculated accurately', () {
      expect(PdfDateRangeFilter.allTime.cutoffDate, isNull);
      
      final now = DateTime.now();
      final cutoff30 = PdfDateRangeFilter.last30Days.cutoffDate!;
      expect(now.difference(cutoff30).inDays, inInclusiveRange(29, 31));

      final cutoff90 = PdfDateRangeFilter.last90Days.cutoffDate!;
      expect(now.difference(cutoff90).inDays, inInclusiveRange(89, 91));

      final cutoff180 = PdfDateRangeFilter.last6Months.cutoffDate!;
      expect(now.difference(cutoff180).inDays, inInclusiveRange(179, 181));

      final cutoff365 = PdfDateRangeFilter.lastYear.cutoffDate!;
      expect(now.difference(cutoff365).inDays, inInclusiveRange(364, 366));
    });

    test('MedicalPdfExportOptions copyWith updates attributes', () {
      const defaultOptions = MedicalPdfExportOptions();
      expect(defaultOptions.includeDemographics, isTrue);
      expect(defaultOptions.includeAllergies, isTrue);
      expect(defaultOptions.includeMedications, isTrue);
      expect(defaultOptions.includeVitals, isTrue);
      expect(defaultOptions.includeHistory, isTrue);
      expect(defaultOptions.includeCheckups, isTrue);
      expect(defaultOptions.includeFertility, isTrue);
      expect(defaultOptions.includeEmergencyContacts, isTrue);
      expect(defaultOptions.includeDoctorNotesSection, isTrue);
      expect(defaultOptions.dateRange, PdfDateRangeFilter.allTime);

      final modified = defaultOptions.copyWith(
        includeAllergies: false,
        includeMedications: false,
        dateRange: PdfDateRangeFilter.last90Days,
      );

      expect(modified.includeAllergies, isFalse);
      expect(modified.includeMedications, isFalse);
      expect(modified.includeVitals, isTrue);
      expect(modified.dateRange, PdfDateRangeFilter.last90Days);
    });

    test('PdfExportParams equality and hashing test', () {
      const params1 = PdfExportParams(
        profileId: 'p-1',
        options: MedicalPdfExportOptions(includeAllergies: true),
      );
      const params2 = PdfExportParams(
        profileId: 'p-1',
        options: MedicalPdfExportOptions(includeAllergies: true),
      );
      const params3 = PdfExportParams(
        profileId: 'p-2',
        options: MedicalPdfExportOptions(includeAllergies: true),
      );

      expect(params1, equals(params2));
      expect(params1.hashCode, equals(params2.hashCode));
      expect(params1, isNot(equals(params3)));
    });
  });

  group('MedicalPdfService Document Generation Tests', () {
    late ProviderContainer container;
    late MedicalPdfService pdfService;

    setUp(() {
      container = ProviderContainer();
      pdfService = container.read(medicalPdfServiceProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('buildPdfDocument compiles complete clinical report into valid PDF bytes', () async {
      final profile = Profile(
        id: 'prof-test-1',
        name: 'Sarah',
        middleNames: 'Jane',
        surname: 'Connor',
        dateOfBirth: DateTime(1985, 5, 20),
        gender: Gender.female,
        bloodType: 'A+',
        isOrganDonor: true,
        chronicConditions: ['Hypertension', 'Asthma'],
      );

      final allergies = [
        Allergy(profileId: profile.id, name: 'Penicillin', note: 'Severe anaphylaxis risk'),
        Allergy(profileId: profile.id, name: 'Latex', note: 'Contact dermatitis'),
      ];

      final emergencyContacts = [
        EmergencyContact(
          profileId: profile.id,
          name: 'John Connor',
          relationship: 'Son',
          phoneNumber: '+1-555-0199',
        ),
      ];

      final medications = [
        Medication(
          profileId: profile.id,
          name: 'Lisinopril',
          dosage: '10mg',
          type: 'Tablet',
          timesOfDay: [const TimeOfDay(hour: 8, minute: 0)],
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isActive: true,
        ),
        Medication(
          profileId: profile.id,
          name: 'Albuterol Inhaler',
          dosage: '90mcg (2 puffs)',
          type: 'Inhaler',
          isAsNeeded: true,
          isActive: true,
        ),
      ];

      final vitals = [
        VitalLog(
          profileId: profile.id,
          type: VitalType.bloodPressure,
          date: DateTime.now().subtract(const Duration(days: 2)),
          value1: 120,
          value2: 80,
          unit: 'mmHg',
          note: 'Resting sitting position',
        ),
        VitalLog(
          profileId: profile.id,
          type: VitalType.bloodSugar,
          date: DateTime.now().subtract(const Duration(days: 1)),
          value1: 94,
          unit: 'mg/dL',
          note: 'Fasting',
        ),
        VitalLog(
          profileId: profile.id,
          type: VitalType.weight,
          date: DateTime.now().subtract(const Duration(days: 5)),
          value1: 68.5,
          unit: 'kg',
        ),
      ];

      final historyEvents = [
        HistoryEvent(
          profileId: profile.id,
          title: 'Annual Cardiology Follow-up',
          description: 'ECG normal sinus rhythm. Continued current Lisinopril dose.',
          date: DateTime.now().subtract(const Duration(days: 14)),
          eventType: EventType.specialistConsultation,
          provider: 'Marcus Brody',
          facility: 'Metro General Hospital',
          attachmentCount: 2,
        ),
      ];

      final checkups = [
        Checkup(
          profileId: profile.id,
          name: 'Comprehensive Lipid Panel',
          frequencyInMonths: 12,
        ),
      ];

      final checkupLogs = {
        checkups.first.id: [
          CheckupLog(
            checkupId: checkups.first.id,
            dateCompleted: DateTime.now().subtract(const Duration(days: 60)),
            doctorName: 'Dr. Marcus Brody',
            location: 'Metro Labs',
            notes: 'Total cholesterol 175 mg/dL, HDL 55 mg/dL, LDL 98 mg/dL',
          ),
        ],
      };

      final periodCycles = [
        PeriodCycle(
          profileId: profile.id,
          startDate: DateTime.now().subtract(const Duration(days: 35)),
          endDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ];

      final periodLogs = {
        periodCycles.first.id: [
          PeriodLog(
            cycleId: periodCycles.first.id,
            date: DateTime.now().subtract(const Duration(days: 35)),
            flowLevel: FlowLevel.heavy,
            physicalSymptoms: [PhysicalSymptom.cramps],
            moods: [Mood.anxious],
          ),
        ],
      };

      final bundle = MedicalPdfDataBundle(
        profile: profile,
        allergies: allergies,
        emergencyContacts: emergencyContacts,
        medications: medications,
        vitals: vitals,
        historyEvents: historyEvents,
        checkups: checkups,
        checkupLogsByCheckupId: checkupLogs,
        periodCycles: periodCycles,
        periodLogsByCycleId: periodLogs,
        options: const MedicalPdfExportOptions(),
      );

      final pdfDoc = pdfService.buildPdfDocument(bundle);
      final pdfBytes = await pdfDoc.save();

      expect(pdfBytes, isNotEmpty);
      // Valid PDF magic header check: %PDF-1.
      final magicHeader = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(magicHeader, equals('%PDF-'));
    });

    test('buildPdfDocument handles empty medical data gracefully without errors', () async {
      final emptyMaleProfile = Profile(
        id: 'prof-empty-male',
        name: 'John',
        middleNames: '',
        surname: 'Doe',
        dateOfBirth: DateTime(2000, 1, 1),
        gender: Gender.male,
        bloodType: 'O-',
        isOrganDonor: false,
      );

      final bundle = MedicalPdfDataBundle(
        profile: emptyMaleProfile,
        allergies: [],
        emergencyContacts: [],
        medications: [],
        vitals: [],
        historyEvents: [],
        checkups: [],
        options: const MedicalPdfExportOptions(),
      );

      final pdfDoc = pdfService.buildPdfDocument(bundle);
      final pdfBytes = await pdfDoc.save();

      expect(pdfBytes, isNotEmpty);
      final magicHeader = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(magicHeader, equals('%PDF-'));
    });

    test('buildPdfDocument respects disabled section options', () async {
      final profile = Profile(
        id: 'prof-options-test',
        name: 'Alex',
        middleNames: '',
        surname: 'Smith',
        dateOfBirth: DateTime(1990, 8, 12),
        gender: Gender.male,
        bloodType: 'B+',
        isOrganDonor: true,
      );

      final bundle = MedicalPdfDataBundle(
        profile: profile,
        allergies: [Allergy(profileId: profile.id, name: 'Dust', note: 'Mild')],
        medications: [
          Medication(
            profileId: profile.id,
            name: 'Vitamin D3',
            dosage: '2000 IU',
            isActive: true,
          ),
        ],
        options: const MedicalPdfExportOptions(
          includeDemographics: false,
          includeAllergies: false,
          includeChronicConditions: false,
          includeMedications: false,
          includeVitals: false,
          includeHistory: false,
          includeCheckups: false,
          includeFertility: false,
          includeEmergencyContacts: false,
          includeDoctorNotesSection: false,
        ),
      );

      final pdfDoc = pdfService.buildPdfDocument(bundle);
      final pdfBytes = await pdfDoc.save();

      expect(pdfBytes, isNotEmpty);
      final magicHeader = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(magicHeader, equals('%PDF-'));
    });
  });
}
