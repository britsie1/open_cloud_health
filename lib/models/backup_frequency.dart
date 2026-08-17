enum BackupFrequency {
  never,
  manual,
  daily,
  weekly,
  monthly;

  String get displayName {
    switch (this) {
      case BackupFrequency.never:
        return 'Never';
      case BackupFrequency.manual:
        return 'Only when I tap "Back up"';
      case BackupFrequency.daily:
        return 'Daily';
      case BackupFrequency.weekly:
        return 'Weekly';
      case BackupFrequency.monthly:
        return 'Monthly';
    }
  }

  String get description {
    switch (this) {
      case BackupFrequency.never:
        return 'Automatic cloud backups are disabled.';
      case BackupFrequency.manual:
        return 'Only runs when you manually press "Back Up Now".';
      case BackupFrequency.daily:
        return 'Backs up every night during idle hours (2:00 AM – 5:00 AM).';
      case BackupFrequency.weekly:
        return 'Backs up once a week during idle hours.';
      case BackupFrequency.monthly:
        return 'Backs up once a month during idle hours.';
    }
  }

  Duration? get interval {
    switch (this) {
      case BackupFrequency.daily:
        return const Duration(days: 1);
      case BackupFrequency.weekly:
        return const Duration(days: 7);
      case BackupFrequency.monthly:
        return const Duration(days: 30);
      case BackupFrequency.never:
      case BackupFrequency.manual:
        return null;
    }
  }

  bool get isAutomated =>
      this == BackupFrequency.daily ||
      this == BackupFrequency.weekly ||
      this == BackupFrequency.monthly;

  /// Returns true if a backup is due given the last backup timestamp.
  /// If [enforceIdleHours] is true, checks that the current time is within [startIdleHour]..[endIdleHour],
  /// unless the backup is overdue by more than double its standard interval.
  bool isDue({
    DateTime? lastBackup,
    DateTime? now,
    bool enforceIdleHours = true,
    int startIdleHour = 2,
    int endIdleHour = 5,
  }) {
    if (!isAutomated) return false;

    final currentTime = now ?? DateTime.now();
    final currentHour = currentTime.hour;
    final isIdleWindow = currentHour >= startIdleHour && currentHour < endIdleHour;

    if (lastBackup == null) {
      // Never backed up before: backup during idle window or if idle enforcement is off
      return !enforceIdleHours || isIdleWindow;
    }

    final diff = currentTime.difference(lastBackup);
    final targetInterval = interval!;

    // If we haven't reached the interval yet, not due
    if (diff < targetInterval) {
      return false;
    }

    // If overdue by 2x the interval, run immediately regardless of hour
    if (diff >= targetInterval * 2) {
      return true;
    }

    // Otherwise, run only if currently in the idle window (or enforcement disabled)
    if (!enforceIdleHours) {
      return true;
    }

    return isIdleWindow;
  }

  static BackupFrequency fromString(String? value) {
    if (value == null) return BackupFrequency.manual;
    switch (value.toLowerCase().trim()) {
      case 'never':
        return BackupFrequency.never;
      case 'manual':
      case 'only_manual':
      case 'tap':
        return BackupFrequency.manual;
      case 'daily':
        return BackupFrequency.daily;
      case 'weekly':
        return BackupFrequency.weekly;
      case 'monthly':
        return BackupFrequency.monthly;
      default:
        return BackupFrequency.manual;
    }
  }
}
