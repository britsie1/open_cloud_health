import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqlite_api.dart';

class DatabaseHelper {
  Future<Database> getDatabase() async {
    final dbPath = await sql.getDatabasesPath();
    final db = await sql.openDatabase(
      path.join(dbPath, 'opencloudhealth.db'),
      onCreate: (db, version) async {
        await db.execute(createProfilesTable);
        await db.execute(createHistoryTable);
        await db.execute(createAttachementsTable);
        await db.execute(createAllergyTable);
        await db.execute(createMedicationsTable);
        await db.execute(createMedicationLogsTable);
        await db.execute(createCheckupsTable);
        await db.execute(createCheckupLogsTable);
        await db.execute(createPeriodCyclesTable);
        await db.execute(createPeriodLogsTable);
        await db.execute(createVitalLogsTable);
        await db.execute(createSettingsTable);
        await db.execute(createEmergencyContactsTable);
        await db.execute(createLockScreenSettingsTable);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(createMedicationsTable);
          await db.execute(createMedicationLogsTable);
        }
        if (oldVersion < 3) {
          await db.execute(createCheckupsTable);
          await db.execute(createCheckupLogsTable);
        }
        if (oldVersion < 4) {
          await db.execute(createPeriodCyclesTable);
          await db.execute(createPeriodLogsTable);
        }
        if (oldVersion < 5) {
          await db.execute(createVitalLogsTable);
        }
        if (oldVersion < 6) {
          await db.execute("ALTER TABLE medications ADD COLUMN type TEXT DEFAULT 'Other'");
          await db.execute("ALTER TABLE medications ADD COLUMN alarmEnabled TEXT DEFAULT 'false'");
        }
        if (oldVersion < 7) {
          await db.execute("ALTER TABLE medications ADD COLUMN notificationEnabled TEXT DEFAULT 'false'");
        }
        if (oldVersion < 8) {
          await db.execute("ALTER TABLE medications ADD COLUMN daysOfWeek TEXT");
          await db.execute("ALTER TABLE medications ADD COLUMN timesOfDay TEXT");
        }
        if (oldVersion < 9) {
          await db.execute("ALTER TABLE medications ADD COLUMN isAsNeeded TEXT DEFAULT 'false'");
          await db.execute("ALTER TABLE medications ADD COLUMN trackInventory TEXT DEFAULT 'false'");
          await db.execute("ALTER TABLE medications ADD COLUMN stockQuantity REAL DEFAULT 0.0");
          await db.execute("ALTER TABLE medications ADD COLUMN lowStockThreshold REAL DEFAULT 0.0");
          await db.execute("ALTER TABLE medication_logs ADD COLUMN dosage TEXT");
        }
        if (oldVersion < 10) {
          await db.execute("ALTER TABLE profiles ADD COLUMN isArchived TEXT DEFAULT 'false'");
          await db.execute("ALTER TABLE profiles ADD COLUMN archivedAt TEXT");
        }
        if (oldVersion < 11) {
          await db.execute("ALTER TABLE history ADD COLUMN eventType TEXT DEFAULT 'other'");
          await db.execute("ALTER TABLE history ADD COLUMN hasTime TEXT DEFAULT 'true'");
          await db.execute("ALTER TABLE history ADD COLUMN provider TEXT");
          await db.execute("ALTER TABLE history ADD COLUMN facility TEXT");
        }
        if (oldVersion < 12) {
          await db.execute("ALTER TABLE profiles ADD COLUMN chronicConditions TEXT DEFAULT ''");
        }
        if (oldVersion < 13) {
          await db.execute(createSettingsTable);
        }
        if (oldVersion < 14) {
          await db.execute("ALTER TABLE checkups ADD COLUMN isCustomInterval TEXT DEFAULT 'false'");
          await db.execute("ALTER TABLE checkups ADD COLUMN isActive TEXT DEFAULT 'true'");
          await db.execute("ALTER TABLE checkup_logs ADD COLUMN location TEXT");
          await db.execute("ALTER TABLE checkup_logs ADD COLUMN doctorName TEXT");
          await db.execute("ALTER TABLE checkup_logs ADD COLUMN notes TEXT");
        }
        if (oldVersion < 15) {
          await db.execute(createEmergencyContactsTable);
          await db.execute(createLockScreenSettingsTable);
        }
      },
      version: 15,
    );

    return db;
  }

  Future<void> resetDatabase() async {
    final dbPath = await sql.getDatabasesPath();
    await sql.deleteDatabase(path.join(dbPath, 'opencloudhealth.db'));
  }

  Future<int> getDatabaseSize() async {
    final dbPath = await sql.getDatabasesPath();
    final dbFilePath = path.join(dbPath, 'opencloudhealth.db');
    return File(dbFilePath).lengthSync();
  }

  // settings helper methods
  Future<bool> isLocalAuthEnabled() async {
    try {
      final db = await getDatabase();
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['local_auth_enabled'],
      );
      if (result.isEmpty) return false;
      return result.first['value'] == 'true';
    } catch (e) {
      return false;
    }
  }

  Future<void> setLocalAuthEnabled(bool enabled) async {
    final db = await getDatabase();
    await db.insert(
      'settings',
      {'key': 'local_auth_enabled', 'value': enabled.toString()},
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  Future<bool> isSecurityBannerDismissed() async {
    try {
      final db = await getDatabase();
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['security_banner_dismissed'],
      );
      if (result.isEmpty) return false;
      return result.first['value'] == 'true';
    } catch (e) {
      return false;
    }
  }

  Future<void> setSecurityBannerDismissed(bool dismissed) async {
    final db = await getDatabase();
    await db.insert(
      'settings',
      {'key': 'security_banner_dismissed', 'value': dismissed.toString()},
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  Future<String?> getPrimaryProfileId() async {
    try {
      final db = await getDatabase();
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['primary_profile_id'],
      );
      if (result.isEmpty) return null;
      return result.first['value'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> setPrimaryProfileId(String? profileId) async {
    final db = await getDatabase();
    if (profileId == null) {
      await db.delete('settings', where: 'key = ?', whereArgs: ['primary_profile_id']);
    } else {
      await db.insert(
        'settings',
        {'key': 'primary_profile_id', 'value': profileId},
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
    }
  }
}

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

// Keep these as global functions for backward compatibility if needed, 
// but we should migrate to using the provider.
Future<Database> getDatabase() async => DatabaseHelper().getDatabase();

String createProfilesTable = '''
  CREATE TABLE profiles(
    id TEXT PRIMARY KEY, 
    name TEXT, 
    middleNames TEXT,
    surname TEXT, 
    dateOfBirth TEXT,
    bloodType TEXT, 
    gender TEXT,
    isOrganDonor TEXT,
    trackOvulation TEXT,
    isArchived TEXT DEFAULT 'false',
    archivedAt TEXT,
    chronicConditions TEXT DEFAULT ''
  )''';

String createHistoryTable = '''
  CREATE TABLE history(
    id TEXT PRIMARY KEY,
    profileId TEXT,
    title TEXT,
    description TEXT,
    date TEXT,
    eventType TEXT DEFAULT 'other',
    hasTime TEXT DEFAULT 'true',
    provider TEXT,
    facility TEXT
  )''';

String createAttachementsTable = '''
  CREATE TABLE attachments(
    id TEXT PRIMARY KEY,
    historyId TEXT,
    filename TEXT,
    uploadDate TEXT,
    byteLength INTEGER
  )''';

String createAllergyTable = '''
  CREATE TABLE allergy(
    id TEXT PRIMARY KEY,
    profileId TEXT,
    name TEXT,
    note TEXT
  )''';

String createMedicationsTable = '''
  CREATE TABLE medications(
    id TEXT PRIMARY KEY,
    profileId TEXT,
    name TEXT,
    dosage TEXT,
    type TEXT,
    notificationEnabled TEXT,
    alarmEnabled TEXT,
    timeOfDay TEXT,
    isActive TEXT,
    daysOfWeek TEXT,
    timesOfDay TEXT,
    isAsNeeded TEXT DEFAULT 'false',
    trackInventory TEXT DEFAULT 'false',
    stockQuantity REAL DEFAULT 0.0,
    lowStockThreshold REAL DEFAULT 0.0
  )''';

String createMedicationLogsTable = '''
  CREATE TABLE medication_logs(
    id TEXT PRIMARY KEY,
    medicationId TEXT,
    timestamp TEXT,
    isTaken TEXT,
    dosage TEXT
  )''';

String createCheckupsTable = '''
  CREATE TABLE checkups(
    id TEXT PRIMARY KEY,
    profileId TEXT,
    name TEXT,
    frequencyInMonths INTEGER,
    iconName TEXT,
    isCustomInterval TEXT DEFAULT 'false',
    isActive TEXT DEFAULT 'true'
  )''';

String createCheckupLogsTable = '''
  CREATE TABLE checkup_logs(
    id TEXT PRIMARY KEY,
    checkupId TEXT,
    dateCompleted TEXT,
    location TEXT,
    doctorName TEXT,
    notes TEXT
  )''';

String createPeriodCyclesTable = '''
  CREATE TABLE period_cycles(
    id TEXT PRIMARY KEY,
    profileId TEXT,
    startDate TEXT,
    endDate TEXT
  )''';

String createPeriodLogsTable = '''
  CREATE TABLE period_logs(
    id TEXT PRIMARY KEY,
    cycleId TEXT,
    date TEXT,
    flowLevel TEXT,
    moods TEXT,
    physicalSymptoms TEXT
  )''';

String createVitalLogsTable = '''
  CREATE TABLE vital_logs(
    id TEXT PRIMARY KEY,
    profileId TEXT,
    type TEXT,
    date TEXT,
    value1 REAL,
    value2 REAL,
    unit TEXT,
    note TEXT
  )''';

String createSettingsTable = '''
  CREATE TABLE IF NOT EXISTS settings(
    key TEXT PRIMARY KEY,
    value TEXT
  )''';

String createEmergencyContactsTable = '''
  CREATE TABLE emergency_contacts(
    id TEXT PRIMARY KEY,
    profileId TEXT,
    name TEXT,
    relationship TEXT,
    phoneNumber TEXT
  )''';

String createLockScreenSettingsTable = '''
  CREATE TABLE lock_screen_settings(
    profileId TEXT PRIMARY KEY,
    showName TEXT DEFAULT 'true',
    showAge TEXT DEFAULT 'true',
    showBloodType TEXT DEFAULT 'true',
    showOrganDonor TEXT DEFAULT 'true',
    showChronicConditions TEXT DEFAULT 'true',
    showAllergies TEXT DEFAULT 'true',
    showMedications TEXT DEFAULT 'true',
    showContacts TEXT DEFAULT 'true',
    isEnabled TEXT DEFAULT 'false'
  )''';


