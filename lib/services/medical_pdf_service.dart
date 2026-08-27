import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/checkup.dart';
import 'package:open_cloud_health/models/checkup_log.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/insurance_policy.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/models/pdf_export_options.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/repositories/allergies_repository.dart';
import 'package:open_cloud_health/repositories/checkups_repository.dart';
import 'package:open_cloud_health/repositories/emergency_repository.dart';
import 'package:open_cloud_health/repositories/history_repository.dart';
import 'package:open_cloud_health/repositories/insurance_repository.dart';
import 'package:open_cloud_health/repositories/medications_repository.dart';
import 'package:open_cloud_health/repositories/period_repository.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/repositories/shared_profiles_repository.dart';
import 'package:open_cloud_health/repositories/vitals_repository.dart';
import 'package:open_cloud_health/services/file_service.dart';

class MedicalPdfDataBundle {
  final Profile profile;
  final Uint8List? profileImageBytes;
  final List<Allergy> allergies;
  final List<EmergencyContact> emergencyContacts;
  final InsurancePolicy? insurance;
  final List<Medication> medications;
  final List<MedicationLog> medicationLogs;
  final List<VitalLog> vitals;
  final List<HistoryEvent> historyEvents;
  final List<Checkup> checkups;
  final Map<String, List<CheckupLog>> checkupLogsByCheckupId;
  final List<PeriodCycle> periodCycles;
  final Map<String, List<PeriodLog>> periodLogsByCycleId;
  final MedicalPdfExportOptions options;

  MedicalPdfDataBundle({
    required this.profile,
    this.profileImageBytes,
    this.allergies = const [],
    this.emergencyContacts = const [],
    this.insurance,
    this.medications = const [],
    this.medicationLogs = const [],
    this.vitals = const [],
    this.historyEvents = const [],
    this.checkups = const [],
    this.checkupLogsByCheckupId = const {},
    this.periodCycles = const [],
    this.periodLogsByCycleId = const {},
    this.options = const MedicalPdfExportOptions(),
  });
}

class MedicalPdfService {
  final Ref _ref;

  MedicalPdfService(this._ref);

  FileService get _fileService => _ref.read(fileServiceProvider);
  ProfilesRepository get _profilesRepo => _ref.read(profilesRepositoryProvider);
  SharedProfilesRepository get _sharedRepo => _ref.read(sharedProfilesRepositoryProvider);

  /// Colors for medical layout
  static final PdfColor primaryNavy = PdfColor.fromHex('#1E3A8A');
  static final PdfColor clinicalBlue = PdfColor.fromHex('#2563EB');
  static final PdfColor lightBlueBg = PdfColor.fromHex('#F0F7FF');
  static final PdfColor alertRed = PdfColor.fromHex('#B91C1C');
  static final PdfColor alertRedBg = PdfColor.fromHex('#FEF2F2');
  static final PdfColor alertRedBorder = PdfColor.fromHex('#FCA5A5');
  static final PdfColor textDark = PdfColor.fromHex('#0F172A');
  static final PdfColor textMuted = PdfColor.fromHex('#475569');
  static final PdfColor borderSlate = PdfColor.fromHex('#CBD5E1');
  static final PdfColor borderLight = PdfColor.fromHex('#E2E8F0');
  static final PdfColor rowAltBg = PdfColor.fromHex('#F8FAFC');
  static final PdfColor badgeBg = PdfColor.fromHex('#E0E7FF');
  static final PdfColor badgeText = PdfColor.fromHex('#3730A3');

  /// Fetches all required profile data and bundles it for PDF generation.
  Future<MedicalPdfDataBundle> prepareDataBundle(
    String profileId, {
    MedicalPdfExportOptions options = const MedicalPdfExportOptions(),
  }) async {
    final localProfiles = await _profilesRepo.fetchProfiles(includeArchived: true);
    final sharedProfiles = await _sharedRepo.getSharedProfiles();
    final allProfiles = [...localProfiles, ...sharedProfiles];
    
    final profile = allProfiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => throw FormatException('Profile not found for ID: $profileId'),
    );

    // Profile photo bytes if available
    Uint8List? photoBytes;
    try {
      final photoPath = await _fileService.getProfileImagePath(profileId);
      if (photoPath.isNotEmpty && File(photoPath).existsSync()) {
        photoBytes = await File(photoPath).readAsBytes();
      }
    } catch (_) {}

    // Allergies
    List<Allergy> allergies = [];
    if (options.includeAllergies) {
      allergies = await _ref.read(allergiesRepositoryProvider).fetchAllergies(profileId);
    }

    // Emergency Contacts
    List<EmergencyContact> emergencyContacts = [];
    if (options.includeEmergencyContacts) {
      emergencyContacts = await _ref.read(emergencyRepositoryProvider).fetchEmergencyContacts(profileId);
    }

    // Medications & Logs
    List<Medication> medications = [];
    List<MedicationLog> medLogs = [];
    if (options.includeMedications) {
      medications = await _ref.read(medicationsRepositoryProvider).fetchMedications(profileId);
      medLogs = await _ref.read(medicationsRepositoryProvider).loadAllLogs(profileId, limit: 50);
    }

    // Vitals
    List<VitalLog> vitals = [];
    if (options.includeVitals) {
      final allVitals = await _ref.read(vitalsRepositoryProvider).fetchAllVitals(profileId);
      final cutoff = options.dateRange.cutoffDate;
      if (cutoff != null) {
        vitals = allVitals.where((v) => v.date.isAfter(cutoff)).toList();
      } else {
        vitals = allVitals;
      }
    }

    // History Events
    List<HistoryEvent> historyEvents = [];
    if (options.includeHistory) {
      final allEvents = await _ref.read(historyRepositoryProvider).fetchHistory(profileId);
      final cutoff = options.dateRange.cutoffDate;
      if (cutoff != null) {
        historyEvents = allEvents.where((e) => e.date.isAfter(cutoff)).toList();
      } else {
        historyEvents = allEvents;
      }
      historyEvents.sort((a, b) => b.date.compareTo(a.date));
    }

    // Checkups & Logs
    List<Checkup> checkups = [];
    final checkupLogsMap = <String, List<CheckupLog>>{};
    if (options.includeCheckups) {
      checkups = await _ref.read(checkupsRepositoryProvider).fetchCheckups(profileId);
      for (final c in checkups) {
        final logs = await _ref.read(checkupsRepositoryProvider).fetchCheckupLogs(c.id);
        checkupLogsMap[c.id] = logs;
      }
    }

    // Period cycles & logs
    List<PeriodCycle> periodCycles = [];
    final periodLogsMap = <String, List<PeriodLog>>{};
    if (options.includeFertility && profile.gender == Gender.female && profile.trackOvulation) {
      periodCycles = await _ref.read(periodRepositoryProvider).fetchPeriodCycles(profileId);
      final cutoff = options.dateRange.cutoffDate;
      if (cutoff != null) {
        periodCycles = periodCycles.where((c) => c.startDate.isAfter(cutoff)).toList();
      }
      for (final cycle in periodCycles) {
        final logs = await _ref.read(periodRepositoryProvider).fetchPeriodLogs(cycle.id);
        periodLogsMap[cycle.id] = logs;
      }
    }

    // Insurance
    InsurancePolicy? insurance;
    if (options.includeInsurance) {
      insurance = await _ref.read(insuranceRepositoryProvider).getInsurance(profileId);
    }

    return MedicalPdfDataBundle(
      profile: profile,
      profileImageBytes: photoBytes,
      allergies: allergies,
      emergencyContacts: emergencyContacts,
      insurance: insurance,
      medications: medications,
      medicationLogs: medLogs,
      vitals: vitals,
      historyEvents: historyEvents,
      checkups: checkups,
      checkupLogsByCheckupId: checkupLogsMap,
      periodCycles: periodCycles,
      periodLogsByCycleId: periodLogsMap,
      options: options,
    );
  }

  /// Builds a pw.Document from a pre-compiled MedicalPdfDataBundle.
  pw.Document buildPdfDocument(MedicalPdfDataBundle bundle) {
    final pdf = pw.Document(
      title: 'Medical Summary - ${bundle.profile.name} ${bundle.profile.surname}',
      author: 'Open Cloud Health',
      creator: 'Open Cloud Health Medical Export Engine',
    );

    final profile = bundle.profile;
    final options = bundle.options;
    final dateGenStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildPageHeader(context, profile),
        footer: (context) => _buildPageFooter(context, profile, dateGenStr),
        build: (context) {
          final widgets = <pw.Widget>[];

          // 1. Main Document Header Banner
          widgets.add(_buildDocumentBanner(profile, dateGenStr, options));
          widgets.add(pw.SizedBox(height: 12));

          // 2. Patient Demographics & Identification Card
          if (options.includeDemographics) {
            widgets.add(_buildDemographicsSection(profile, bundle.profileImageBytes, bundle.emergencyContacts, options));
            widgets.add(pw.SizedBox(height: 12));
          }

          // 2.5 Health Insurance & Policy Information
          if (options.includeInsurance && bundle.insurance != null) {
            widgets.add(_buildInsuranceSection(bundle.insurance!));
            widgets.add(pw.SizedBox(height: 12));
          }

          // 3. High Priority Clinical Alerts (Allergies & Chronic Conditions)
          if (options.includeAllergies || options.includeChronicConditions) {
            widgets.add(_buildClinicalAlertsSection(bundle.allergies, profile.chronicConditions, options));
            widgets.add(pw.SizedBox(height: 14));
          }

          // 4. Current Active Medications & Regimens
          if (options.includeMedications) {
            widgets.add(_buildMedicationsSection(bundle.medications));
            widgets.add(pw.SizedBox(height: 14));
          }

          // 5. Vital Signs & Biometric Trends
          if (options.includeVitals) {
            widgets.add(_buildVitalsSection(bundle.vitals));
            widgets.add(pw.SizedBox(height: 14));
          }

          // 6. Medical History, Consultations & Procedures
          if (options.includeHistory) {
            widgets.add(_buildHistorySection(bundle.historyEvents));
            widgets.add(pw.SizedBox(height: 14));
          }

          // 7. Preventive Care & Periodic Screenings
          if (options.includeCheckups) {
            widgets.add(_buildCheckupsSection(bundle.checkups, bundle.checkupLogsByCheckupId));
            widgets.add(pw.SizedBox(height: 14));
          }

          // 8. Fertility & Menstrual Health (if applicable)
          if (options.includeFertility && profile.gender == Gender.female && profile.trackOvulation && bundle.periodCycles.isNotEmpty) {
            widgets.add(_buildFertilitySection(bundle.periodCycles, bundle.periodLogsByCycleId));
            widgets.add(pw.SizedBox(height: 14));
          }

          // 9. Clinician Review & Attestation Section
          if (options.includeDoctorNotesSection) {
            widgets.add(_buildDoctorNotesSection());
          }

          return widgets;
        },
      ),
    );

    return pdf;
  }

  /// Generates the raw PDF bytes for a given profile ID.
  Future<Uint8List> generateMedicalPdfBytes(
    String profileId, {
    MedicalPdfExportOptions options = const MedicalPdfExportOptions(),
  }) async {
    final bundle = await prepareDataBundle(profileId, options: options);
    final pdf = buildPdfDocument(bundle);
    return await pdf.save();
  }

  /// Generates and writes the PDF to a temporary file on the device filesystem.
  Future<File> generateAndSaveMedicalPdf(
    String profileId, {
    MedicalPdfExportOptions options = const MedicalPdfExportOptions(),
  }) async {
    final bundle = await prepareDataBundle(profileId, options: options);
    final pdf = buildPdfDocument(bundle);
    final bytes = await pdf.save();

    final tempDir = await getTemporaryDirectory();
    final sanitizedName = '${bundle.profile.name}_${bundle.profile.surname}'.replaceAll(RegExp(r'[^\w]'), '_');
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = 'Medical_Summary_${sanitizedName}_$timestamp.pdf';
    final file = File(path.join(tempDir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // --- Sub-component Builders ---

  pw.Widget _buildPageHeader(pw.Context context, Profile profile) {
    if (context.pageNumber <= 1) {
      return pw.SizedBox.shrink();
    }
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: borderSlate, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'CONFIDENTIAL MEDICAL SUMMARY - ${profile.name.toUpperCase()} ${profile.surname.toUpperCase()}',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: textMuted,
            ),
          ),
          pw.Text(
            'DOB: ${profile.formattedDate} (Age: ${profile.age}) | Blood: ${profile.bloodType}',
            style: pw.TextStyle(
              fontSize: 8.5,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter(pw.Context context, Profile profile, String dateGenStr) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: borderLight, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Open Cloud Health - Patient Medical Record Summary - Generated: $dateGenStr',
            style: pw.TextStyle(fontSize: 7.5, color: textMuted),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textMuted),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDocumentBanner(Profile profile, String dateGenStr, MedicalPdfExportOptions options) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        color: primaryNavy,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PATIENT HEALTH SUMMARY & CLINICAL PROFILE',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Prepared for Healthcare Practitioner Review - Confidential Medical Record',
                style: pw.TextStyle(
                  color: PdfColor.fromHex('#93C5FD'),
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: clinicalBlue,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  options.dateRange.label.toUpperCase(),
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Date: $dateGenStr',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDemographicsSection(
    Profile profile,
    Uint8List? photoBytes,
    List<EmergencyContact> emergencyContacts,
    MedicalPdfExportOptions options,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightBlueBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderSlate, width: 0.8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: Photo or Avatar Placeholder
          if (photoBytes != null)
            pw.Container(
              width: 54,
              height: 54,
              margin: const pw.EdgeInsets.only(right: 12),
              decoration: pw.BoxDecoration(
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: clinicalBlue, width: 1.2),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 5,
                verticalRadius: 5,
                child: pw.Image(pw.MemoryImage(photoBytes), fit: pw.BoxFit.cover),
              ),
            )
          else
            pw.Container(
              width: 54,
              height: 54,
              margin: const pw.EdgeInsets.only(right: 12),
              decoration: pw.BoxDecoration(
                color: clinicalBlue,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Center(
                child: pw.Text(
                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'P',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),

          // Center: Patient Demographics Details
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${profile.name} ${profile.middleNames.isNotEmpty ? "${profile.middleNames} " : ""}${profile.surname}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: textDark,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    _buildInfoBadge('DOB', profile.formattedDate),
                    pw.SizedBox(width: 8),
                    _buildInfoBadge('Age', '${profile.age} yrs'),
                    pw.SizedBox(width: 8),
                    _buildInfoBadge('Sex', profile.gender.name.toUpperCase()),
                    pw.SizedBox(width: 8),
                    _buildInfoBadge('Blood Group', profile.bloodType, isHighlight: true),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text('Organ Donor: ', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                    pw.Text(
                      profile.isOrganDonor ? 'YES (Registered)' : 'No',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: profile.isOrganDonor ? PdfColor.fromHex('#047857') : textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right: Primary Emergency Contact (if enabled)
          if (options.includeEmergencyContacts && emergencyContacts.isNotEmpty)
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: borderLight, width: 0.6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'EMERGENCY CONTACT',
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textMuted),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      emergencyContacts.first.name,
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark),
                    ),
                    pw.Text(
                      '${emergencyContacts.first.relationship} | ${emergencyContacts.first.phoneNumber}',
                      style: pw.TextStyle(fontSize: 8, color: textDark),
                    ),
                    if (emergencyContacts.length > 1)
                      pw.Text(
                        '+ ${emergencyContacts.length - 1} more contact(s) on file',
                        style: pw.TextStyle(fontSize: 7, color: textMuted, fontStyle: pw.FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoBadge(String label, String value, {bool isHighlight = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: pw.BoxDecoration(
        color: isHighlight ? alertRedBg : PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        border: pw.Border.all(
          color: isHighlight ? alertRedBorder : borderLight,
          width: 0.6,
        ),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(fontSize: 8, color: textMuted),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: isHighlight ? alertRed : textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildInsuranceSection(InsurancePolicy insurance) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: lightBlueBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderSlate, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'HEALTH INSURANCE & COVERAGE',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryNavy),
              ),
              if (insurance.planName != null && insurance.planName!.isNotEmpty)
                pw.Text(
                  insurance.planName!,
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: clinicalBlue),
                ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildInfoBadge('Provider', insurance.provider),
              _buildInfoBadge('Policy #', insurance.policyNumber, isHighlight: true),
              if (insurance.groupNumber != null && insurance.groupNumber!.isNotEmpty)
                _buildInfoBadge('Group #', insurance.groupNumber!),
              if (insurance.subscriberName != null && insurance.subscriberName!.isNotEmpty)
                _buildInfoBadge('Main Member', insurance.subscriberName!),
              if (insurance.memberId != null && insurance.memberId!.isNotEmpty)
                _buildInfoBadge('Dependent Code', insurance.memberId!),
              if (insurance.emergencyPhone != null && insurance.emergencyPhone!.isNotEmpty)
                _buildInfoBadge('Pre-Auth Hotline', insurance.emergencyPhone!),
            ],
          ),
          if (insurance.notes != null && insurance.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Coverage Notes: ${insurance.notes}',
              style: pw.TextStyle(fontSize: 8, color: textMuted, fontStyle: pw.FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildClinicalAlertsSection(
    List<Allergy> allergies,
    List<String> chronicConditions,
    MedicalPdfExportOptions options,
  ) {
    final hasAllergies = allergies.isNotEmpty;
    final hasConditions = chronicConditions.isNotEmpty;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: hasAllergies ? alertRedBg : lightBlueBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(
          color: hasAllergies ? alertRedBorder : borderSlate,
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Allergies Column
              if (options.includeAllergies)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 6,
                            height: 6,
                            decoration: pw.BoxDecoration(
                              color: hasAllergies ? alertRed : PdfColor.fromHex('#10B981'),
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 5),
                          pw.Text(
                            'ALLERGIES & ADVERSE REACTIONS',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: hasAllergies ? alertRed : textDark,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      if (hasAllergies)
                        ...allergies.map((a) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 2, left: 11),
                              child: pw.RichText(
                                text: pw.TextSpan(
                                  children: [
                                    pw.TextSpan(
                                      text: '- ${a.name}',
                                      style: pw.TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: pw.FontWeight.bold,
                                        color: alertRed,
                                      ),
                                    ),
                                    if (a.note.isNotEmpty)
                                      pw.TextSpan(
                                        text: ' (${a.note})',
                                        style: pw.TextStyle(fontSize: 8, color: textDark),
                                      ),
                                  ],
                                ),
                              ),
                            ))
                      else
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 11),
                          child: pw.Text(
                            'No Known Drug or Food Allergies Documented (NKDA)',
                            style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: textMuted),
                          ),
                        ),
                    ],
                  ),
                ),

              if (options.includeAllergies && options.includeChronicConditions)
                pw.Container(
                  width: 1,
                  height: 38,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                  color: hasAllergies ? alertRedBorder : borderLight,
                ),

              // Chronic Conditions Column
              if (options.includeChronicConditions)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 6,
                            height: 6,
                            decoration: pw.BoxDecoration(
                              color: hasConditions ? primaryNavy : textMuted,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 5),
                          pw.Text(
                            'ACTIVE CHRONIC CONDITIONS',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryNavy,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      if (hasConditions)
                        pw.Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: chronicConditions.map((cond) {
                            return pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: badgeBg,
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                              ),
                              child: pw.Text(
                                cond,
                                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: badgeText),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 11),
                          child: pw.Text(
                            'No Chronic Conditions Documented',
                            style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: textMuted),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionHeading(String title, {String? subtitle}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.only(bottom: 3),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: primaryNavy, width: 1.2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: primaryNavy,
              letterSpacing: 0.3,
            ),
          ),
          if (subtitle != null)
            pw.Text(
              subtitle,
              style: pw.TextStyle(fontSize: 8, color: textMuted, fontStyle: pw.FontStyle.italic),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildMedicationsSection(List<Medication> medications) {
    final activeMeds = medications.where((m) => m.isActive).toList();
    final inactiveMeds = medications.where((m) => !m.isActive).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeading('Current Medications & Prescriptions', subtitle: '${activeMeds.length} Active'),
        if (medications.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: rowAltBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'No medications currently recorded for this patient.',
              style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: textMuted),
            ),
          )
        else ...[
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: borderLight, width: 0.5),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: primaryNavy),
            cellStyle: pw.TextStyle(fontSize: 8, color: textDark),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            headers: ['Medication', 'Dosage', 'Type', 'Schedule / Frequency', 'Status'],
            data: [
              ...activeMeds.map((m) => [
                    m.name,
                    m.dosage,
                    m.type,
                    _formatMedicationSchedule(m),
                    'Active',
                  ]),
              ...inactiveMeds.map((m) => [
                    m.name,
                    m.dosage,
                    m.type,
                    _formatMedicationSchedule(m),
                    'Discontinued / Inactive',
                  ]),
            ],
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(4),
              4: const pw.FlexColumnWidth(2),
            },
          ),
        ],
      ],
    );
  }

  String _formatMedicationSchedule(Medication m) {
    if (m.isAsNeeded) {
      return 'PRN (As Needed)';
    }
    final times = m.timesOfDay.map((t) {
      final hour = t.hour.toString().padLeft(2, '0');
      final minute = t.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }).join(', ');

    if (m.daysOfWeek.length == 7) {
      return 'Daily at $times';
    } else {
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final days = m.daysOfWeek.map((d) => (d >= 1 && d <= 7) ? dayNames[d - 1] : '').where((s) => s.isNotEmpty).join(', ');
      return '$days at $times';
    }
  }

  pw.Widget _buildVitalsSection(List<VitalLog> vitals) {
    final bpLogs = vitals.where((v) => v.type == VitalType.bloodPressure).toList();
    final bgLogs = vitals.where((v) => v.type == VitalType.bloodSugar).toList();
    final wtLogs = vitals.where((v) => v.type == VitalType.weight).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeading('Vital Signs & Clinical Biometrics', subtitle: '${vitals.length} Total Recordings'),
        if (vitals.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: rowAltBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'No vital sign records found for the selected timeframe.',
              style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: textMuted),
            ),
          )
        else ...[
          // Summary KPI Cards for each vital type
          pw.Row(
            children: [
              _buildVitalKpiCard('Blood Pressure', bpLogs, isBp: true, normalRef: 'Normal: <120/80 mmHg'),
              pw.SizedBox(width: 8),
              _buildVitalKpiCard('Blood Sugar', bgLogs, normalRef: 'Fasting: 70-99 mg/dL'),
              pw.SizedBox(width: 8),
              _buildVitalKpiCard('Weight', wtLogs, normalRef: 'Body Mass'),
            ],
          ),
          pw.SizedBox(height: 8),

          // Recent Vitals Log Table (Last 8 entries)
          pw.Text('Recent Measurements Log', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textDark)),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: borderLight, width: 0.5),
            headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryNavy),
            headerDecoration: pw.BoxDecoration(color: lightBlueBg),
            cellStyle: pw.TextStyle(fontSize: 7.5, color: textDark),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            headers: ['Date & Time', 'Vital Metric', 'Reading Value', 'Unit', 'Clinical Notes'],
            data: vitals.reversed.take(8).map((v) {
              final valStr = v.type == VitalType.bloodPressure && v.value2 != null
                  ? '${v.value1.toInt()}/${v.value2!.toInt()}'
                  : v.value1.toStringAsFixed(v.value1 == v.value1.roundToDouble() ? 0 : 1);
              return [
                DateFormat('yyyy-MM-dd HH:mm').format(v.date),
                _formatVitalName(v.type),
                valStr,
                v.unit,
                v.note ?? '-',
              ];
            }).toList(),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(4),
            },
          ),
        ],
      ],
    );
  }

  pw.Widget _buildVitalKpiCard(String label, List<VitalLog> logs, {bool isBp = false, String? normalRef}) {
    final latest = logs.isNotEmpty ? logs.last : null;
    String valueDisplay = 'No Data';
    String dateDisplay = '-';

    if (latest != null) {
      if (isBp && latest.value2 != null) {
        valueDisplay = '${latest.value1.toInt()}/${latest.value2!.toInt()} ${latest.unit}';
      } else {
        final val = latest.value1.toStringAsFixed(latest.value1 == latest.value1.roundToDouble() ? 0 : 1);
        valueDisplay = '$val ${latest.unit}';
      }
      dateDisplay = DateFormat('MM/dd/yy').format(latest.date);
    }

    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          color: rowAltBg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          border: pw.Border.all(color: borderLight, width: 0.6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textMuted)),
            pw.SizedBox(height: 2),
            pw.Text(
              valueDisplay,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: latest != null ? clinicalBlue : textMuted,
              ),
            ),
            pw.SizedBox(height: 1),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(dateDisplay, style: pw.TextStyle(fontSize: 6.5, color: textMuted)),
                if (normalRef != null)
                  pw.Text(
                    normalRef.split(':').first,
                    style: pw.TextStyle(fontSize: 6.5, color: textMuted, fontStyle: pw.FontStyle.italic),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatVitalName(VitalType type) {
    switch (type) {
      case VitalType.bloodPressure:
        return 'Blood Pressure';
      case VitalType.bloodSugar:
        return 'Blood Glucose';
      case VitalType.weight:
        return 'Body Weight';
    }
  }

  pw.Widget _buildHistorySection(List<HistoryEvent> events) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeading('Medical History & Clinical Encounters', subtitle: '${events.length} Events'),
        if (events.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: rowAltBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'No clinical events recorded for the selected timeframe.',
              style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: textMuted),
            ),
          )
        else ...[
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: borderLight, width: 0.5),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: primaryNavy),
            cellStyle: pw.TextStyle(fontSize: 7.5, color: textDark),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            headers: ['Date', 'Category', 'Encounter / Diagnosis', 'Provider & Facility', 'Clinical Notes / Summary'],
            data: events.map((e) {
              final providerFacility = [
                if (e.provider != null && e.provider!.isNotEmpty) 'Dr. ${e.provider}',
                if (e.facility != null && e.facility!.isNotEmpty) e.facility!,
              ].join(' | ');

              final attachInfo = e.attachmentCount > 0 ? ' [${e.attachmentCount} Attachment(s)]' : '';

              return [
                e.formattedDate,
                e.eventType.displayName,
                e.title + attachInfo,
                providerFacility.isNotEmpty ? providerFacility : '-',
                e.description.isNotEmpty ? e.description : '-',
              ];
            }).toList(),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(3.5),
              3: const pw.FlexColumnWidth(3),
              4: const pw.FlexColumnWidth(4.5),
            },
          ),
        ],
      ],
    );
  }

  pw.Widget _buildCheckupsSection(List<Checkup> checkups, Map<String, List<CheckupLog>> checkupLogsMap) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeading('Preventive Care & Routine Health Screenings', subtitle: '${checkups.length} Checkups Tracked'),
        if (checkups.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: rowAltBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'No periodic screenings currently scheduled.',
              style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: textMuted),
            ),
          )
        else ...[
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: borderLight, width: 0.5),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: primaryNavy),
            cellStyle: pw.TextStyle(fontSize: 7.5, color: textDark),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            headers: ['Screening / Checkup', 'Target Frequency', 'Last Completed', 'Doctor / Clinic', 'Findings / Notes'],
            data: checkups.map((c) {
              final logs = checkupLogsMap[c.id] ?? [];
              final latestLog = logs.isNotEmpty ? logs.first : null;
              final lastCompletedStr = latestLog != null ? DateFormat('yyyy-MM-dd').format(latestLog.dateCompleted) : 'Never';
              final docClinic = [
                if (latestLog?.doctorName != null && latestLog!.doctorName!.isNotEmpty) latestLog.doctorName!,
                if (latestLog?.location != null && latestLog!.location!.isNotEmpty) latestLog.location!,
              ].join(' / ');

              return [
                c.name,
                c.frequencyInMonths >= 12
                    ? 'Every ${c.frequencyInMonths ~/ 12} year(s)'
                    : 'Every ${c.frequencyInMonths} month(s)',
                lastCompletedStr,
                docClinic.isNotEmpty ? docClinic : '-',
                latestLog?.notes ?? '-',
              ];
            }).toList(),
            columnWidths: {
              0: const pw.FlexColumnWidth(3.5),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(2.5),
              3: const pw.FlexColumnWidth(3),
              4: const pw.FlexColumnWidth(4.5),
            },
          ),
        ],
      ],
    );
  }

  pw.Widget _buildFertilitySection(List<PeriodCycle> cycles, Map<String, List<PeriodLog>> logsMap) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeading('Menstrual & Reproductive Health History', subtitle: '${cycles.length} Cycles Logged'),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: borderLight, width: 0.5),
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: primaryNavy),
          cellStyle: pw.TextStyle(fontSize: 7.5, color: textDark),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          headers: ['Cycle Start', 'Cycle End', 'Duration', 'Symptoms & Mood Observations'],
          data: cycles.take(6).map((c) {
            final startStr = DateFormat('yyyy-MM-dd').format(c.startDate);
            final endStr = c.endDate != null ? DateFormat('yyyy-MM-dd').format(c.endDate!) : 'Ongoing';
            final durationStr = c.endDate != null ? '${c.endDate!.difference(c.startDate).inDays + 1} days' : '-';
            
            final logs = logsMap[c.id] ?? [];
            final symptoms = logs.expand((l) => l.physicalSymptoms).map((s) => s.name).toSet().toList();
            final moods = logs.expand((l) => l.moods).map((m) => m.name).toSet().toList();
            
            final summaryParts = <String>[];
            if (symptoms.isNotEmpty) summaryParts.add('Symptoms: ${symptoms.join(", ")}');
            if (moods.isNotEmpty) summaryParts.add('Mood: ${moods.join(", ")}');
            
            return [
              startStr,
              endStr,
              durationStr,
              summaryParts.isNotEmpty ? summaryParts.join(' | ') : 'Normal / No symptoms logged',
            ];
          }).toList(),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(2.5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(7),
          },
        ),
      ],
    );
  }

  pw.Widget _buildDoctorNotesSection() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: rowAltBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderSlate, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'HEALTHCARE PRACTITIONER CLINICAL NOTES & ATTESTATION',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: primaryNavy,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Clinical Observations / Plan:',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textMuted),
          ),
          pw.SizedBox(height: 30),
          pw.Container(
            height: 0.6,
            color: borderSlate,
            margin: const pw.EdgeInsets.symmetric(vertical: 6),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Reviewing Physician / Clinician Name: _______________________', style: pw.TextStyle(fontSize: 7.5, color: textDark)),
                  pw.SizedBox(height: 4),
                  pw.Text('License / Registration Number: ________________________________', style: pw.TextStyle(fontSize: 7.5, color: textDark)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Signature: ______________________  Date: ____________', style: pw.TextStyle(fontSize: 7.5, color: textDark)),
                  pw.SizedBox(height: 4),
                  pw.Text('Clinic Stamp / Facility: ___________________________', style: pw.TextStyle(fontSize: 7.5, color: textDark)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final medicalPdfServiceProvider = Provider<MedicalPdfService>((ref) {
  return MedicalPdfService(ref);
});
