class AppAssets {
  static const String logo = 'assets/images/logo.png';
  static const String malePlaceholder = 'assets/images/male_placeholder.png';
  static const String femalePlaceholder = 'assets/images/female_placeholder.png';

  static String getGenderPlaceholder(String gender) {
    return 'assets/images/${gender.toLowerCase()}_placeholder.png';
  }
}

class AppRoutes {
  static const String auth = '/auth';
  static const String home = '/home';
  static const String homeBase = '/home-base';
  static const String profiles = '/profiles';
  static const String profileDetail = '/profile-detail';
  static const String profileBase = '/profile-base';
  static const String history = '/history';
  static const String historyBase = '/history-base';
  static const String historyDetail = '/history-detail';
  static const String historyReadonlyDetail = '/history-readonly-detail';
  static const String medicationTracker = '/medication-tracker';
  static const String medicationBase = '/medication-base';
  static const String medicationEditor = '/medication-editor';
  static const String checkups = '/checkups';
  static const String settings = '/settings';
  static const String periodTracker = '/period-tracker';
  static const String vitalTracker = '/vital-tracker';
  static const String importProfile = '/import-profile';
  static const String archivedProfiles = '/archived-profiles';
  static const String exportProfile = '/export-profile';
  static const String welcome = '/welcome';
  static const String securitySetup = '/security-setup';
  static const String emergencySettings = '/emergency-settings';
  static const String shareProfile = '/share-profile';
  static const String qrScanner = '/qr-scanner';
  static const String pdfPreview = '/pdf-preview';
}
