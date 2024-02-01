import 'dart:io';

import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqlite_api.dart';

Future<Database> getDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbPath, 'opencloudhealth.db'),
    onCreate: (db, version) async {
      await db.execute(createProfilesTable);
      await db.execute(createHistoryTable);
      await db.execute(createAttachementsTable);
      await db.execute(createAllergyTable);
    },
    version: 1,
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
    content BLOB
  )''';

String createAllergyTable = '''
  CREATE TABLE allergy(
    id TEXT PRIMARY KEY,
    profileId TEXT,
    name TEXT,
    note TEXT
  )''';