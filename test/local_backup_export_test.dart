import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/services/backup_encryption_service.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File testDbFile;
  late Directory testProfileImagesDir;
  late Directory testAttachmentsDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('och_test_backup_');
    testDbFile = File(path.join(tempDir.path, 'opencloudhealth.db'));
    testDbFile.writeAsStringSync('MOCK_SQLITE_DATABASE_DATA_TEST_12345');

    testProfileImagesDir = Directory(path.join(tempDir.path, 'profileImages'));
    testProfileImagesDir.createSync(recursive: true);
    final avatarFile = File(path.join(testProfileImagesDir.path, 'avatar_p1.jpg'));
    avatarFile.writeAsBytesSync([1, 2, 3, 4, 5, 6, 7, 8]);

    testAttachmentsDir = Directory(path.join(tempDir.path, 'attachments', 'event_1'));
    testAttachmentsDir.createSync(recursive: true);
    final pdfFile = File(path.join(testAttachmentsDir.path, 'lab_report.pdf'));
    pdfFile.writeAsStringSync('%PDF-1.4 Mock Lab Results Blood Test');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Local Backup Export and Import Tests', () {
    test('creates full ZIP archive with database, avatar photos, and attachments', () {
      final zipBytes = BackupEncryptionService.createZipArchive(
        dbFile: testDbFile,
        profileImagesDir: testProfileImagesDir,
        attachmentsDir: Directory(path.join(tempDir.path, 'attachments')),
      );

      expect(zipBytes, isNotEmpty);

      // Unpack in a clean destination directory
      final restoreDbDir = Directory(path.join(tempDir.path, 'restore_db'));
      final restoreBaseDir = Directory(path.join(tempDir.path, 'restore_base'));
      restoreDbDir.createSync(recursive: true);
      restoreBaseDir.createSync(recursive: true);

      BackupEncryptionService.unpackZipArchive(
        zipBytes: zipBytes,
        dbDirectoryPath: restoreDbDir.path,
        localBasePath: restoreBaseDir.path,
      );

      final restoredDb = File(path.join(restoreDbDir.path, 'opencloudhealth.db'));
      expect(restoredDb.existsSync(), isTrue);
      expect(restoredDb.readAsStringSync(), 'MOCK_SQLITE_DATABASE_DATA_TEST_12345');

      final restoredAvatar = File(path.join(restoreBaseDir.path, 'profileImages', 'avatar_p1.jpg'));
      expect(restoredAvatar.existsSync(), isTrue);
      expect(restoredAvatar.readAsBytesSync(), [1, 2, 3, 4, 5, 6, 7, 8]);

      final restoredPdf = File(path.join(restoreBaseDir.path, 'attachments', 'event_1', 'lab_report.pdf'));
      expect(restoredPdf.existsSync(), isTrue);
      expect(restoredPdf.readAsStringSync(), '%PDF-1.4 Mock Lab Results Blood Test');
    });

    test('exportLocalBackupToFile and importLocalBackupFromFile with custom password', () async {
      final exportPath = path.join(tempDir.path, 'export_test.ochbackup');
      const password = 'MedicalPassword!2026';

      final exportedFile = await BackupEncryptionService.exportLocalBackupToFile(
        dbFile: testDbFile,
        targetFilePath: exportPath,
        profileImagesDir: testProfileImagesDir,
        attachmentsDir: Directory(path.join(tempDir.path, 'attachments')),
        encryptionPasswordOrKey: password,
      );

      expect(exportedFile.existsSync(), isTrue);
      expect(exportedFile.lengthSync(), greaterThan(0));

      // Restore destination
      final restoreDbDir = Directory(path.join(tempDir.path, 'restore_db_pass'));
      final restoreBaseDir = Directory(path.join(tempDir.path, 'restore_base_pass'));

      await BackupEncryptionService.importLocalBackupFromFile(
        backupFile: exportedFile,
        dbDirectoryPath: restoreDbDir.path,
        localBasePath: restoreBaseDir.path,
        encryptionPasswordOrKey: password,
      );

      final restoredDb = File(path.join(restoreDbDir.path, 'opencloudhealth.db'));
      expect(restoredDb.existsSync(), isTrue);
      expect(restoredDb.readAsStringSync(), 'MOCK_SQLITE_DATABASE_DATA_TEST_12345');
    });

    test('importLocalBackupFromFile fails and throws FormatException with incorrect password', () async {
      final exportPath = path.join(tempDir.path, 'export_wrong_pass.ochbackup');
      const password = 'CorrectPassword#99';
      const wrongPassword = 'WrongPassword#00';

      final exportedFile = await BackupEncryptionService.exportLocalBackupToFile(
        dbFile: testDbFile,
        targetFilePath: exportPath,
        profileImagesDir: testProfileImagesDir,
        attachmentsDir: Directory(path.join(tempDir.path, 'attachments')),
        encryptionPasswordOrKey: password,
      );

      final restoreDbDir = Directory(path.join(tempDir.path, 'restore_fail_db'));
      final restoreBaseDir = Directory(path.join(tempDir.path, 'restore_fail_base'));

      expect(
        () async => await BackupEncryptionService.importLocalBackupFromFile(
          backupFile: exportedFile,
          dbDirectoryPath: restoreDbDir.path,
          localBasePath: restoreBaseDir.path,
          encryptionPasswordOrKey: wrongPassword,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('export and import with 256-bit hardware master key', () async {
      final exportPath = path.join(tempDir.path, 'export_master_key.ochbackup');
      const masterKey = 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';

      final exportedFile = await BackupEncryptionService.exportLocalBackupToFile(
        dbFile: testDbFile,
        targetFilePath: exportPath,
        profileImagesDir: testProfileImagesDir,
        attachmentsDir: Directory(path.join(tempDir.path, 'attachments')),
        encryptionPasswordOrKey: masterKey,
      );

      final restoreDbDir = Directory(path.join(tempDir.path, 'restore_master_db'));
      final restoreBaseDir = Directory(path.join(tempDir.path, 'restore_master_base'));

      await BackupEncryptionService.importLocalBackupFromFile(
        backupFile: exportedFile,
        dbDirectoryPath: restoreDbDir.path,
        localBasePath: restoreBaseDir.path,
        encryptionPasswordOrKey: masterKey,
      );

      final restoredDb = File(path.join(restoreDbDir.path, 'opencloudhealth.db'));
      expect(restoredDb.existsSync(), isTrue);
      expect(restoredDb.readAsStringSync(), 'MOCK_SQLITE_DATABASE_DATA_TEST_12345');
    });
  });
}
