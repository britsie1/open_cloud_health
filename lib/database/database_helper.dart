import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqlite_api.dart';

final _buffer = StringBuffer();

Future<Database> getDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  //await sql.deleteDatabase(path.join(dbPath, 'opencloudhealth.db'));
  final db = await sql.openDatabase(
    path.join(dbPath, 'opencloudhealth.db'),
    onCreate: (db, version) {
      return db.execute(_getInitialScript());
    },
    version: 1,
  );

  return db;
}

String _getInitialScript(){
  _buffer.write(profilesTable);
  _buffer.write(historyTable);
  _buffer.write(attachementsTable);
  _buffer.write(allergyTable);

  return _buffer.toString();
}

String profilesTable = '''
  CREATE TABLE profiles(
    id TEXT PRIMARY KEY, 
    name TEXT, 
    middleNames TEXT,
    surname TEXT, 
    dateOfBirth TEXT,
    bloodType TEXT, 
    gender TEXT,
    isOrganDonor TEXT,
    image BLOB
  ); ''';

String historyTable = '''
  CREATE TABLE history(
    id TEXT PRIMARY KEY,
    profileId TEXT,
    title TEXT,
    date TEXT,
    description TEXT
  )''';

String attachementsTable = '''
  CREATE TABLE attachments(
    id TEXT PRIMARY KEY,
    historyId TEXT,
    filename TEXT PRIMARY KEY,
    uploadDate TEXT,
    content BLOB
  )
''';

String allergyTable = '''
  CREATE TABLE allergy(
    id TEXT PRIMARY KEY,
    profileId TEXT,
    name TEXT,
    note TEXT
  )
''';