import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/tables.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqlite3/common.dart' show CommonDatabase;
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

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
  Insurance,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_medications_profileId ON medications(profileId);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_medication_logs_medId_ts ON medication_logs(medicationId, timestamp);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_vital_logs_profileId_date ON vital_logs(profileId, date);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_history_profileId_date ON history(profileId, date);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_period_cycles_profileId ON period_cycles(profileId);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_period_logs_cycleId_date ON period_logs(cycleId, date);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_allergy_profileId ON allergy(profileId);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_attachments_historyId ON attachments(historyId);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_emergency_contacts_profileId ON emergency_contacts(profileId);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_insurance_profileId ON insurance(profileId);');
      },
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Step-by-step incremental migration pattern (idempotent for restored legacy databases)
        if (from < 2) {
          try {
            await m.createTable(insurance);
          } catch (_) {}
          try {
            await m.addColumn(lockScreenSettings, lockScreenSettings.showInsurance);
          } catch (_) {}
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

  /// Ensures [file] can be opened without `SqliteException(26): file is not a database`
  /// and normalizes any legacy schema or data formats from older backups.
  /// Returns the SQLCipher key to pass to `PRAGMA key`, or `null` if [file] is an
  /// unencrypted SQLite 3 file that should be opened without `PRAGMA key`.
  static Future<String?> ensureDatabaseReadable(
    File file, {
    String? explicitDbKey,
    SecureStorage? storage,
    List<String> extraCandidateKeys = const [],
  }) async {
    _setupSqlCipher();
    final secStorage = storage ?? SecureStorage();
    final primaryKey = explicitDbKey ?? await secStorage.getOrCreateDatabaseKey();

    if (!file.existsSync() || file.lengthSync() == 0) {
      return primaryKey;
    }

    // 1. Check if the database on disk is a plaintext (unencrypted) SQLite 3 file
    //    (e.g., restored from a cloud backup created before SQLCipher was enabled).
    if (isPlaintextSqliteFile(file)) {
      debugPrint('Detected plaintext SQLite database at ${file.path}. Normalizing...');
      _normalizePlaintextDatabaseOnDisk(file);
      final encryptedWithKey = _tryEncryptPlaintextDatabase(file, primaryKey);
      if (encryptedWithKey != null) {
        if (explicitDbKey == null) {
          await secStorage.setDatabaseKey(encryptedWithKey);
        }
        return encryptedWithKey;
      }
      // Plaintext SQLite file remains unencrypted on disk (e.g., on desktop or if
      // sqlcipher_export is unavailable); do not run PRAGMA key so SQLCipher opens it as plaintext.
      return null;
    }

    // 2. Encrypted SQLCipher file: probe candidate keys in priority order.
    final storedDbKey = await secStorage.getDatabaseKey();
    final localMasterKey = await secStorage.getLocalMasterKey();
    final cachedE2ePassword = await secStorage.getE2eCachedPassword();
    final recoveryKey = await secStorage.getE2eRecoveryKey();

    final candidates = <String>[
      if (explicitDbKey != null && explicitDbKey.isNotEmpty) explicitDbKey,
      if (storedDbKey != null && storedDbKey.isNotEmpty) storedDbKey,
      if (primaryKey.isNotEmpty) primaryKey,
      ...extraCandidateKeys.where((k) => k.isNotEmpty),
      if (localMasterKey != null && localMasterKey.isNotEmpty) localMasterKey,
      if (cachedE2ePassword != null && cachedE2ePassword.isNotEmpty) cachedE2ePassword,
      if (recoveryKey != null && recoveryKey.isNotEmpty) recoveryKey,
    ];

    final seen = <String>{};
    for (final candidate in candidates) {
      if (!seen.add(candidate)) continue;
      if (_canOpenEncryptedDatabase(file, candidate)) {
        if (explicitDbKey == null && candidate != storedDbKey) {
          await secStorage.setDatabaseKey(candidate);
        }
        return candidate;
      }
    }

    // 3. Last resort: if the file on disk cannot be read by any candidate key or as plaintext,
    //    quarantine it to `.corrupt_backup` and allow a clean database to be created so the app
    //    never gets permanently bricked on startup.
    debugPrint(
      'Database at ${file.path} could not be decrypted with any candidate key. '
      'Backing up to ${file.path}.corrupt_backup and resetting.',
    );
    try {
      final backupFile = File('${file.path}.corrupt_backup');
      file.copySync(backupFile.path);
      file.deleteSync();
      for (final suffix in ['-wal', '-shm', '-journal']) {
        final aux = File('${file.path}$suffix');
        if (aux.existsSync()) aux.deleteSync();
      }
    } catch (e) {
      debugPrint('Error quarantining unreadable database: $e');
    }
    return primaryKey;
  }
}

const List<int> _sqliteHeaderBytes = <int>[
  83, 81, 76, 105, 116, 101, 32, 102, 111, 114, 109, 97, 116, 32, 51, 0,
];

/// Returns `true` if [file] starts with the standard 16-byte `"SQLite format 3\x00"` header.
@visibleForTesting
bool isPlaintextSqliteFile(File file) {
  try {
    if (!file.existsSync() || file.lengthSync() < _sqliteHeaderBytes.length) {
      return false;
    }
    final raf = file.openSync(mode: FileMode.read);
    try {
      final header = raf.readSync(_sqliteHeaderBytes.length);
      if (header.length < _sqliteHeaderBytes.length) return false;
      for (var i = 0; i < _sqliteHeaderBytes.length; i++) {
        if (header[i] != _sqliteHeaderBytes[i]) return false;
      }
      return true;
    } finally {
      raf.closeSync();
    }
  } catch (_) {
    return false;
  }
}

String _escapeSqlLiteral(String value) => value.replaceAll("'", "''");

void _normalizePlaintextDatabaseOnDisk(File file) {
  sqlite3.Database? db;
  try {
    db = sqlite3.sqlite3.open(file.path);
    normalizeLegacyDatabase(db);
  } catch (e) {
    debugPrint('Warning normalizing plaintext database: $e');
  } finally {
    try {
      db?.dispose();
    } catch (_) {}
  }
}

/// Attempts to encrypt a plaintext SQLite 3 [file] in-place using SQLCipher's
/// `sqlcipher_export` when SQLCipher is active on the current platform.
/// Returns [targetKey] if encryption succeeded, or `null` if SQLCipher is not active
/// (e.g. desktop standard sqlite3) or export was skipped.
String? _tryEncryptPlaintextDatabase(File file, String targetKey) {
  if (targetKey.isEmpty) return null;
  final tmpFile = File('${file.path}.enc_tmp');
  sqlite3.Database? plainDb;
  try {
    if (tmpFile.existsSync()) tmpFile.deleteSync();
    plainDb = sqlite3.sqlite3.open(file.path);

    // Check whether SQLCipher is loaded (returns non-empty row on Android libsqlcipher.so,
    // empty on standard desktop sqlite3).
    final cipherVer = plainDb.select('PRAGMA cipher_version;');
    if (cipherVer.isEmpty) {
      return null;
    }

    final userVersionRows = plainDb.select('PRAGMA user_version;');
    final userVersion = userVersionRows.isNotEmpty
        ? (userVersionRows.first.values.first as int? ?? 2)
        : 2;

    final escapedPath = _escapeSqlLiteral(tmpFile.path);
    final escapedKey = _escapeSqlLiteral(targetKey);

    plainDb.execute("ATTACH DATABASE '$escapedPath' AS encrypted KEY '$escapedKey';");
    plainDb.select("SELECT sqlcipher_export('encrypted');");
    plainDb.execute('PRAGMA encrypted.user_version = $userVersion;');
    plainDb.execute('DETACH DATABASE encrypted;');
    plainDb.dispose();
    plainDb = null;

    if (tmpFile.existsSync() &&
        tmpFile.lengthSync() >= 16 &&
        !isPlaintextSqliteFile(tmpFile) &&
        _canOpenEncryptedDatabase(tmpFile, targetKey)) {
      for (final suffix in ['-wal', '-shm', '-journal']) {
        final aux = File('${file.path}$suffix');
        if (aux.existsSync()) aux.deleteSync();
      }
      file.deleteSync();
      tmpFile.renameSync(file.path);
      debugPrint('Successfully migrated plaintext database to SQLCipher.');
      return targetKey;
    }
  } catch (e) {
    debugPrint('Skipping in-place SQLCipher export (keeping plaintext mode): $e');
  } finally {
    try {
      plainDb?.dispose();
    } catch (_) {}
    try {
      if (tmpFile.existsSync()) tmpFile.deleteSync();
    } catch (_) {}
  }
  return null;
}

bool _canOpenEncryptedDatabase(File file, String candidateKey) {
  sqlite3.Database? db;
  try {
    db = sqlite3.sqlite3.open(file.path);
    final escapedKey = _escapeSqlLiteral(candidateKey);
    db.execute("PRAGMA key = '$escapedKey';");
    try {
      db.select('PRAGMA user_version;');
      db.select('SELECT count(*) FROM sqlite_master;');
      normalizeLegacyDatabase(db);
      return true;
    } catch (_) {
      // Try SQLCipher v1-v3 migration pragma in case the database was created with older cipher settings
      db.select('PRAGMA cipher_migrate;');
      db.select('PRAGMA user_version;');
      db.select('SELECT count(*) FROM sqlite_master;');
      normalizeLegacyDatabase(db);
      return true;
    }
  } catch (_) {
    return false;
  } finally {
    try {
      db?.dispose();
    } catch (_) {}
  }
}

/// Normalizes legacy `sqflite` (`DatabaseHelper` v1..v15) and early `Drift` schemas
/// and column data types (`TEXT` booleans `'true'`/`'false'` -> `INTEGER` `1`/`0`,
/// `TEXT` ISO-8601 dates -> `INTEGER` Unix epoch seconds, missing tables/columns,
/// and `PRAGMA user_version` > 2) so Drift can open any older backup without errors.
@visibleForTesting
void normalizeLegacyDatabase(CommonDatabase rawDb) {
  try {
    final tables = rawDb.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='profiles';",
    );
    if (tables.isEmpty) {
      // Brand-new empty database; Drift's onCreate will create all tables.
      return;
    }

    rawDb.execute('PRAGMA foreign_keys = OFF;');

    // 1. Ensure all tables added across legacy versions and schema v2 exist
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS history (
        id TEXT NOT NULL PRIMARY KEY,
        profileId TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        date INTEGER NOT NULL,
        eventType TEXT DEFAULT 'other',
        hasTime INTEGER DEFAULT 1,
        provider TEXT,
        facility TEXT
      );
    ''');
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS attachments (
        id TEXT NOT NULL PRIMARY KEY,
        historyId TEXT NOT NULL REFERENCES history(id) ON DELETE CASCADE,
        filename TEXT NOT NULL,
        uploadDate INTEGER NOT NULL,
        byteLength INTEGER NOT NULL
      );
    ''');
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS allergy (
        id TEXT NOT NULL PRIMARY KEY,
        profileId TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        note TEXT NOT NULL
      );
    ''');
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS medications (
        id TEXT NOT NULL PRIMARY KEY,
        profileId TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        type TEXT DEFAULT 'Other',
        notificationEnabled INTEGER DEFAULT 0,
        alarmEnabled INTEGER DEFAULT 0,
        timeOfDay TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        daysOfWeek TEXT,
        timesOfDay TEXT,
        isAsNeeded INTEGER DEFAULT 0,
        trackInventory INTEGER DEFAULT 0,
        stockQuantity REAL DEFAULT 0.0,
        lowStockThreshold REAL DEFAULT 0.0
      );
    ''');
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS medication_logs (
        id TEXT NOT NULL PRIMARY KEY,
        medicationId TEXT NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
        timestamp INTEGER NOT NULL,
        isTaken INTEGER DEFAULT 1,
        dosage TEXT
      );
    ''');
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS checkups (
        id TEXT NOT NULL PRIMARY KEY,
        profileId TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        frequencyInMonths INTEGER NOT NULL,
        iconName TEXT,
        isCustomInterval INTEGER DEFAULT 0,
        isActive INTEGER DEFAULT 1
      );
    ''');
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS checkup_logs (
        id TEXT NOT NULL PRIMARY KEY,
        checkupId TEXT NOT NULL REFERENCES checkups(id) ON DELETE CASCADE,
        dateCompleted INTEGER NOT NULL,
        location TEXT,
        doctorName TEXT,
        notes TEXT
      );
    ''');
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS period_cycles (
        id TEXT NOT NULL PRIMARY KEY,
        profileId TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        startDate INTEGER NOT NULL,
        endDate INTEGER
      );
    ''');
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS period_logs (
        id TEXT NOT NULL PRIMARY KEY,
        cycleId TEXT NOT NULL REFERENCES period_cycles(id) ON DELETE CASCADE,
        date INTEGER NOT NULL,
        flowLevel TEXT,
        moods TEXT,
        physicalSymptoms TEXT
      );
    ''');
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS vital_logs (
        id TEXT NOT NULL PRIMARY KEY,
        profileId TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        type TEXT NOT NULL,
        date INTEGER NOT NULL,
        value1 REAL NOT NULL,
        value2 REAL,
        unit TEXT NOT NULL,
        note TEXT
      );
    ''');
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT NOT NULL PRIMARY KEY,
        value TEXT
      );
    ''');
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS emergency_contacts (
        id TEXT NOT NULL PRIMARY KEY,
        profileId TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL,
        phoneNumber TEXT NOT NULL
      );
    ''');
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS lock_screen_settings (
        profileId TEXT NOT NULL PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
        showName INTEGER DEFAULT 1,
        showAge INTEGER DEFAULT 1,
        showBloodType INTEGER DEFAULT 1,
        showOrganDonor INTEGER DEFAULT 1,
        showChronicConditions INTEGER DEFAULT 1,
        showAllergies INTEGER DEFAULT 1,
        showMedications INTEGER DEFAULT 1,
        showContacts INTEGER DEFAULT 1,
        showInsurance INTEGER DEFAULT 1,
        isEnabled INTEGER DEFAULT 0
      );
    ''');
    rawDb.execute('''
      CREATE TABLE IF NOT EXISTS insurance (
        id TEXT NOT NULL PRIMARY KEY,
        profileId TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        provider TEXT NOT NULL,
        planName TEXT,
        policyNumber TEXT NOT NULL,
        groupNumber TEXT,
        subscriberName TEXT,
        memberId TEXT,
        emergencyPhone TEXT,
        frontCardImage TEXT,
        backCardImage TEXT,
        notes TEXT
      );
    ''');

    // 2. Ensure all columns exist on existing tables
    _ensureColumnExists(rawDb, 'profiles', 'middleNames', "TEXT NOT NULL DEFAULT ''");
    _ensureColumnExists(rawDb, 'profiles', 'isOrganDonor', 'INTEGER NOT NULL DEFAULT 0');
    _ensureColumnExists(rawDb, 'profiles', 'trackOvulation', 'INTEGER DEFAULT 1');
    _ensureColumnExists(rawDb, 'profiles', 'isArchived', 'INTEGER DEFAULT 0');
    _ensureColumnExists(rawDb, 'profiles', 'archivedAt', 'INTEGER');
    _ensureColumnExists(rawDb, 'profiles', 'chronicConditions', "TEXT DEFAULT ''");

    _ensureColumnExists(rawDb, 'history', 'eventType', "TEXT DEFAULT 'other'");
    _ensureColumnExists(rawDb, 'history', 'hasTime', 'INTEGER DEFAULT 1');
    _ensureColumnExists(rawDb, 'history', 'provider', 'TEXT');
    _ensureColumnExists(rawDb, 'history', 'facility', 'TEXT');

    _ensureColumnExists(rawDb, 'medications', 'type', "TEXT DEFAULT 'Other'");
    _ensureColumnExists(rawDb, 'medications', 'notificationEnabled', 'INTEGER DEFAULT 0');
    _ensureColumnExists(rawDb, 'medications', 'alarmEnabled', 'INTEGER DEFAULT 0');
    _ensureColumnExists(rawDb, 'medications', 'isActive', 'INTEGER DEFAULT 1');
    _ensureColumnExists(rawDb, 'medications', 'daysOfWeek', 'TEXT');
    _ensureColumnExists(rawDb, 'medications', 'timesOfDay', 'TEXT');
    _ensureColumnExists(rawDb, 'medications', 'isAsNeeded', 'INTEGER DEFAULT 0');
    _ensureColumnExists(rawDb, 'medications', 'trackInventory', 'INTEGER DEFAULT 0');
    _ensureColumnExists(rawDb, 'medications', 'stockQuantity', 'REAL DEFAULT 0.0');
    _ensureColumnExists(rawDb, 'medications', 'lowStockThreshold', 'REAL DEFAULT 0.0');

    _ensureColumnExists(rawDb, 'medication_logs', 'dosage', 'TEXT');

    _ensureColumnExists(rawDb, 'checkups', 'iconName', 'TEXT');
    _ensureColumnExists(rawDb, 'checkups', 'isCustomInterval', 'INTEGER DEFAULT 0');
    _ensureColumnExists(rawDb, 'checkups', 'isActive', 'INTEGER DEFAULT 1');

    _ensureColumnExists(rawDb, 'checkup_logs', 'location', 'TEXT');
    _ensureColumnExists(rawDb, 'checkup_logs', 'doctorName', 'TEXT');
    _ensureColumnExists(rawDb, 'checkup_logs', 'notes', 'TEXT');

    _ensureColumnExists(rawDb, 'lock_screen_settings', 'showInsurance', 'INTEGER DEFAULT 1');
    _ensureColumnExists(rawDb, 'lock_screen_settings', 'isEnabled', 'INTEGER DEFAULT 0');

    // 3. Convert legacy TEXT boolean values ('true' / 'false') to INTEGER (1 / 0)
    const boolColumns = <(String, String)>[
      ('profiles', 'isOrganDonor'),
      ('profiles', 'trackOvulation'),
      ('profiles', 'isArchived'),
      ('history', 'hasTime'),
      ('medications', 'notificationEnabled'),
      ('medications', 'alarmEnabled'),
      ('medications', 'isActive'),
      ('medications', 'isAsNeeded'),
      ('medications', 'trackInventory'),
      ('medication_logs', 'isTaken'),
      ('checkups', 'isCustomInterval'),
      ('checkups', 'isActive'),
      ('lock_screen_settings', 'showName'),
      ('lock_screen_settings', 'showAge'),
      ('lock_screen_settings', 'showBloodType'),
      ('lock_screen_settings', 'showOrganDonor'),
      ('lock_screen_settings', 'showChronicConditions'),
      ('lock_screen_settings', 'showAllergies'),
      ('lock_screen_settings', 'showMedications'),
      ('lock_screen_settings', 'showContacts'),
      ('lock_screen_settings', 'showInsurance'),
      ('lock_screen_settings', 'isEnabled'),
    ];

    for (final (table, col) in boolColumns) {
      rawDb.execute('''
        UPDATE $table
        SET $col = CASE
          WHEN lower(trim(CAST($col AS TEXT))) IN ('true', '1', 'yes') THEN 1
          ELSE 0
        END
        WHERE typeof($col) = 'text';
      ''');
    }

    // 4. Convert legacy TEXT ISO-8601 dates/timestamps to INTEGER Unix epoch seconds
    const dateColumns = <(String, String, bool)>[
      ('profiles', 'dateOfBirth', false),
      ('profiles', 'archivedAt', true),
      ('history', 'date', false),
      ('attachments', 'uploadDate', false),
      ('medication_logs', 'timestamp', false),
      ('checkup_logs', 'dateCompleted', false),
      ('period_cycles', 'startDate', false),
      ('period_cycles', 'endDate', true),
      ('period_logs', 'date', false),
      ('vital_logs', 'date', false),
    ];

    for (final (table, col, nullable) in dateColumns) {
      final rows = rawDb.select(
        "SELECT rowid AS _rid, $col AS _val FROM $table WHERE typeof($col) = 'text';",
      );
      if (rows.isEmpty) continue;

      final updateStmt = rawDb.prepare('UPDATE $table SET $col = ? WHERE rowid = ?;');
      try {
        for (final row in rows) {
          final rid = row['_rid'] as int;
          final rawVal = (row['_val'] as String?)?.trim() ?? '';
          if (rawVal.isEmpty && nullable) {
            updateStmt.execute([null, rid]);
            continue;
          }
          int? epochSeconds;
          final parsedInt = int.tryParse(rawVal);
          if (parsedInt != null) {
            epochSeconds = parsedInt > 100000000000 ? parsedInt ~/ 1000 : parsedInt;
          } else {
            final parsedDate = DateTime.tryParse(rawVal);
            if (parsedDate != null) {
              epochSeconds = parsedDate.millisecondsSinceEpoch ~/ 1000;
            }
          }
          if (epochSeconds != null) {
            updateStmt.execute([epochSeconds, rid]);
          } else if (nullable) {
            updateStmt.execute([null, rid]);
          } else {
            updateStmt.execute([0, rid]);
          }
        }
      } finally {
        updateStmt.dispose();
      }
    }

    // 5. If any table was created by legacy sqflite (where boolean/date columns had TEXT affinity,
    //    causing SQLite to coerce 0/1 back into '0'/'1' strings), rebuild the table with INTEGER columns.
    _rebuildTableIfLegacyTypes(
      rawDb,
      tableName: 'profiles',
      integerColumns: const ['dateOfBirth', 'isOrganDonor', 'trackOvulation', 'isArchived', 'archivedAt'],
      createSql: '''
        CREATE TABLE _och_mig_profiles (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          middleNames TEXT NOT NULL DEFAULT '',
          surname TEXT NOT NULL,
          dateOfBirth INTEGER NOT NULL,
          bloodType TEXT NOT NULL,
          gender TEXT NOT NULL,
          isOrganDonor INTEGER NOT NULL DEFAULT 0,
          trackOvulation INTEGER DEFAULT 1,
          isArchived INTEGER DEFAULT 0,
          archivedAt INTEGER,
          chronicConditions TEXT DEFAULT ''
        );
      ''',
      copySql: '''
        INSERT INTO _och_mig_profiles (
          id, name, middleNames, surname, dateOfBirth, bloodType, gender,
          isOrganDonor, trackOvulation, isArchived, archivedAt, chronicConditions
        )
        SELECT
          id,
          COALESCE(name, ''),
          COALESCE(middleNames, ''),
          COALESCE(surname, ''),
          COALESCE(CAST(dateOfBirth AS INTEGER), 0),
          COALESCE(bloodType, ''),
          COALESCE(gender, 'female'),
          COALESCE(CAST(isOrganDonor AS INTEGER), 0),
          CASE WHEN trackOvulation IS NULL THEN 1 ELSE CAST(trackOvulation AS INTEGER) END,
          CASE WHEN isArchived IS NULL THEN 0 ELSE CAST(isArchived AS INTEGER) END,
          CASE WHEN archivedAt IS NULL OR archivedAt = '' THEN NULL ELSE CAST(archivedAt AS INTEGER) END,
          COALESCE(chronicConditions, '')
        FROM profiles;
      ''',
    );

    _rebuildTableIfLegacyTypes(
      rawDb,
      tableName: 'history',
      integerColumns: const ['date', 'hasTime'],
      createSql: '''
        CREATE TABLE _och_mig_history (
          id TEXT NOT NULL PRIMARY KEY,
          profileId TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          date INTEGER NOT NULL,
          eventType TEXT DEFAULT 'other',
          hasTime INTEGER DEFAULT 1,
          provider TEXT,
          facility TEXT
        );
      ''',
      copySql: '''
        INSERT INTO _och_mig_history (
          id, profileId, title, description, date, eventType, hasTime, provider, facility
        )
        SELECT
          id,
          profileId,
          COALESCE(title, ''),
          COALESCE(description, ''),
          COALESCE(CAST(date AS INTEGER), 0),
          COALESCE(eventType, 'other'),
          CASE WHEN hasTime IS NULL THEN 1 ELSE CAST(hasTime AS INTEGER) END,
          provider,
          facility
        FROM history;
      ''',
    );

    _rebuildTableIfLegacyTypes(
      rawDb,
      tableName: 'attachments',
      integerColumns: const ['uploadDate', 'byteLength'],
      createSql: '''
        CREATE TABLE _och_mig_attachments (
          id TEXT NOT NULL PRIMARY KEY,
          historyId TEXT NOT NULL REFERENCES history(id) ON DELETE CASCADE,
          filename TEXT NOT NULL,
          uploadDate INTEGER NOT NULL,
          byteLength INTEGER NOT NULL
        );
      ''',
      copySql: '''
        INSERT INTO _och_mig_attachments (id, historyId, filename, uploadDate, byteLength)
        SELECT
          id,
          historyId,
          COALESCE(filename, ''),
          COALESCE(CAST(uploadDate AS INTEGER), 0),
          COALESCE(CAST(byteLength AS INTEGER), 0)
        FROM attachments;
      ''',
    );

    _rebuildTableIfLegacyTypes(
      rawDb,
      tableName: 'medications',
      integerColumns: const ['notificationEnabled', 'alarmEnabled', 'isActive', 'isAsNeeded', 'trackInventory'],
      createSql: '''
        CREATE TABLE _och_mig_medications (
          id TEXT NOT NULL PRIMARY KEY,
          profileId TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          dosage TEXT NOT NULL,
          type TEXT DEFAULT 'Other',
          notificationEnabled INTEGER DEFAULT 0,
          alarmEnabled INTEGER DEFAULT 0,
          timeOfDay TEXT NOT NULL,
          isActive INTEGER DEFAULT 1,
          daysOfWeek TEXT,
          timesOfDay TEXT,
          isAsNeeded INTEGER DEFAULT 0,
          trackInventory INTEGER DEFAULT 0,
          stockQuantity REAL DEFAULT 0.0,
          lowStockThreshold REAL DEFAULT 0.0
        );
      ''',
      copySql: '''
        INSERT INTO _och_mig_medications (
          id, profileId, name, dosage, type, notificationEnabled, alarmEnabled,
          timeOfDay, isActive, daysOfWeek, timesOfDay, isAsNeeded, trackInventory,
          stockQuantity, lowStockThreshold
        )
        SELECT
          id,
          profileId,
          COALESCE(name, ''),
          COALESCE(dosage, ''),
          COALESCE(type, 'Other'),
          CASE WHEN notificationEnabled IS NULL THEN 0 ELSE CAST(notificationEnabled AS INTEGER) END,
          CASE WHEN alarmEnabled IS NULL THEN 0 ELSE CAST(alarmEnabled AS INTEGER) END,
          COALESCE(timeOfDay, '08:00'),
          CASE WHEN isActive IS NULL THEN 1 ELSE CAST(isActive AS INTEGER) END,
          daysOfWeek,
          timesOfDay,
          CASE WHEN isAsNeeded IS NULL THEN 0 ELSE CAST(isAsNeeded AS INTEGER) END,
          CASE WHEN trackInventory IS NULL THEN 0 ELSE CAST(trackInventory AS INTEGER) END,
          COALESCE(CAST(stockQuantity AS REAL), 0.0),
          COALESCE(CAST(lowStockThreshold AS REAL), 0.0)
        FROM medications;
      ''',
    );

    _rebuildTableIfLegacyTypes(
      rawDb,
      tableName: 'medication_logs',
      integerColumns: const ['timestamp', 'isTaken'],
      createSql: '''
        CREATE TABLE _och_mig_medication_logs (
          id TEXT NOT NULL PRIMARY KEY,
          medicationId TEXT NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
          timestamp INTEGER NOT NULL,
          isTaken INTEGER DEFAULT 1,
          dosage TEXT
        );
      ''',
      copySql: '''
        INSERT INTO _och_mig_medication_logs (id, medicationId, timestamp, isTaken, dosage)
        SELECT
          id,
          medicationId,
          COALESCE(CAST(timestamp AS INTEGER), 0),
          CASE WHEN isTaken IS NULL THEN 1 ELSE CAST(isTaken AS INTEGER) END,
          dosage
        FROM medication_logs;
      ''',
    );

    _rebuildTableIfLegacyTypes(
      rawDb,
      tableName: 'checkups',
      integerColumns: const ['frequencyInMonths', 'isCustomInterval', 'isActive'],
      createSql: '''
        CREATE TABLE _och_mig_checkups (
          id TEXT NOT NULL PRIMARY KEY,
          profileId TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          frequencyInMonths INTEGER NOT NULL,
          iconName TEXT,
          isCustomInterval INTEGER DEFAULT 0,
          isActive INTEGER DEFAULT 1
        );
      ''',
      copySql: '''
        INSERT INTO _och_mig_checkups (
          id, profileId, name, frequencyInMonths, iconName, isCustomInterval, isActive
        )
        SELECT
          id,
          profileId,
          COALESCE(name, ''),
          COALESCE(CAST(frequencyInMonths AS INTEGER), 12),
          iconName,
          CASE WHEN isCustomInterval IS NULL THEN 0 ELSE CAST(isCustomInterval AS INTEGER) END,
          CASE WHEN isActive IS NULL THEN 1 ELSE CAST(isActive AS INTEGER) END
        FROM checkups;
      ''',
    );

    _rebuildTableIfLegacyTypes(
      rawDb,
      tableName: 'checkup_logs',
      integerColumns: const ['dateCompleted'],
      createSql: '''
        CREATE TABLE _och_mig_checkup_logs (
          id TEXT NOT NULL PRIMARY KEY,
          checkupId TEXT NOT NULL REFERENCES checkups(id) ON DELETE CASCADE,
          dateCompleted INTEGER NOT NULL,
          location TEXT,
          doctorName TEXT,
          notes TEXT
        );
      ''',
      copySql: '''
        INSERT INTO _och_mig_checkup_logs (id, checkupId, dateCompleted, location, doctorName, notes)
        SELECT
          id,
          checkupId,
          COALESCE(CAST(dateCompleted AS INTEGER), 0),
          location,
          doctorName,
          notes
        FROM checkup_logs;
      ''',
    );

    _rebuildTableIfLegacyTypes(
      rawDb,
      tableName: 'period_cycles',
      integerColumns: const ['startDate', 'endDate'],
      createSql: '''
        CREATE TABLE _och_mig_period_cycles (
          id TEXT NOT NULL PRIMARY KEY,
          profileId TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          startDate INTEGER NOT NULL,
          endDate INTEGER
        );
      ''',
      copySql: '''
        INSERT INTO _och_mig_period_cycles (id, profileId, startDate, endDate)
        SELECT
          id,
          profileId,
          COALESCE(CAST(startDate AS INTEGER), 0),
          CASE WHEN endDate IS NULL OR endDate = '' THEN NULL ELSE CAST(endDate AS INTEGER) END
        FROM period_cycles;
      ''',
    );

    _rebuildTableIfLegacyTypes(
      rawDb,
      tableName: 'period_logs',
      integerColumns: const ['date'],
      createSql: '''
        CREATE TABLE _och_mig_period_logs (
          id TEXT NOT NULL PRIMARY KEY,
          cycleId TEXT NOT NULL REFERENCES period_cycles(id) ON DELETE CASCADE,
          date INTEGER NOT NULL,
          flowLevel TEXT,
          moods TEXT,
          physicalSymptoms TEXT
        );
      ''',
      copySql: '''
        INSERT INTO _och_mig_period_logs (id, cycleId, date, flowLevel, moods, physicalSymptoms)
        SELECT
          id,
          cycleId,
          COALESCE(CAST(date AS INTEGER), 0),
          flowLevel,
          moods,
          physicalSymptoms
        FROM period_logs;
      ''',
    );

    _rebuildTableIfLegacyTypes(
      rawDb,
      tableName: 'vital_logs',
      integerColumns: const ['date'],
      createSql: '''
        CREATE TABLE _och_mig_vital_logs (
          id TEXT NOT NULL PRIMARY KEY,
          profileId TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          type TEXT NOT NULL,
          date INTEGER NOT NULL,
          value1 REAL NOT NULL,
          value2 REAL,
          unit TEXT NOT NULL,
          note TEXT
        );
      ''',
      copySql: '''
        INSERT INTO _och_mig_vital_logs (id, profileId, type, date, value1, value2, unit, note)
        SELECT
          id,
          profileId,
          COALESCE(type, ''),
          COALESCE(CAST(date AS INTEGER), 0),
          COALESCE(CAST(value1 AS REAL), 0.0),
          CASE WHEN value2 IS NULL THEN NULL ELSE CAST(value2 AS REAL) END,
          COALESCE(unit, ''),
          note
        FROM vital_logs;
      ''',
    );

    _rebuildTableIfLegacyTypes(
      rawDb,
      tableName: 'lock_screen_settings',
      integerColumns: const [
        'showName',
        'showAge',
        'showBloodType',
        'showOrganDonor',
        'showChronicConditions',
        'showAllergies',
        'showMedications',
        'showContacts',
        'showInsurance',
        'isEnabled',
      ],
      createSql: '''
        CREATE TABLE _och_mig_lock_screen_settings (
          profileId TEXT NOT NULL PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
          showName INTEGER DEFAULT 1,
          showAge INTEGER DEFAULT 1,
          showBloodType INTEGER DEFAULT 1,
          showOrganDonor INTEGER DEFAULT 1,
          showChronicConditions INTEGER DEFAULT 1,
          showAllergies INTEGER DEFAULT 1,
          showMedications INTEGER DEFAULT 1,
          showContacts INTEGER DEFAULT 1,
          showInsurance INTEGER DEFAULT 1,
          isEnabled INTEGER DEFAULT 0
        );
      ''',
      copySql: '''
        INSERT INTO _och_mig_lock_screen_settings (
          profileId, showName, showAge, showBloodType, showOrganDonor,
          showChronicConditions, showAllergies, showMedications, showContacts,
          showInsurance, isEnabled
        )
        SELECT
          profileId,
          CASE WHEN showName IS NULL THEN 1 ELSE CAST(showName AS INTEGER) END,
          CASE WHEN showAge IS NULL THEN 1 ELSE CAST(showAge AS INTEGER) END,
          CASE WHEN showBloodType IS NULL THEN 1 ELSE CAST(showBloodType AS INTEGER) END,
          CASE WHEN showOrganDonor IS NULL THEN 1 ELSE CAST(showOrganDonor AS INTEGER) END,
          CASE WHEN showChronicConditions IS NULL THEN 1 ELSE CAST(showChronicConditions AS INTEGER) END,
          CASE WHEN showAllergies IS NULL THEN 1 ELSE CAST(showAllergies AS INTEGER) END,
          CASE WHEN showMedications IS NULL THEN 1 ELSE CAST(showMedications AS INTEGER) END,
          CASE WHEN showContacts IS NULL THEN 1 ELSE CAST(showContacts AS INTEGER) END,
          CASE WHEN showInsurance IS NULL THEN 1 ELSE CAST(showInsurance AS INTEGER) END,
          CASE WHEN isEnabled IS NULL THEN 0 ELSE CAST(isEnabled AS INTEGER) END
        FROM lock_screen_settings;
      ''',
    );

    // 6. Normalize PRAGMA user_version so legacy sqflite versions (e.g. 1..15) align with Drift schemaVersion (2)
    final versionRows = rawDb.select('PRAGMA user_version;');
    final currentVersion = versionRows.isNotEmpty
        ? (versionRows.first.values.first as int? ?? 0)
        : 0;
    if (currentVersion != 2) {
      rawDb.execute('PRAGMA user_version = 2;');
    }
  } catch (e) {
    debugPrint('Error in normalizeLegacyDatabase: $e');
  }
}

void _rebuildTableIfLegacyTypes(
  CommonDatabase rawDb, {
  required String tableName,
  required List<String> integerColumns,
  required String createSql,
  required String copySql,
}) {
  try {
    final info = rawDb.select('PRAGMA table_info($tableName);');
    if (info.isEmpty) return;

    bool needsRebuild = false;
    for (final colName in integerColumns) {
      final colRow = info.where(
        (r) => (r['name'] as String?)?.toLowerCase() == colName.toLowerCase(),
      ).firstOrNull;
      if (colRow != null) {
        final colType = (colRow['type'] as String? ?? '').toUpperCase();
        if (!colType.contains('INT')) {
          needsRebuild = true;
          break;
        }
      }
    }

    if (!needsRebuild) return;

    final tempTable = '_och_mig_$tableName';
    rawDb.execute('DROP TABLE IF EXISTS $tempTable;');
    rawDb.execute(createSql);
    rawDb.execute(copySql);
    rawDb.execute('DROP TABLE $tableName;');
    rawDb.execute('ALTER TABLE $tempTable RENAME TO $tableName;');
  } catch (e) {
    debugPrint('Error rebuilding legacy table $tableName: $e');
  }
}

void _ensureColumnExists(
  CommonDatabase rawDb,
  String tableName,
  String columnName,
  String columnDefinition,
) {
  try {
    final info = rawDb.select('PRAGMA table_info($tableName);');
    final exists = info.any(
      (row) => (row['name'] as String?)?.toLowerCase() == columnName.toLowerCase(),
    );
    if (!exists) {
      rawDb.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition;');
    }
  } catch (e) {
    debugPrint('Could not ensure column $tableName.$columnName: $e');
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
    final workingKey = await AppDatabase.ensureDatabaseReadable(
      file,
      explicitDbKey: explicitDbKey,
    );

    return NativeDatabase.createInBackground(
      file,
      isolateSetup: _setupSqlCipher,
      setup: (rawDb) {
        if (workingKey != null && workingKey.isNotEmpty && !isPlaintextSqliteFile(file)) {
          final escapedKey = _escapeSqlLiteral(workingKey);
          rawDb.execute("PRAGMA key = '$escapedKey';");
        }
        normalizeLegacyDatabase(rawDb);
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



