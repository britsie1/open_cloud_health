import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/profile_share_config.dart';
import 'package:open_cloud_health/models/profile_share_models.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/repositories/allergies_repository.dart';
import 'package:open_cloud_health/repositories/checkups_repository.dart';
import 'package:open_cloud_health/repositories/emergency_repository.dart';
import 'package:open_cloud_health/repositories/history_repository.dart';
import 'package:open_cloud_health/repositories/insurance_repository.dart';
import 'package:open_cloud_health/repositories/medications_repository.dart';
import 'package:open_cloud_health/repositories/period_repository.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/repositories/shared_profiles_repository.dart';
import 'package:open_cloud_health/repositories/vitals_repository.dart';
import 'package:open_cloud_health/services/backup_encryption_service.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/providers/active_shares_provider.dart';
import 'package:open_cloud_health/storage/google_auth_client.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';

enum SyncStatus { success, revoked, networkError, decryptionError }

class SyncResult {
  final SyncStatus status;
  final String message;
  final Profile? profile;

  SyncResult({required this.status, required this.message, this.profile});

  factory SyncResult.success(Profile profile) =>
      SyncResult(status: SyncStatus.success, message: 'Profile updated successfully.', profile: profile);

  factory SyncResult.revoked() => SyncResult(
      status: SyncStatus.revoked,
      message: 'The owner has revoked sharing or deleted this profile.');

  factory SyncResult.error(String message, [SyncStatus status = SyncStatus.networkError]) =>
      SyncResult(status: status, message: message);
}

class ShareCreationResult {
  final ShareLinkPayload payload;
  final String driveFileId;
  final String shareLink;

  ShareCreationResult({
    required this.payload,
    required this.driveFileId,
    required this.shareLink,
  });
}

class ProfileSharingService {
  final Ref _ref;
  final GoogleSignIn _googleSignIn;

  ProfileSharingService(this._ref, {GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn.standard(scopes: [
              drive.DriveApi.driveAppdataScope,
              drive.DriveApi.driveFileScope,
            ]);

  SharedProfilesRepository get _sharedRepo => _ref.read(sharedProfilesRepositoryProvider);
  ProfilesRepository get _profilesRepo => _ref.read(profilesRepositoryProvider);
  FileService get _fileService => _ref.read(fileServiceProvider);
  SecureStorage get _secureStorage => _ref.read(secureStorageProvider);

  Future<drive.DriveApi?> _getDriveApi({bool interactive = true}) async {
    try {
      GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
      if (googleUser == null) {
        if (interactive) {
          googleUser = await _googleSignIn.signIn();
        } else {
          googleUser = await _googleSignIn.signInSilently();
        }
      }
      if (googleUser == null) return null;

      final headers = await googleUser.authHeaders;
      final client = GoogleAuthClient(headers);
      return drive.DriveApi(client);
    } catch (e) {
      debugPrint('Error getting Drive API for sharing: $e');
      return null;
    }
  }

  static const String _sharedFolderName = 'Open Cloud Health';

  Future<String> _getOrCreateShareFolder(drive.DriveApi driveApi) async {
    try {
      const query = "mimeType = 'application/vnd.google-apps.folder' and name = '$_sharedFolderName' and 'root' in parents and trashed = false";
      final fileList = await driveApi.files.list(
        q: query,
        $fields: 'files(id, name)',
      );
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id!;
      }

      final folder = drive.File()
        ..name = _sharedFolderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = ['root']
        ..description = 'Open Cloud Health encrypted shared profiles';
      final created = await driveApi.files.create(folder);
      return created.id!;
    } catch (e) {
      debugPrint('Error getting or creating shared folder: $e');
      return 'root';
    }
  }

  /// Exports, encrypts, and uploads a profile to Google Drive with public read permission.
  /// Returns the pairing payload and universal share link.
  Future<ShareCreationResult> createOrUpdateProfileShare({
    required String profileId,
    required ShareModuleOptions options,
    String? existingFileId,
    String? existingEncryptionKey,
  }) async {
    final driveApi = await _getDriveApi(interactive: true);
    if (driveApi == null) {
      throw const FormatException('Google Drive authorization required to share profile.');
    }

    final currentUser = _googleSignIn.currentUser;
    final sharedBy = currentUser != null
        ? '${currentUser.displayName ?? "User"} (${currentUser.email})'
        : 'Open Cloud Health User';

    final existingConfig = await _secureStorage.getActiveShareConfig(profileId);
    final targetFileId = existingFileId ?? existingConfig?.driveFileId;
    final encryptionKey = existingEncryptionKey ??
        existingConfig?.encryptionKey ??
        BackupEncryptionService.generateRecoveryKey();

    // 1. Gather all profile records based on options
    final profile = await _profilesRepo.getProfile(profileId);
    if (profile == null) {
      throw const FormatException('Profile not found.');
    }

    // Profile Photo
    String? imageBase64;
    final photoPath = await _fileService.getProfileImagePath(profileId);
    if (photoPath.isNotEmpty && File(photoPath).existsSync()) {
      try {
        final imageBytes = await File(photoPath).readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      } catch (_) {}
    }

    // Allergies
    final allergies = options.includeAllergies
        ? await _ref.read(allergiesRepositoryProvider).fetchAllergies(profileId)
        : <Allergy>[];

    // Medications + Logs
    final medBundles = <MedicationShareBundle>[];
    if (options.includeMedications) {
      final meds = await _ref.read(medicationsRepositoryProvider).fetchMedications(profileId);
      for (final m in meds) {
        final logs = await _ref.read(medicationsRepositoryProvider).fetchMedicationLogs(m.id);
        medBundles.add(MedicationShareBundle(medication: m, logs: logs));
      }
    }

    // Checkups + Logs
    final checkupBundles = <CheckupShareBundle>[];
    if (options.includeCheckups) {
      final checkups = await _ref.read(checkupsRepositoryProvider).fetchCheckups(profileId);
      for (final c in checkups) {
        final logs = await _ref.read(checkupsRepositoryProvider).fetchCheckupLogs(c.id);
        checkupBundles.add(CheckupShareBundle(checkup: c, logs: logs));
      }
    }

    // Period Cycles + Logs
    final periodBundles = <PeriodCycleShareBundle>[];
    if (options.includeFertility) {
      final cycles = await _ref.read(periodRepositoryProvider).fetchPeriodCycles(profileId);
      for (final cycle in cycles) {
        final logs = await _ref.read(periodRepositoryProvider).fetchPeriodLogs(cycle.id);
        periodBundles.add(PeriodCycleShareBundle(cycle: cycle, logs: logs));
      }
    }

    // Vitals
    final vitals = options.includeVitals
        ? await _ref.read(vitalsRepositoryProvider).fetchAllVitals(profileId)
        : <VitalLog>[];

    // History
    final historyEvents = options.includeHistory
        ? await _ref.read(historyRepositoryProvider).fetchHistory(profileId)
        : <HistoryEvent>[];

    // Emergency
    final emergencyContacts = options.includeEmergency
        ? await _ref.read(emergencyRepositoryProvider).fetchEmergencyContacts(profileId)
        : <EmergencyContact>[];

    final lockScreenSetting = options.includeEmergency
        ? await _ref.read(emergencyRepositoryProvider).getLockScreenSetting(profileId)
        : null;

    // Insurance
    final insurance = options.includeInsurance
        ? await _ref.read(insuranceRepositoryProvider).getInsurance(profileId)
        : null;

    // 2. Build Bundle
    final bundle = SharedProfileBundle(
      profile: profile,
      sharedBy: sharedBy,
      sharedAt: DateTime.now(),
      moduleOptions: options,
      profileImageBase64: imageBase64,
      allergies: allergies,
      medications: medBundles,
      checkups: checkupBundles,
      periodCycles: periodBundles,
      vitals: vitals,
      historyEvents: historyEvents,
      emergencyContacts: emergencyContacts,
      lockScreenSetting: lockScreenSetting,
      insurance: insurance,
    );

    // 3. Encrypt bundle with AES-256 (reusing deterministic key if already shared)
    final bundleJsonBytes = utf8.encode(bundle.encodeToJsonString());
    final encryptedBytes = BackupEncryptionService.encryptBundle(bundleJsonBytes, encryptionKey);

    // 4. Upload to Google Drive inside Open Cloud Health folder
    final fileName = 'och_share_${profile.id.replaceAll("-", "").substring(0, 8)}.ochprofile';
    final tempDir = await getTemporaryDirectory();
    final tempEncFile = File(path.join(tempDir.path, fileName));
    await tempEncFile.writeAsBytes(encryptedBytes, flush: true);

    String fileId;
    try {
      if (targetFileId != null && targetFileId.isNotEmpty) {
        try {
          final uploadMedia = drive.Media(tempEncFile.openRead(), await tempEncFile.length());
          final updateFile = drive.File()
            ..name = fileName
            ..modifiedTime = DateTime.now().toUtc();
          final updated = await driveApi.files.update(updateFile, targetFileId, uploadMedia: uploadMedia);
          fileId = updated.id ?? targetFileId;
        } catch (e) {
          debugPrint('Could not update existing file, creating new one: $e');
          final folderId = await _getOrCreateShareFolder(driveApi);
          final retryUploadMedia = drive.Media(tempEncFile.openRead(), await tempEncFile.length());
          final driveFile = drive.File()
            ..name = fileName
            ..parents = [folderId]
            ..mimeType = 'application/octet-stream'
            ..modifiedTime = DateTime.now().toUtc();
          final created = await driveApi.files.create(driveFile, uploadMedia: retryUploadMedia);
          fileId = created.id!;
        }
      } else {
        final folderId = await _getOrCreateShareFolder(driveApi);
        final uploadMedia = drive.Media(tempEncFile.openRead(), await tempEncFile.length());
        final driveFile = drive.File()
          ..name = fileName
          ..parents = [folderId]
          ..mimeType = 'application/octet-stream'
          ..modifiedTime = DateTime.now().toUtc();
        final created = await driveApi.files.create(driveFile, uploadMedia: uploadMedia);
        fileId = created.id!;
      }
    } finally {
      if (await tempEncFile.exists()) {
        await tempEncFile.delete();
      }
    }

    // 5. Grant public read permission ("Anyone with link can read")
    try {
      final permission = drive.Permission()
        ..type = 'anyone'
        ..role = 'reader';
      await driveApi.permissions.create(permission, fileId);
    } catch (e) {
      debugPrint('Permission setting note: $e');
    }

    // 6. Save active share configuration locally for auto-sync & management
    final now = DateTime.now();
    final activeConfig = ActiveShareConfig(
      profileId: profileId,
      driveFileId: fileId,
      encryptionKey: encryptionKey,
      options: options,
      createdAt: existingConfig?.createdAt ?? now,
      lastSyncedAt: now,
      sharedBy: sharedBy,
      profileName: '${profile.name} ${profile.surname}',
    );
    await _secureStorage.saveActiveShareConfig(activeConfig);
    _ref.invalidate(activeShareConfigsProvider);

    // 7. Build Universal Link & Payload
    final payload = ShareLinkPayload(
      fileId: fileId,
      key: encryptionKey,
      profileName: '${profile.name} ${profile.surname}',
      sharedBy: sharedBy,
    );

    return ShareCreationResult(
      payload: payload,
      driveFileId: fileId,
      shareLink: payload.toUniversalUriString(),
    );
  }

  /// Revokes a shared profile by deleting the file from Google Drive and clearing local active config.
  Future<bool> revokeProfileShare(String fileId, {String? profileId}) async {
    try {
      final driveApi = await _getDriveApi(interactive: true);
      if (driveApi == null) return false;
      await driveApi.files.delete(fileId);
      debugPrint('Successfully deleted shared file from Drive: $fileId');

      if (profileId != null) {
        await _secureStorage.deleteActiveShareConfig(profileId);
      } else {
        final allConfigs = await _secureStorage.getAllActiveShareConfigs();
        for (final c in allConfigs) {
          if (c.driveFileId == fileId) {
            await _secureStorage.deleteActiveShareConfig(c.profileId);
          }
        }
      }
      _ref.invalidate(activeShareConfigsProvider);
      return true;
    } catch (e) {
      debugPrint('Error revoking profile share on Drive: $e');
      return false;
    }
  }

  /// Evaluates and runs automated background share syncs for all active shared profiles.
  /// Returns the number of profiles updated.
  Future<int> performScheduledShareSyncsIfDue({
    bool enforceIdleHours = true,
    DateTime? now,
  }) async {
    try {
      final frequency = await _secureStorage.getShareSyncFrequency();
      if (!frequency.isAutomated) {
        debugPrint('Share sync frequency is ${frequency.name}, skipping automated sync.');
        return 0;
      }

      final activeConfigs = await _secureStorage.getAllActiveShareConfigs();
      if (activeConfigs.isEmpty) {
        return 0;
      }

      final driveApi = await _getDriveApi(interactive: false);
      if (driveApi == null) {
        debugPrint('Google Drive not connected for background share sync.');
        return 0;
      }

      int updatedCount = 0;
      final currentTime = now ?? DateTime.now();

      for (final config in activeConfigs) {
        final isDue = frequency.isDue(
          lastSync: config.lastSyncedAt,
          now: currentTime,
          enforceIdleHours: enforceIdleHours,
        );

        if (!isDue) {
          debugPrint('Profile ${config.profileId} (${config.profileName}) not due for share sync yet.');
          continue;
        }

        try {
          debugPrint('Auto-syncing shared profile ${config.profileId} (${config.profileName})...');
          await createOrUpdateProfileShare(
            profileId: config.profileId,
            options: config.options,
            existingFileId: config.driveFileId,
            existingEncryptionKey: config.encryptionKey,
          );
          updatedCount++;
        } catch (e) {
          debugPrint('Error auto-syncing shared profile ${config.profileId}: $e');
        }
      }

      return updatedCount;
    } catch (e) {
      debugPrint('Error in performScheduledShareSyncsIfDue: $e');
      return 0;
    }
  }

  /// Downloads raw bytes of a shared file from Google Drive via direct download URL.
  Future<Uint8List?> _downloadSharedBytes(String fileId) async {
    try {
      // Primary attempt: standard anonymous Google Drive stream
      final url = 'https://drive.google.com/uc?export=download&id=$fileId';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final bodyBytes = response.bodyBytes;
        // Verify it's not an HTML error / login redirect page
        if (bodyBytes.length > 10) {
          final headerCheck = String.fromCharCodes(bodyBytes.sublist(0, 10));
          if (headerCheck == BackupEncryptionService.header) {
            return bodyBytes;
          }
        }
      } else if (response.statusCode == 404 || response.statusCode == 403) {
        debugPrint('File not accessible (status: ${response.statusCode})');
        return null;
      }

      // Secondary attempt: via authenticated Drive API if user is signed into Google
      final driveApi = await _getDriveApi(interactive: false);
      if (driveApi != null) {
        final media = await driveApi.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;
        final builder = BytesBuilder();
        await for (final chunk in media.stream) {
          builder.add(chunk);
        }
        return builder.toBytes();
      }
    } catch (e) {
      debugPrint('Error downloading shared file $fileId: $e');
    }
    return null;
  }

  /// Imports a shared profile on the receiver device using the QR payload or link.
  Future<Profile> importSharedProfile(ShareLinkPayload payload) async {
    final encryptedBytes = await _downloadSharedBytes(payload.fileId);
    if (encryptedBytes == null || encryptedBytes.isEmpty) {
      throw const FormatException('Could not access or download the shared profile. Access may have been revoked.');
    }

    List<int> decryptedBytes;
    try {
      decryptedBytes = BackupEncryptionService.decryptBundle(encryptedBytes, payload.key);
    } catch (e) {
      throw const FormatException('Decryption failed. The encryption key or PIN is incorrect.');
    }

    final jsonStr = utf8.decode(decryptedBytes);
    final bundle = SharedProfileBundle.decodeFromJsonString(jsonStr);

    await _sharedRepo.saveSharedProfileBundle(
      bundle,
      fileId: payload.fileId,
      encryptionKey: payload.key,
    );

    return bundle.profile;
  }

  /// Syncs an existing shared profile to fetch any new updates from the owner.
  Future<SyncResult> syncSharedProfile(String profileId) async {
    final meta = await _sharedRepo.getSharedProfileMeta(profileId);
    if (meta == null) {
      return SyncResult.error('Shared profile metadata not found.');
    }

    final encryptedBytes = await _downloadSharedBytes(meta.fileId);
    if (encryptedBytes == null) {
      return SyncResult.revoked();
    }

    try {
      final decryptedBytes = BackupEncryptionService.decryptBundle(encryptedBytes, meta.encryptionKey);
      final jsonStr = utf8.decode(decryptedBytes);
      final bundle = SharedProfileBundle.decodeFromJsonString(jsonStr);

      await _sharedRepo.saveSharedProfileBundle(
        bundle,
        fileId: meta.fileId,
        encryptionKey: meta.encryptionKey,
      );

      return SyncResult.success(bundle.profile);
    } catch (e) {
      return SyncResult.error('Failed to decrypt update: $e', SyncStatus.decryptionError);
    }
  }
}

final profileSharingServiceProvider = Provider<ProfileSharingService>((ref) {
  return ProfileSharingService(ref);
});
