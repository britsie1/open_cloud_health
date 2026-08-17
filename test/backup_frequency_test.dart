import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/models/backup_frequency.dart';

void main() {
  group('BackupFrequency Model Tests', () {
    test('fromString parses correctly', () {
      expect(BackupFrequency.fromString('never'), BackupFrequency.never);
      expect(BackupFrequency.fromString('manual'), BackupFrequency.manual);
      expect(BackupFrequency.fromString('tap'), BackupFrequency.manual);
      expect(BackupFrequency.fromString('daily'), BackupFrequency.daily);
      expect(BackupFrequency.fromString('weekly'), BackupFrequency.weekly);
      expect(BackupFrequency.fromString('monthly'), BackupFrequency.monthly);
      expect(BackupFrequency.fromString('UNKNOWN'), BackupFrequency.manual);
      expect(BackupFrequency.fromString(null), BackupFrequency.manual);
    });

    test('displayName and description are populated for all values', () {
      for (final freq in BackupFrequency.values) {
        expect(freq.displayName, isNotEmpty);
        expect(freq.description, isNotEmpty);
      }
    });

    test('isAutomated is true for daily, weekly, monthly and false for manual, never', () {
      expect(BackupFrequency.daily.isAutomated, true);
      expect(BackupFrequency.weekly.isAutomated, true);
      expect(BackupFrequency.monthly.isAutomated, true);
      expect(BackupFrequency.manual.isAutomated, false);
      expect(BackupFrequency.never.isAutomated, false);
    });

    test('interval matches expectation', () {
      expect(BackupFrequency.daily.interval, const Duration(days: 1));
      expect(BackupFrequency.weekly.interval, const Duration(days: 7));
      expect(BackupFrequency.monthly.interval, const Duration(days: 30));
      expect(BackupFrequency.manual.interval, isNull);
      expect(BackupFrequency.never.interval, isNull);
    });

    test('isDue returns false for manual and never regardless of timestamp', () {
      final now = DateTime(2026, 8, 17, 3, 0); // 3:00 AM
      final longAgo = DateTime(2025, 1, 1);

      expect(BackupFrequency.never.isDue(lastBackup: longAgo, now: now), false);
      expect(BackupFrequency.manual.isDue(lastBackup: longAgo, now: now), false);
      expect(BackupFrequency.never.isDue(lastBackup: null, now: now), false);
      expect(BackupFrequency.manual.isDue(lastBackup: null, now: now), false);
    });

    test('Daily frequency isDue logic with idle hours', () {
      final idleTime = DateTime(2026, 8, 17, 3, 0); // 3:00 AM
      final dayTime = DateTime(2026, 8, 17, 14, 0); // 2:00 PM

      // Never backed up
      expect(BackupFrequency.daily.isDue(lastBackup: null, now: idleTime), true);
      expect(BackupFrequency.daily.isDue(lastBackup: null, now: dayTime), false);
      expect(BackupFrequency.daily.isDue(lastBackup: null, now: dayTime, enforceIdleHours: false), true);

      // Backed up 10 hours ago (< 24h)
      final tenHoursAgo = idleTime.subtract(const Duration(hours: 10));
      expect(BackupFrequency.daily.isDue(lastBackup: tenHoursAgo, now: idleTime), false);

      // Backed up 26 hours ago (due, during idle time)
      final twentySixHoursAgo = idleTime.subtract(const Duration(hours: 26));
      expect(BackupFrequency.daily.isDue(lastBackup: twentySixHoursAgo, now: idleTime), true);

      // Backed up 26 hours ago (during daytime: not due yet until idle hours)
      final yesterdayNoon = dayTime.subtract(const Duration(hours: 26));
      expect(BackupFrequency.daily.isDue(lastBackup: yesterdayNoon, now: dayTime), false);

      // Backed up 60 hours ago (> 2x daily interval = overdue: should run immediately even during daytime)
      final sixtyHoursAgo = dayTime.subtract(const Duration(hours: 60));
      expect(BackupFrequency.daily.isDue(lastBackup: sixtyHoursAgo, now: dayTime), true);
    });

    test('Weekly frequency isDue logic', () {
      final idleTime = DateTime(2026, 8, 17, 3, 0);

      // Backed up 3 days ago (< 7 days)
      final threeDaysAgo = idleTime.subtract(const Duration(days: 3));
      expect(BackupFrequency.weekly.isDue(lastBackup: threeDaysAgo, now: idleTime), false);

      // Backed up 8 days ago (>= 7 days, idle hours)
      final eightDaysAgo = idleTime.subtract(const Duration(days: 8));
      expect(BackupFrequency.weekly.isDue(lastBackup: eightDaysAgo, now: idleTime), true);
    });
  });
}
