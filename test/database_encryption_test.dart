import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/services/backup_encryption_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
  });
}
