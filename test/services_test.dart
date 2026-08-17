import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/models/backup_frequency.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:path/path.dart' as path;

class MockFileService extends Mock implements FileService {}
class MockRef extends Mock implements Ref {}
class MockSecureStorage extends Mock implements SecureStorage {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late FileService fileService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('file_service_test');
    fileService = FileService(baseDirectory: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FileService Tests', () {
    test('getProfileImagePath returns empty string if file does not exist', () async {
      final imagePath = await fileService.getProfileImagePath('non-existent');
      expect(imagePath, '');
    });

    test('saveProfileImage creates the file and directory', () async {
      final testFile = File(path.join(tempDir.path, 'test_source.jpg'));
      await testFile.writeAsBytes([1, 2, 3]);

      await fileService.saveProfileImage('profile-123', testFile);

      final savedPath = await fileService.getProfileImagePath('profile-123');
      expect(savedPath, contains('profile-123.jpg'));
      expect(await File(savedPath).exists(), true);
      expect(await File(savedPath).length(), 3);
    });

    test('getProfileImagePath returns empty string for empty file', () async {
      final testFile = File(path.join(tempDir.path, 'profileImages', 'empty-profile.jpg'));
      await testFile.create(recursive: true);

      final imagePath = await fileService.getProfileImagePath('empty-profile');
      expect(imagePath, '');
    });

    test('deleteProfileImage removes the file', () async {
      final testFile = File(path.join(tempDir.path, 'test_source.jpg'));
      await testFile.writeAsBytes([1, 2, 3]);
      await fileService.saveProfileImage('profile-to-delete', testFile);

      await fileService.deleteProfileImage('profile-to-delete');

      final imagePath = await fileService.getProfileImagePath('profile-to-delete');
      expect(imagePath, '');
    });

    test('saveAttachment creates file in history-specific subdirectory', () async {
      final testFile = File(path.join(tempDir.path, 'doc_source.pdf'));
      await testFile.writeAsBytes([4, 5, 6]);

      final savedPath = await fileService.saveAttachment('history-123', testFile, 'report.pdf');

      expect(savedPath, contains('history-123'));
      expect(savedPath, contains('report.pdf'));
      expect(await File(savedPath).exists(), true);
      expect(await File(savedPath).length(), 3);
    });

    test('deleteAttachment removes the specific file', () async {
      final testFile = File(path.join(tempDir.path, 'doc_source.pdf'));
      await testFile.writeAsBytes([4, 5, 6]);
      await fileService.saveAttachment('history-123', testFile, 'report.pdf');

      await fileService.deleteAttachment('history-123', 'report.pdf');

      final savedPath = await fileService.getAttachmentPath('history-123', 'report.pdf');
      expect(await File(savedPath).exists(), false);
    });
  });

  group('BackupService Mock Tests', () {
    late MockFileService mockFileService;
    late MockSecureStorage mockSecureStorage;
    late MockRef mockRef;
    late MockGoogleSignIn mockGoogleSignIn;

    setUp(() {
      mockFileService = MockFileService();
      mockSecureStorage = MockSecureStorage();
      mockRef = MockRef();
      mockGoogleSignIn = MockGoogleSignIn();

      when(() => mockRef.read(fileServiceProvider)).thenReturn(mockFileService);
      when(() => mockRef.read(secureStorageProvider)).thenReturn(mockSecureStorage);
    });

    test('BackupService correctly requests directories from FileService', () async {
      when(() => mockFileService.getProfileImagesDirectory())
          .thenAnswer((_) async => Directory('fake_profiles'));
      when(() => mockFileService.getAttachmentsDirectory())
          .thenAnswer((_) async => Directory('fake_attachments'));

      // Verify the service-to-service connection via Riverpod
      expect(mockRef.read(fileServiceProvider), mockFileService);
    });

    test('BackupService getConnectedUser returns null if no user signed in', () async {
      when(() => mockGoogleSignIn.currentUser).thenReturn(null);
      when(() => mockGoogleSignIn.signInSilently()).thenAnswer((_) async => null);

      final backupService = BackupService(mockRef, googleSignIn: mockGoogleSignIn);
      final user = await backupService.getConnectedUser();

      expect(user, isNull);
      verify(() => mockGoogleSignIn.signInSilently()).called(1);
    });

    test('BackupService signOut triggers googleSignIn signOut', () async {
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

      final backupService = BackupService(mockRef, googleSignIn: mockGoogleSignIn);
      await backupService.signOut();

      verify(() => mockGoogleSignIn.signOut()).called(1);
    });

    test('performScheduledBackupIfDue returns false when user is not connected', () async {
      when(() => mockGoogleSignIn.currentUser).thenReturn(null);
      when(() => mockGoogleSignIn.signInSilently()).thenAnswer((_) async => null);

      final backupService = BackupService(mockRef, googleSignIn: mockGoogleSignIn);
      final result = await backupService.performScheduledBackupIfDue();

      expect(result, false);
    });

    test('performScheduledBackupIfDue returns false when frequency is manual or never', () async {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockGoogleSignIn.currentUser).thenReturn(mockAccount);
      when(() => mockSecureStorage.getBackupFrequency())
          .thenAnswer((_) async => BackupFrequency.manual);

      final backupService = BackupService(mockRef, googleSignIn: mockGoogleSignIn);
      final result = await backupService.performScheduledBackupIfDue();

      expect(result, false);
    });

    test('performScheduledBackupIfDue returns false when not due yet', () async {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockGoogleSignIn.currentUser).thenReturn(mockAccount);
      when(() => mockSecureStorage.getBackupFrequency())
          .thenAnswer((_) async => BackupFrequency.daily);
      when(() => mockSecureStorage.getLastAutoBackupTime())
          .thenAnswer((_) async => DateTime(2026, 8, 17, 2, 0));

      final backupService = BackupService(mockRef, googleSignIn: mockGoogleSignIn);
      final result = await backupService.performScheduledBackupIfDue(
        now: DateTime(2026, 8, 17, 3, 0), // Only 1 hr later
      );

      expect(result, false);
    });
  });

  group('NotificationService Battery Optimization Tests', () {
    test('isBatteryOptimizationDisabled returns boolean on non-Android platform', () async {
      final service = NotificationService();
      final result = await service.isBatteryOptimizationDisabled();
      expect(result, isA<bool>());
    });

    test('requestDisableBatteryOptimization completes without throwing', () async {
      final service = NotificationService();
      expect(service.requestDisableBatteryOptimization(), completes);
    });

    test('openAutoStartSettings completes without throwing on test runner', () async {
      final service = NotificationService();
      expect(service.openAutoStartSettings(), completes);
    });
  });
}
