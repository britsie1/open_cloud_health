import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/services/backup_encryption_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Encryption & Key Management Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('SecureStorage generates and retrieves 256-bit database key', () async {
      final secureStorage = SecureStorage();
      final key1 = await secureStorage.getOrCreateDatabaseKey();
      expect(key1, isNotEmpty);
      expect(key1.length, 64); // 32 bytes in hex = 64 characters

      final key2 = await secureStorage.getDatabaseKey();
      expect(key2, equals(key1));

      // Key persistence on subsequent getOrCreate call
      final key3 = await secureStorage.getOrCreateDatabaseKey();
      expect(key3, equals(key1));

      // Set custom key
      const customKey = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      await secureStorage.setDatabaseKey(customKey);
      expect(await secureStorage.getDatabaseKey(), equals(customKey));

      // Clear key
      await secureStorage.clearDatabaseKey();
      expect(await secureStorage.getDatabaseKey(), isNull);
    });

    test('Drift AppDatabase creates and queries tables with PRAGMA key', () async {
      const encryptionKey = 'test_secret_key_1234567890abcdef';
      final db = AppDatabase(NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute("PRAGMA key = '$encryptionKey';");
          rawDb.execute('PRAGMA foreign_keys = ON;');
        },
      ));

      try {
        expect(db.schemaVersion, 2);
        final profile = ProfileEntry(
          id: 'test-enc-prof-1',
          name: 'Encrypted Patient',
          middleNames: '',
          surname: 'Tester',
          dateOfBirth: DateTime(1995, 1, 1),
          bloodType: 'A+',
          gender: 'female',
          isOrganDonor: true,
          trackOvulation: true,
        );

        await db.into(db.profiles).insert(profile);
        final fetched = await (db.select(db.profiles)..where((t) => t.id.equals('test-enc-prof-1'))).getSingle();
        expect(fetched.name, equals('Encrypted Patient'));
      } finally {
        await db.close();
      }
    });

    test('BackupEncryptionService preserves and restores db_key.txt in encrypted archive', () async {
      final tempDir = Directory.systemTemp.createTempSync('db_test_backup_');
      final dbFile = File(path.join(tempDir.path, 'opencloudhealth.db'));
      await dbFile.writeAsString('mock_db_content');

      const testDbKey = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';
      const backupPassword = 'MySecureBackupPassword123!';

      try {
        final zipBytes = BackupEncryptionService.createZipArchive(
          dbFile: dbFile,
          databaseEncryptionKey: testDbKey,
        );

        final encryptedPayload = BackupEncryptionService.encryptBundle(zipBytes, backupPassword);
        final decryptedZip = BackupEncryptionService.decryptBundle(encryptedPayload, backupPassword);

        final restoreDir = Directory(path.join(tempDir.path, 'restored'));
        restoreDir.createSync();

        final restoredDbKey = BackupEncryptionService.unpackZipArchive(
          zipBytes: decryptedZip,
          dbDirectoryPath: restoreDir.path,
          localBasePath: restoreDir.path,
        );

        expect(restoredDbKey, equals(testDbKey));
        final restoredDbFile = File(path.join(restoreDir.path, 'opencloudhealth.db'));
        expect(restoredDbFile.existsSync(), isTrue);
        expect(await restoredDbFile.readAsString(), equals('mock_db_content'));
      } finally {
        try {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        } catch (_) {}
      }
    });

    test('Legacy plaintext backup database (v15 sqflite with TEXT booleans/dates) normalizes and opens in AppDatabase without SqliteException(26)', () async {
      final tempDir = Directory.systemTemp.createTempSync('db_legacy_restore_');
      final legacyDbFile = File(path.join(tempDir.path, 'opencloudhealth.db'));

      try {
        // 1. Create a legacy sqflite v15 plaintext SQLite database (no insurance table, TEXT booleans & ISO-8601 dates)
        final rawLegacy = sqlite3.sqlite3.open(legacyDbFile.path);
        rawLegacy.execute('''
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
          );
        ''');
        rawLegacy.execute('''
          INSERT INTO profiles (
            id, name, middleNames, surname, dateOfBirth, bloodType, gender,
            isOrganDonor, trackOvulation, isArchived, archivedAt, chronicConditions
          ) VALUES (
            'legacy-prof-1', 'Evelyn', 'Mae', 'Carter', '1952-04-19T00:00:00.000',
            'O+', 'female', 'true', 'false', 'false', NULL, 'Hypertension,Type 2 Diabetes'
          );
        ''');
        rawLegacy.execute('PRAGMA user_version = 15;');
        rawLegacy.dispose();

        expect(isPlaintextSqliteFile(legacyDbFile), isTrue);

        // 2. Simulate restoring an older backup ZIP that has NO db_key.txt
        final zipBytes = BackupEncryptionService.createZipArchive(
          dbFile: legacyDbFile,
          databaseEncryptionKey: null,
        );
        final restoreDir = Directory(path.join(tempDir.path, 'restored_db'));
        restoreDir.createSync();

        final restoredDbKey = BackupEncryptionService.unpackZipArchive(
          zipBytes: zipBytes,
          dbDirectoryPath: restoreDir.path,
          localBasePath: restoreDir.path,
        );
        expect(restoredDbKey, isNull);

        final restoredFile = File(path.join(restoreDir.path, 'opencloudhealth.db'));
        final workingKey = await AppDatabase.ensureDatabaseReadable(restoredFile);

        // 3. Open in Drift AppDatabase using the same setup logic as _openConnection
        final appDb = AppDatabase(
          NativeDatabase(
            restoredFile,
            setup: (rawDb) {
              if (workingKey != null && workingKey.isNotEmpty && !isPlaintextSqliteFile(restoredFile)) {
                rawDb.execute("PRAGMA key = '$workingKey';");
              }
              normalizeLegacyDatabase(rawDb);
              rawDb.execute('PRAGMA foreign_keys = ON;');
            },
          ),
        );

        try {
          final repo = ProfilesRepository(appDb);
          final profiles = await repo.fetchProfiles();
          expect(profiles.length, 1);
          expect(profiles.first.id, 'legacy-prof-1');
          expect(profiles.first.name, 'Evelyn');
          expect(profiles.first.surname, 'Carter');
          expect(profiles.first.isOrganDonor, isTrue);
          expect(profiles.first.trackOvulation, isFalse);
          expect(profiles.first.isArchived, isFalse);
          expect(profiles.first.dateOfBirth.year, 1952);
          expect(profiles.first.chronicConditions, contains('Hypertension'));
        } finally {
          await appDb.close();
        }
      } finally {
        try {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        } catch (_) {}
      }
    });

    test('ensureDatabaseReadable quarantines unreadable corrupt database file instead of bricking startup', () async {
      final tempDir = Directory.systemTemp.createTempSync('db_corrupt_test_');
      final corruptFile = File(path.join(tempDir.path, 'opencloudhealth.db'));

      try {
        // Write 64 random non-SQLite bytes that cannot be decrypted with any key
        await corruptFile.writeAsBytes(List<int>.generate(64, (i) => (i * 37 + 13) & 0xFF));
        expect(isPlaintextSqliteFile(corruptFile), isFalse);

        final key = await AppDatabase.ensureDatabaseReadable(corruptFile);
        expect(key, isNotNull);
        expect(key, isNotEmpty);

        // Original unreadable file is quarantined to .corrupt_backup and cleared for fresh initialization
        final backupFile = File('${corruptFile.path}.corrupt_backup');
        expect(backupFile.existsSync(), isTrue);
        expect(corruptFile.existsSync(), isFalse);
      } finally {
        try {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        } catch (_) {}
      }
    });
  });
}
