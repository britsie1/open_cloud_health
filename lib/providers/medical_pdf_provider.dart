import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/pdf_export_options.dart';
import 'package:open_cloud_health/services/medical_pdf_service.dart';

export 'package:open_cloud_health/models/pdf_export_options.dart';
export 'package:open_cloud_health/services/medical_pdf_service.dart';

class PdfExportParams {
  final String profileId;
  final MedicalPdfExportOptions options;

  const PdfExportParams({
    required this.profileId,
    this.options = const MedicalPdfExportOptions(),
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfExportParams &&
          runtimeType == other.runtimeType &&
          profileId == other.profileId &&
          options.includeDemographics == other.options.includeDemographics &&
          options.includeAllergies == other.options.includeAllergies &&
          options.includeChronicConditions == other.options.includeChronicConditions &&
          options.includeMedications == other.options.includeMedications &&
          options.includeVitals == other.options.includeVitals &&
          options.includeHistory == other.options.includeHistory &&
          options.includeCheckups == other.options.includeCheckups &&
          options.includeFertility == other.options.includeFertility &&
          options.includeEmergencyContacts == other.options.includeEmergencyContacts &&
          options.includeDoctorNotesSection == other.options.includeDoctorNotesSection &&
          options.dateRange == other.options.dateRange;

  @override
  int get hashCode =>
      profileId.hashCode ^
      options.includeDemographics.hashCode ^
      options.includeAllergies.hashCode ^
      options.includeChronicConditions.hashCode ^
      options.includeMedications.hashCode ^
      options.includeVitals.hashCode ^
      options.includeHistory.hashCode ^
      options.includeCheckups.hashCode ^
      options.includeFertility.hashCode ^
      options.includeEmergencyContacts.hashCode ^
      options.includeDoctorNotesSection.hashCode ^
      options.dateRange.hashCode;
}

final medicalPdfBytesProvider =
    FutureProvider.family<Uint8List, PdfExportParams>((ref, params) async {
  final service = ref.read(medicalPdfServiceProvider);
  return await service.generateMedicalPdfBytes(
    params.profileId,
    options: params.options,
  );
});

final medicalPdfFileProvider =
    FutureProvider.family<File, PdfExportParams>((ref, params) async {
  final service = ref.read(medicalPdfServiceProvider);
  return await service.generateAndSaveMedicalPdf(
    params.profileId,
    options: params.options,
  );
});
