import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/checkup.dart';
import 'package:open_cloud_health/models/checkup_log.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/insurance_policy.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/profile_share_models.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:path/path.dart' as path;

/// Metadata stored alongside a shared profile bundle for syncing and management.
class StoredSharedProfileMeta {
  final String profileId;
  final String fileId;
  final String encryptionKey;
  final DateTime lastSyncedAt;
  final String sharedBy;

  StoredSharedProfileMeta({
    required this.profileId,
    required this.fileId,
    required this.encryptionKey,
    required this.lastSyncedAt,
    required this.sharedBy,
  });

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'fileId': fileId,
        'encryptionKey': encryptionKey,
        'lastSyncedAt': lastSyncedAt.toIso8601String(),
        'sharedBy': sharedBy,
      };

  factory StoredSharedProfileMeta.fromJson(Map<String, dynamic> json) {
    return StoredSharedProfileMeta(
      profileId: json['profileId'] as String,
      fileId: json['fileId'] as String,
      encryptionKey: json['encryptionKey'] as String,
      lastSyncedAt: DateTime.parse(json['lastSyncedAt'] as String),
      sharedBy: json['sharedBy'] as String? ?? 'Unknown',
    );
  }
}

/// Repository responsible for storing, reading, and managing shared read-only profiles.
/// Kept completely isolated in a dedicated directory so it is NEVER included in backups.
class SharedProfilesRepository {
  final FileService _fileService;

  SharedProfilesRepository(this._fileService);

  Future<Directory> _getSharedProfilesDir() async {
    final basePath = await _fileService.localPath;
    final dir = Directory(path.join(basePath, 'shared_profiles'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  File _getBundleFile(Directory dir, String profileId) {
    return File(path.join(dir.path, '$profileId.bundle.json'));
  }

  File _getMetaFile(Directory dir, String profileId) {
    return File(path.join(dir.path, '$profileId.meta.json'));
  }

  File _getImageFile(Directory dir, String profileId) {
    return File(path.join(dir.path, '$profileId.photo.jpg'));
  }

  /// Returns all active shared read-only profiles.
  Future<List<Profile>> getSharedProfiles() async {
    final dir = await _getSharedProfilesDir();
    final metaFiles = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.meta.json'));

    final profiles = <Profile>[];
    for (final metaFile in metaFiles) {
      try {
        final metaContent = metaFile.readAsStringSync();
        final meta = StoredSharedProfileMeta.fromJson(jsonDecode(metaContent) as Map<String, dynamic>);
        final bundle = await getSharedProfileBundle(meta.profileId);
        if (bundle != null) {
          final p = bundle.profile;
          profiles.add(Profile(
            id: p.id,
            name: p.name,
            middleNames: p.middleNames,
            surname: p.surname,
            dateOfBirth: p.dateOfBirth,
            gender: p.gender,
            bloodType: p.bloodType,
            isOrganDonor: p.isOrganDonor,
            trackOvulation: p.trackOvulation,
            isArchived: false,
            chronicConditions: p.chronicConditions,
            isShared: true,
            isReadOnly: true,
            sharedBy: meta.sharedBy,
            lastSyncedAt: meta.lastSyncedAt,
            shareFileId: meta.fileId,
            shareEncryptionKey: meta.encryptionKey,
          ));
        }
      } catch (e) {
        debugPrint('Error loading shared profile from ${metaFile.path}: $e');
      }
    }
    return profiles;
  }

  /// Checks if a profile ID is a shared read-only profile.
  Future<bool> isSharedProfile(String profileId) async {
    final dir = await _getSharedProfilesDir();
    return _getMetaFile(dir, profileId).existsSync();
  }

  /// Retrieves the full bundle for a shared profile.
  Future<SharedProfileBundle?> getSharedProfileBundle(String profileId) async {
    try {
      final dir = await _getSharedProfilesDir();
      final bundleFile = _getBundleFile(dir, profileId);
      if (!bundleFile.existsSync()) return null;
      final jsonStr = bundleFile.readAsStringSync();
      return SharedProfileBundle.decodeFromJsonString(jsonStr);
    } catch (e) {
      debugPrint('Error reading shared profile bundle for $profileId: $e');
      return null;
    }
  }

  /// Retrieves sync metadata for a shared profile.
  Future<StoredSharedProfileMeta?> getSharedProfileMeta(String profileId) async {
    try {
      final dir = await _getSharedProfilesDir();
      final metaFile = _getMetaFile(dir, profileId);
      if (!metaFile.existsSync()) return null;
      return StoredSharedProfileMeta.fromJson(jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error reading shared profile meta for $profileId: $e');
      return null;
    }
  }

  /// Saves or updates a shared profile bundle and its metadata.
  Future<void> saveSharedProfileBundle(
    SharedProfileBundle bundle, {
    required String fileId,
    required String encryptionKey,
  }) async {
    final dir = await _getSharedProfilesDir();
    final profileId = bundle.profile.id;

    // 1. Save bundle
    final bundleFile = _getBundleFile(dir, profileId);
    await bundleFile.writeAsString(bundle.encodeToJsonString(), flush: true);

    // 2. Save metadata
    final meta = StoredSharedProfileMeta(
      profileId: profileId,
      fileId: fileId,
      encryptionKey: encryptionKey,
      lastSyncedAt: DateTime.now(),
      sharedBy: bundle.sharedBy,
    );
    final metaFile = _getMetaFile(dir, profileId);
    await metaFile.writeAsString(jsonEncode(meta.toJson()), flush: true);

    // 3. Save profile image if present
    if (bundle.profileImageBase64 != null && bundle.profileImageBase64!.isNotEmpty) {
      try {
        final imageBytes = base64Decode(bundle.profileImageBase64!);
        final imgFile = _getImageFile(dir, profileId);
        await imgFile.writeAsBytes(imageBytes, flush: true);
      } catch (e) {
        debugPrint('Error writing shared profile photo: $e');
      }
    }
  }

  /// Removes a shared profile from the local device completely.
  Future<void> removeSharedProfile(String profileId) async {
    final dir = await _getSharedProfilesDir();
    final bundleFile = _getBundleFile(dir, profileId);
    final metaFile = _getMetaFile(dir, profileId);
    final imgFile = _getImageFile(dir, profileId);

    if (bundleFile.existsSync()) bundleFile.deleteSync();
    if (metaFile.existsSync()) metaFile.deleteSync();
    if (imgFile.existsSync()) imgFile.deleteSync();
  }

  /// Returns the cached photo path if available.
  Future<String> getSharedProfileImagePath(String profileId) async {
    final dir = await _getSharedProfilesDir();
    final imgFile = _getImageFile(dir, profileId);
    if (imgFile.existsSync()) {
      return imgFile.path;
    }
    return '';
  }

  // --- Granular Query Methods for Shared Profiles ---

  Future<List<Allergy>> getAllergies(String profileId) async {
    final bundle = await getSharedProfileBundle(profileId);
    return bundle?.allergies ?? [];
  }

  Future<List<Medication>> getMedications(String profileId) async {
    final bundle = await getSharedProfileBundle(profileId);
    return bundle?.medications.map((m) => m.medication).toList() ?? [];
  }

  Future<List<MedicationLog>> getMedicationLogs(String profileId, String medicationId) async {
    final bundle = await getSharedProfileBundle(profileId);
    if (bundle == null) return [];
    for (final m in bundle.medications) {
      if (m.medication.id == medicationId) {
        return m.logs;
      }
    }
    return [];
  }

  Future<List<Checkup>> getCheckups(String profileId) async {
    final bundle = await getSharedProfileBundle(profileId);
    return bundle?.checkups.map((c) => c.checkup).toList() ?? [];
  }

  Future<List<CheckupLog>> getCheckupLogs(String checkupId) async {
    final dir = await _getSharedProfilesDir();
    final metaFiles = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.meta.json'));
    for (final metaFile in metaFiles) {
      try {
        final meta = StoredSharedProfileMeta.fromJson(jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>);
        final bundle = await getSharedProfileBundle(meta.profileId);
        if (bundle != null) {
          for (final c in bundle.checkups) {
            if (c.checkup.id == checkupId) {
              return c.logs;
            }
          }
        }
      } catch (_) {}
    }
    return [];
  }

  Future<List<VitalLog>> getVitals(String profileId, {VitalType? type}) async {
    final bundle = await getSharedProfileBundle(profileId);
    if (bundle == null) return [];
    if (type == null) return bundle.vitals;
    return bundle.vitals.where((v) => v.type == type).toList();
  }

  Future<List<HistoryEvent>> getHistoryEvents(String profileId) async {
    final bundle = await getSharedProfileBundle(profileId);
    return bundle?.historyEvents ?? [];
  }

  Future<List<EmergencyContact>> getEmergencyContacts(String profileId) async {
    final bundle = await getSharedProfileBundle(profileId);
    return bundle?.emergencyContacts ?? [];
  }

  Future<LockScreenSetting?> getLockScreenSetting(String profileId) async {
    final bundle = await getSharedProfileBundle(profileId);
    return bundle?.lockScreenSetting;
  }

  Future<InsurancePolicy?> getInsurance(String profileId) async {
    final bundle = await getSharedProfileBundle(profileId);
    return bundle?.insurance;
  }

  Future<List<PeriodCycle>> getPeriodCycles(String profileId) async {
    final bundle = await getSharedProfileBundle(profileId);
    return bundle?.periodCycles.map((p) => p.cycle).toList() ?? [];
  }

  Future<List<PeriodLog>> getPeriodLogs(String cycleId) async {
    final dir = await _getSharedProfilesDir();
    final metaFiles = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.meta.json'));
    for (final metaFile in metaFiles) {
      try {
        final meta = StoredSharedProfileMeta.fromJson(jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>);
        final bundle = await getSharedProfileBundle(meta.profileId);
        if (bundle != null) {
          for (final p in bundle.periodCycles) {
            if (p.cycle.id == cycleId) {
              return p.logs;
            }
          }
        }
      } catch (_) {}
    }
    return [];
  }
}

final sharedProfilesRepositoryProvider = Provider<SharedProfilesRepository>((ref) {
  final fileService = ref.watch(fileServiceProvider);
  return SharedProfilesRepository(fileService);
});
