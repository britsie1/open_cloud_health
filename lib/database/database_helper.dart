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
    isOrganDonor TEXT
  ); ''';

String historyTable = '''
  CREATE TABLE history(
    id TEXT PRIMARY KEY,
    userId TEXT,
    title TEXT,
    date TEXT,
    description TEXT
  )''';