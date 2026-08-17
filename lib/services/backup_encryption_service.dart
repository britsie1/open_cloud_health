import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:pointycastle/export.dart' as pc;

/// Provides cryptographic primitives for End-to-End Encrypted Backups.
class BackupEncryptionService {
  static const String header = 'OCH_E2E_V1';
  static const int saltLength = 16;
  static const int ivLength = 16;
  static const int pbkdf2Iterations = 10000;
  static const int keyLength = 32; // 256 bits

  /// Generates a cryptographically secure 64-digit hex recovery key.
  static String generateRecoveryKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final hexString = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    // Format as 8 groups of 8 characters for readability: xxxxxxxx-xxxxxxxx-...
    final chunks = <String>[];
    for (var i = 0; i < hexString.length; i += 8) {
      chunks.add(hexString.substring(i, min(i + 8, hexString.length)));
    }
    return chunks.join('-');
  }

  /// Normalizes a recovery key or password by removing whitespace/dashes for comparison if hex.
  static String normalizeKey(String input) {
    return input.trim();
  }

  /// Generates random cryptographic salt of given length.
  static Uint8List generateSalt([int length = saltLength]) {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
  }

  /// Derives a 256-bit AES key from a password or recovery key using PBKDF2 with SHA-256.
  static Uint8List deriveKey(String password, Uint8List salt) {
    final cleanPass = normalizeKey(password);
    final derivator = pc.KeyDerivator('SHA-256/HMAC/PBKDF2');
    final params = pc.Pbkdf2Parameters(salt, pbkdf2Iterations, keyLength);
    derivator.init(params);
    return derivator.process(Uint8List.fromList(utf8.encode(cleanPass)));
  }

  /// Creates a SHA-256 verification hash of the password with salt.
  static String hashPassword(String password, Uint8List salt) {
    final cleanPass = normalizeKey(password);
    final saltedBytes = [...salt, ...utf8.encode(cleanPass)];
    return crypto.sha256.convert(saltedBytes).toString();
  }

  /// Verifies if a password matches a stored hash.
  static bool verifyPassword(String password, String storedHash, Uint8List salt) {
    final computedHash = hashPassword(password, salt);
    return computedHash == storedHash;
  }

  static const String innerMagic = 'OCH_PAYLOAD_V1';

  /// Encrypts raw ZIP data using AES-256-CBC with inner SHA-256 integrity digest.
  /// Result payload: `[HEADER (10 bytes)][SALT (16 bytes)][IV (16 bytes)][CIPHERTEXT]`
  static Uint8List encryptBundle(List<int> zipBytes, String password) {
    final salt = generateSalt();
    final derivedKeyBytes = deriveKey(password, salt);
    final iv = enc.IV.fromSecureRandom(ivLength);

    // Inner payload with magic token and SHA-256 checksum for guaranteed integrity verification
    final innerMagicBytes = utf8.encode(innerMagic);
    final digest = crypto.sha256.convert(zipBytes).bytes;
    final plainBytes = BytesBuilder(copy: false)
      ..add(innerMagicBytes)
      ..add(digest)
      ..add(zipBytes);

    final key = enc.Key(derivedKeyBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(plainBytes.toBytes(), iv: iv);

    final headerBytes = utf8.encode(header);
    final result = BytesBuilder(copy: false)
      ..add(headerBytes)
      ..add(salt)
      ..add(iv.bytes)
      ..add(encrypted.bytes);

    return result.toBytes();
  }

  /// Decrypts an encrypted bundle payload and verifies integrity.
  /// Throws [FormatException] if password is wrong or format is invalid.
  static List<int> decryptBundle(Uint8List encryptedPayload, String password) {
    final headerBytes = utf8.encode(header);
    if (encryptedPayload.length < headerBytes.length + saltLength + ivLength) {
      throw const FormatException('Encrypted backup payload is too short or invalid.');
    }

    // Verify magic header
    final payloadHeader = String.fromCharCodes(encryptedPayload.sublist(0, headerBytes.length));
    if (payloadHeader != header) {
      throw const FormatException('Invalid backup header. This is not a valid Open Cloud Health encrypted backup.');
    }

    int offset = headerBytes.length;
    final salt = encryptedPayload.sublist(offset, offset + saltLength);
    offset += saltLength;

    final ivBytes = encryptedPayload.sublist(offset, offset + ivLength);
    offset += ivLength;

    final cipherBytes = encryptedPayload.sublist(offset);

    final derivedKeyBytes = deriveKey(password, salt);
    final key = enc.Key(derivedKeyBytes);
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    List<int> decrypted;
    try {
      decrypted = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);
    } catch (e) {
      debugPrint('Decryption error: $e');
      throw const FormatException('Incorrect backup password or recovery key.');
    }

    // Verify inner magic and checksum
    final innerMagicBytes = utf8.encode(innerMagic);
    final expectedHeaderLength = innerMagicBytes.length + 32; // 32 bytes SHA-256

    if (decrypted.length < expectedHeaderLength) {
      throw const FormatException('Incorrect backup password or recovery key.');
    }

    final decryptedMagic = String.fromCharCodes(decrypted.sublist(0, innerMagicBytes.length));
    if (decryptedMagic != innerMagic) {
      throw const FormatException('Incorrect backup password or recovery key.');
    }

    final storedDigest = decrypted.sublist(innerMagicBytes.length, expectedHeaderLength);
    final payloadBytes = decrypted.sublist(expectedHeaderLength);
    final calculatedDigest = crypto.sha256.convert(payloadBytes).bytes;

    if (!listEquals(storedDigest, calculatedDigest)) {
      throw const FormatException('Integrity verification failed: Incorrect backup password or corrupt data.');
    }

    return payloadBytes;
  }

  /// Bundles local database file, profile images, and attachments into a ZIP archive.
  static List<int> createZipArchive({
    required File dbFile,
    Directory? profileImagesDir,
    Directory? attachmentsDir,
  }) {
    final archive = Archive();

    // 1. Add SQLite DB
    if (dbFile.existsSync()) {
      final dbBytes = dbFile.readAsBytesSync();
      archive.addFile(ArchiveFile('opencloudhealth.db', dbBytes.length, dbBytes));
    }

    // 2. Add Profile Images
    if (profileImagesDir != null && profileImagesDir.existsSync()) {
      final files = profileImagesDir.listSync(recursive: true);
      for (var f in files) {
        if (f is File) {
          final relativePath = path.relative(f.path, from: profileImagesDir.path);
          final bytes = f.readAsBytesSync();
          archive.addFile(ArchiveFile('profileImages/$relativePath', bytes.length, bytes));
        }
      }
    }

    // 3. Add Attachments
    if (attachmentsDir != null && attachmentsDir.existsSync()) {
      final files = attachmentsDir.listSync(recursive: true);
      for (var f in files) {
        if (f is File) {
          final relativePath = path.relative(f.path, from: attachmentsDir.path);
          final bytes = f.readAsBytesSync();
          archive.addFile(ArchiveFile('attachments/$relativePath', bytes.length, bytes));
        }
      }
    }

    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);
    return zipData ?? [];
  }

  /// Unpacks a ZIP archive into local database and files directories.
  static void unpackZipArchive({
    required List<int> zipBytes,
    required String dbDirectoryPath,
    required String localBasePath,
  }) {
    final decoder = ZipDecoder();
    final archive = decoder.decodeBytes(zipBytes);

    for (var file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        if (filename == 'opencloudhealth.db') {
          final targetDbFile = File(path.join(dbDirectoryPath, 'opencloudhealth.db'));
          if (!targetDbFile.parent.existsSync()) {
            targetDbFile.parent.createSync(recursive: true);
          }
          targetDbFile.writeAsBytesSync(data, flush: true);
        } else {
          final targetFile = File(path.join(localBasePath, filename));
          if (!targetFile.parent.existsSync()) {
            targetFile.parent.createSync(recursive: true);
          }
          targetFile.writeAsBytesSync(data, flush: true);
        }
      }
    }
  }

  /// Creates an encrypted .ochbackup file containing all database records, profile photos, and medical attachments.
  static Future<File> exportLocalBackupToFile({
    required File dbFile,
    required String targetFilePath,
    Directory? profileImagesDir,
    Directory? attachmentsDir,
    required String encryptionPasswordOrKey,
  }) async {
    final zipBytes = createZipArchive(
      dbFile: dbFile,
      profileImagesDir: profileImagesDir,
      attachmentsDir: attachmentsDir,
    );

    final encryptedBytes = encryptBundle(zipBytes, encryptionPasswordOrKey);

    final targetFile = File(targetFilePath);
    if (!targetFile.parent.existsSync()) {
      targetFile.parent.createSync(recursive: true);
    }
    await targetFile.writeAsBytes(encryptedBytes, flush: true);
    return targetFile;
  }

  /// Imports and restores an encrypted .ochbackup file.
  static Future<void> importLocalBackupFromFile({
    required File backupFile,
    required String dbDirectoryPath,
    required String localBasePath,
    required String encryptionPasswordOrKey,
  }) async {
    final encryptedBytes = await backupFile.readAsBytes();
    final zipBytes = decryptBundle(encryptedBytes, encryptionPasswordOrKey);

    unpackZipArchive(
      zipBytes: zipBytes,
      dbDirectoryPath: dbDirectoryPath,
      localBasePath: localBasePath,
    );
  }
}
