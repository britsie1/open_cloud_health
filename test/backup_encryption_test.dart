import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/services/backup_encryption_service.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupEncryptionService Cryptography Tests', () {
    test('generateRecoveryKey returns formatted 64-hex-digit key', () {
      final key = BackupEncryptionService.generateRecoveryKey();
      expect(key, isNotEmpty);
      final rawHex = key.replaceAll('-', '');
      expect(rawHex.length, 64);
      expect(RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(rawHex), true);
    });

    test('generateSalt returns 16 random bytes', () {
      final salt1 = BackupEncryptionService.generateSalt();
      final salt2 = BackupEncryptionService.generateSalt();
      expect(salt1.length, 16);
      expect(salt2.length, 16);
      expect(salt1, isNot(equals(salt2)));
    });

    test('deriveKey returns 32-byte deterministic key for same password and salt', () {
      final salt = BackupEncryptionService.generateSalt();
      const password = 'MySecureMedicalPassword123!';

      final key1 = BackupEncryptionService.deriveKey(password, salt);
      final key2 = BackupEncryptionService.deriveKey(password, salt);

      expect(key1.length, 32);
      expect(key1, equals(key2));

      final keyDiffPass = BackupEncryptionService.deriveKey('DifferentPassword', salt);
      expect(key1, isNot(equals(keyDiffPass)));
    });

    test('hashPassword and verifyPassword correctly validate password', () {
      final salt = BackupEncryptionService.generateSalt();
      const password = 'CorrectPassword456';

      final hash = BackupEncryptionService.hashPassword(password, salt);
      expect(hash, isNotEmpty);

      expect(BackupEncryptionService.verifyPassword(password, hash, salt), true);
      expect(BackupEncryptionService.verifyPassword('WrongPassword', hash, salt), false);
    });

    test('encryptBundle and decryptBundle roundtrip data with correct password', () {
      const sampleData = 'Confidential patient records and medication logbook payload';
      final rawBytes = utf8.encode(sampleData);
      const password = 'PatientKey#2026';

      final encryptedPayload = BackupEncryptionService.encryptBundle(rawBytes, password);

      // Verify payload structure has header, salt, iv, and ciphertext
      expect(encryptedPayload.length, greaterThan(utf8.encode(BackupEncryptionService.header).length + 32));
      final headerString = String.fromCharCodes(encryptedPayload.sublist(0, BackupEncryptionService.header.length));
      expect(headerString, BackupEncryptionService.header);

      // Decrypt
      final decryptedBytes = BackupEncryptionService.decryptBundle(encryptedPayload, password);
      final decryptedString = utf8.decode(decryptedBytes);

      expect(decryptedString, sampleData);
    });

    test('decryptBundle throws FormatException with incorrect password', () {
      final rawBytes = utf8.encode('Top secret health data');
      final encryptedPayload = BackupEncryptionService.encryptBundle(rawBytes, 'RealPassword123');

      expect(
        () => BackupEncryptionService.decryptBundle(encryptedPayload, 'WrongPassword456'),
        throwsA(isA<FormatException>()),
      );
    });

    test('decryptBundle throws FormatException with invalid or short payload', () {
      expect(
        () => BackupEncryptionService.decryptBundle(Uint8List.fromList([1, 2, 3]), 'pass'),
        throwsA(isA<FormatException>()),
      );

      final invalidHeaderPayload = Uint8List.fromList([
        ...utf8.encode('WRONG_HDR!'),
        ...List<int>.filled(40, 0),
      ]);
      expect(
        () => BackupEncryptionService.decryptBundle(invalidHeaderPayload, 'pass'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('BackupEncryptionService ZIP Archive Bundling Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('zip_bundle_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('createZipArchive and unpackZipArchive roundtrip database and directory contents', () async {
      // 1. Setup sample db and files
      final dbFile = File(path.join(tempDir.path, 'opencloudhealth.db'));
      await dbFile.writeAsString('SQLITE DUMMY DATABASE CONTENT');

      final profileImagesDir = Directory(path.join(tempDir.path, 'profileImages'));
      await profileImagesDir.create(recursive: true);
      final profileImg = File(path.join(profileImagesDir.path, 'avatar.jpg'));
      await profileImg.writeAsBytes([10, 20, 30]);

      final attachmentsDir = Directory(path.join(tempDir.path, 'attachments', 'hist_1'));
      await attachmentsDir.create(recursive: true);
      final attachmentFile = File(path.join(attachmentsDir.path, 'lab_result.pdf'));
      await attachmentFile.writeAsBytes([40, 50, 60]);

      // 2. Create ZIP
      final zipBytes = BackupEncryptionService.createZipArchive(
        dbFile: dbFile,
        profileImagesDir: profileImagesDir,
        attachmentsDir: Directory(path.join(tempDir.path, 'attachments')),
      );

      expect(zipBytes, isNotEmpty);

      // 3. Encrypt and decrypt ZIP
      final encrypted = BackupEncryptionService.encryptBundle(zipBytes, 'ZipSecretKey');
      final decryptedZipBytes = BackupEncryptionService.decryptBundle(encrypted, 'ZipSecretKey');

      // 4. Unpack into a new destination directory
      final restoreDbDir = Directory(path.join(tempDir.path, 'restored_db'));
      final restoreBaseDir = Directory(path.join(tempDir.path, 'restored_base'));
      await restoreDbDir.create(recursive: true);
      await restoreBaseDir.create(recursive: true);

      BackupEncryptionService.unpackZipArchive(
        zipBytes: decryptedZipBytes,
        dbDirectoryPath: restoreDbDir.path,
        localBasePath: restoreBaseDir.path,
      );

      // 5. Verify restored files
      final restoredDbFile = File(path.join(restoreDbDir.path, 'opencloudhealth.db'));
      expect(await restoredDbFile.exists(), true);
      expect(await restoredDbFile.readAsString(), 'SQLITE DUMMY DATABASE CONTENT');

      final restoredImg = File(path.join(restoreBaseDir.path, 'profileImages', 'avatar.jpg'));
      expect(await restoredImg.exists(), true);
      expect(await restoredImg.readAsBytes(), [10, 20, 30]);

      final restoredAtt = File(path.join(restoreBaseDir.path, 'attachments', 'hist_1', 'lab_result.pdf'));
      expect(await restoredAtt.exists(), true);
      expect(await restoredAtt.readAsBytes(), [40, 50, 60]);
    });
  });
}
