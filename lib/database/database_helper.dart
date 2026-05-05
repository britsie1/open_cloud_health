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
      },
      version: 5,
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
    isOrganDonor TEXT
  )''';

String createHistoryTable = '''
  CREATE TABLE history(
    id TEXT PRIMARY KEY,
    profileId TEXT,
    title TEXT,
    description TEXT,
    date TEXT
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
    timeOfDay TEXT,
    isActive TEXT
  )''';

String createMedicationLogsTable = '''
  CREATE TABLE medication_logs(
    id TEXT PRIMARY KEY,
    medicationId TEXT,
    timestamp TEXT,
    isTaken TEXT
  )''';

String createCheckupsTable = '''
  CREATE TABLE checkups(
    id TEXT PRIMARY KEY,
    profileId TEXT,
    name TEXT,
    frequencyInMonths INTEGER,
    iconName TEXT
  )''';

String createCheckupLogsTable = '''
  CREATE TABLE checkup_logs(
    id TEXT PRIMARY KEY,
    checkupId TEXT,
    dateCompleted TEXT
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


