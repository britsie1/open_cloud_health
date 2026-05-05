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
  static const String profiles = '/profiles';
  static const String profileDetail = '/profile-detail';
  static const String history = '/history';
  static const String historyDetail = '/history-detail';
  static const String medicationTracker = '/medication-tracker';
  static const String checkups = '/checkups';
  static const String measurements = '/measurements';
  static const String settings = '/settings';
}
