import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/tables.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqlite3/open.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Profiles,
  History,
  Attachments,
  Allergy,
  Medications,
  MedicationLogs,
  Checkups,
  CheckupLogs,
  PeriodCycles,
  PeriodLogs,
  VitalLogs,
  Settings,
  EmergencyContacts,
  LockScreenSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
      },
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Step-by-step incremental migration pattern
        for (var targetVersion = from + 1; targetVersion <= to; targetVersion++) {
          switch (targetVersion) {
            // Incremental migrations for future versions will be placed here
            default:
              break;
          }
        }
      },
    );
  }

  // --- Settings Helper Methods ---

  Future<bool> isLocalAuthEnabled() async {
    try {
      final query = select(settings)..where((tbl) => tbl.key.equals('local_auth_enabled'));
      final result = await query.getSingleOrNull();
      if (result == null) return false;
      return result.value == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> setLocalAuthEnabled(bool enabled) async {
    await into(settings).insertOnConflictUpdate(
      SettingEntry(key: 'local_auth_enabled', value: enabled.toString()),
    );
  }

  Future<bool> isSecurityBannerDismissed() async {
    try {
      final query = select(settings)..where((tbl) => tbl.key.equals('security_banner_dismissed'));
      final result = await query.getSingleOrNull();
      if (result == null) return false;
      return result.value == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> setSecurityBannerDismissed(bool dismissed) async {
    await into(settings).insertOnConflictUpdate(
      SettingEntry(key: 'security_banner_dismissed', value: dismissed.toString()),
    );
  }

  Future<String?> getPrimaryProfileId() async {
    try {
      final query = select(settings)..where((tbl) => tbl.key.equals('primary_profile_id'));
      final result = await query.getSingleOrNull();
      return result?.value;
    } catch (_) {
      return null;
    }
  }

  Future<void> setPrimaryProfileId(String? profileId) async {
    if (profileId == null) {
      await (delete(settings)..where((tbl) => tbl.key.equals('primary_profile_id'))).go();
    } else {
      await into(settings).insertOnConflictUpdate(
        SettingEntry(key: 'primary_profile_id', value: profileId),
      );
    }
  }

  Future<int> getDatabaseSize() async {
    final dbPath = await sql.getDatabasesPath();
    final dbFilePath = path.join(dbPath, 'opencloudhealth.db');
    final file = File(dbFilePath);
    if (file.existsSync()) {
      return file.lengthSync();
    }
    return 0;
  }

  Future<void> prepareForDatabaseReplacement() async {
    try {
      await customStatement('PRAGMA wal_checkpoint(FULL);');
    } catch (_) {}
    await close();
    try {
      final dbPath = await sql.getDatabasesPath();
      final walFile = File(path.join(dbPath, 'opencloudhealth.db-wal'));
      if (walFile.existsSync()) walFile.deleteSync();
      final shmFile = File(path.join(dbPath, 'opencloudhealth.db-shm'));
      if (shmFile.existsSync()) shmFile.deleteSync();
      final journalFile = File(path.join(dbPath, 'opencloudhealth.db-journal'));
      if (journalFile.existsSync()) journalFile.deleteSync();
    } catch (_) {}
  }

  Future<void> resetDatabase() async {
    try {
      await customStatement('PRAGMA wal_checkpoint(FULL);');
    } catch (_) {}
    await close();
    try {
      final dbPath = await sql.getDatabasesPath();
      final file = File(path.join(dbPath, 'opencloudhealth.db'));
      if (file.existsSync()) {
        file.deleteSync();
      }
      final walFile = File(path.join(dbPath, 'opencloudhealth.db-wal'));
      if (walFile.existsSync()) {
        walFile.deleteSync();
      }
      final shmFile = File(path.join(dbPath, 'opencloudhealth.db-shm'));
      if (shmFile.existsSync()) {
        shmFile.deleteSync();
      }
      final journalFile = File(path.join(dbPath, 'opencloudhealth.db-journal'));
      if (journalFile.existsSync()) {
        journalFile.deleteSync();
      }
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
void _setupSqlCipher() {
  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, () => DynamicLibrary.open('libsqlcipher.so'));
  }
}

LazyDatabase _openConnection([String? explicitDbKey]) {
  return LazyDatabase(() async {
    final dbFolder = await sql.getDatabasesPath();
    final file = File(path.join(dbFolder, 'opencloudhealth.db'));
    final key = explicitDbKey ?? await SecureStorage().getOrCreateDatabaseKey();

    _setupSqlCipher();

    return NativeDatabase.createInBackground(
      file,
      isolateSetup: _setupSqlCipher,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$key';");
        rawDb.execute('PRAGMA foreign_keys = ON;');
      },
    );
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});


