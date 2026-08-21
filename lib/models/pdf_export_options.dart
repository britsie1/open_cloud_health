enum PdfDateRangeFilter {
  allTime('All Records', 'Include complete medical history'),
  last30Days('Last 30 Days', 'Recent month of vitals and events'),
  last90Days('Last 90 Days', 'Last 3 months of vitals and events'),
  last6Months('Last 6 Months', 'Last half year of vitals and events'),
  lastYear('Last 1 Year', 'Past 12 months of vitals and events');

  final String label;
  final String description;
  const PdfDateRangeFilter(this.label, this.description);

  DateTime? get cutoffDate {
    final now = DateTime.now();
    switch (this) {
      case PdfDateRangeFilter.allTime:
        return null;
      case PdfDateRangeFilter.last30Days:
        return now.subtract(const Duration(days: 30));
      case PdfDateRangeFilter.last90Days:
        return now.subtract(const Duration(days: 90));
      case PdfDateRangeFilter.last6Months:
        return now.subtract(const Duration(days: 180));
      case PdfDateRangeFilter.lastYear:
        return now.subtract(const Duration(days: 365));
    }
  }
}

class MedicalPdfExportOptions {
  final bool includeDemographics;
  final bool includeAllergies;
  final bool includeChronicConditions;
  final bool includeMedications;
  final bool includeVitals;
  final bool includeHistory;
  final bool includeCheckups;
  final bool includeFertility;
  final bool includeEmergencyContacts;
  final bool includeDoctorNotesSection;
  final PdfDateRangeFilter dateRange;

  const MedicalPdfExportOptions({
    this.includeDemographics = true,
    this.includeAllergies = true,
    this.includeChronicConditions = true,
    this.includeMedications = true,
    this.includeVitals = true,
    this.includeHistory = true,
    this.includeCheckups = true,
    this.includeFertility = true,
    this.includeEmergencyContacts = true,
    this.includeDoctorNotesSection = true,
    this.dateRange = PdfDateRangeFilter.allTime,
  });

  MedicalPdfExportOptions copyWith({
    bool? includeDemographics,
    bool? includeAllergies,
    bool? includeChronicConditions,
    bool? includeMedications,
    bool? includeVitals,
    bool? includeHistory,
    bool? includeCheckups,
    bool? includeFertility,
    bool? includeEmergencyContacts,
    bool? includeDoctorNotesSection,
    PdfDateRangeFilter? dateRange,
  }) {
    return MedicalPdfExportOptions(
      includeDemographics: includeDemographics ?? this.includeDemographics,
      includeAllergies: includeAllergies ?? this.includeAllergies,
      includeChronicConditions: includeChronicConditions ?? this.includeChronicConditions,
      includeMedications: includeMedications ?? this.includeMedications,
      includeVitals: includeVitals ?? this.includeVitals,
      includeHistory: includeHistory ?? this.includeHistory,
      includeCheckups: includeCheckups ?? this.includeCheckups,
      includeFertility: includeFertility ?? this.includeFertility,
      includeEmergencyContacts: includeEmergencyContacts ?? this.includeEmergencyContacts,
      includeDoctorNotesSection: includeDoctorNotesSection ?? this.includeDoctorNotesSection,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}
