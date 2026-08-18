import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqlite_api.dart';

class DatabaseHelper {
  final AppDatabase? _appDb;

  DatabaseHelper([this._appDb]);

  AppDatabase get _db => _appDb ?? AppDatabase();

  Future<Database> getDatabase() async {
    final dbPath = await sql.getDatabasesPath();
    return sql.openDatabase(
      path.join(dbPath, 'opencloudhealth.db'),
      version: 15,
    );
  }

  Future<void> resetDatabase() async {
    await _db.resetDatabase();
  }

  Future<int> getDatabaseSize() async {
    return _db.getDatabaseSize();
  }

  // settings helper methods
  Future<bool> isLocalAuthEnabled() async {
    return _db.isLocalAuthEnabled();
  }

  Future<void> setLocalAuthEnabled(bool enabled) async {
    await _db.setLocalAuthEnabled(enabled);
  }

  Future<bool> isSecurityBannerDismissed() async {
    return _db.isSecurityBannerDismissed();
  }

  Future<void> setSecurityBannerDismissed(bool dismissed) async {
    await _db.setSecurityBannerDismissed(dismissed);
  }

  Future<String?> getPrimaryProfileId() async {
    return _db.getPrimaryProfileId();
  }

  Future<void> setPrimaryProfileId(String? profileId) async {
    await _db.setPrimaryProfileId(profileId);
  }
}

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  final appDb = ref.watch(appDatabaseProvider);
  return DatabaseHelper(appDb);
});

Future<Database> getDatabase() async => DatabaseHelper().getDatabase();
