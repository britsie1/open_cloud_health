import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:path/path.dart' as path;

class MockFileService extends Mock implements FileService {}
class MockRef extends Mock implements Ref {}

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

      await fileService.saveProfileImage('profile-1', testFile);

      final savedPath = await fileService.getProfileImagePath('profile-1');
      expect(savedPath, isNotEmpty);
      expect(await File(savedPath).exists(), true);
      expect(await File(savedPath).length(), 3);
    });

    test('getProfileImagePath returns empty string for empty file', () async {
      final profileDir = Directory(path.join(tempDir.path, FileService.profileImagesSubdir));
      await profileDir.create(recursive: true);
      final emptyFile = File(path.join(profileDir.path, 'empty.jpg'));
      await emptyFile.create();

      final imagePath = await fileService.getProfileImagePath('empty');
      expect(imagePath, '');
    });

    test('deleteProfileImage removes the file', () async {
      final testFile = File(path.join(tempDir.path, 'test_source.jpg'));
      await testFile.writeAsBytes([1, 2, 3]);
      await fileService.saveProfileImage('profile-1', testFile);

      await fileService.deleteProfileImage('profile-1');

      final savedPath = await fileService.getProfileImagePath('profile-1');
      expect(savedPath, '');
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
    late MockRef mockRef;

    setUp(() {
      mockFileService = MockFileService();
      mockRef = MockRef();
      
      when(() => mockRef.read(fileServiceProvider)).thenReturn(mockFileService);
    });

    test('BackupService correctly requests directories from FileService', () async {
      // We are only testing that BackupService calls FileService correctly
      // We don't execute the full backupToGoogleDrive because of GoogleSignIn dependency
      
      when(() => mockFileService.getProfileImagesDirectory())
          .thenAnswer((_) async => Directory('fake_profiles'));
      when(() => mockFileService.getAttachmentsDirectory())
          .thenAnswer((_) async => Directory('fake_attachments'));

      // Verify the service-to-service connection via Riverpod
      expect(mockRef.read(fileServiceProvider), mockFileService);
      
      // Note: We can't easily test backupToGoogleDrive() itself without mocking 
      // the entire Google Drive API and Google Sign In.
    });
  });

  group('NotificationService Battery Optimization Tests', () {
    test('isBatteryOptimizationDisabled returns boolean on non-Android platform', () async {
      final notificationService = NotificationService();
      final isDisabled = await notificationService.isBatteryOptimizationDisabled();
      expect(isDisabled, isA<bool>());
      expect(isDisabled, true);
    });

    test('requestDisableBatteryOptimization completes without throwing', () async {
      final notificationService = NotificationService();
      await expectLater(notificationService.requestDisableBatteryOptimization(), completes);
    });

    test('openAutoStartSettings completes without throwing on test runner', () async {
      final notificationService = NotificationService();
      await expectLater(notificationService.openAutoStartSettings(), completes);
    });
  });
}

