import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:open_cloud_health/models/backup_frequency.dart';
import 'package:open_cloud_health/models/profile_share_config.dart';

class SecureStorage {
  final storage = const FlutterSecureStorage();

  static const _lastProfileIdKey = 'lastProfileId';
  static const _e2eEnabledKey = 'e2e_backup_enabled';
  static const _e2ePasswordHashKey = 'e2e_password_hash';
  static const _e2eSaltKey = 'e2e_salt';
  static const _e2eRecoveryKey = 'e2e_recovery_key';
  static const _e2eCachedPassKey = 'e2e_cached_password';
  static const _backupFrequencyKey = 'backup_frequency';
  static const _backupWifiOnlyKey = 'backup_wifi_only';
  static const _lastAutoBackupTimeKey = 'last_auto_backup_time';
  static const _shareSyncFrequencyKey = 'share_sync_frequency';
  static const _shareSyncWifiOnlyKey = 'share_sync_wifi_only';
  static const _activeSharePrefix = 'active_share_config_';

  //Save Credentials
  Future saveCredentials(AccessToken token, String refreshToken) async {
    debugPrint(token.expiry.toIso8601String());
    await storage.write(key: "type", value: token.type);
    await storage.write(key: "data", value: token.data);
    await storage.write(key: "expiry", value: token.expiry.toString());
    await storage.write(key: "refreshToken", value: refreshToken);
  }

  //Get Saved Credentials
  Future<Map<String, dynamic>?> getCredentials() async {
    var result = await storage.readAll();
    if (result.isEmpty) return null;
    return result;
  }

  //Clear Saved Credentials
  Future clear() {
    return storage.deleteAll();
  }

  // Last Profile ID
  Future<void> saveLastProfileId(String id) async {
    await storage.write(key: _lastProfileIdKey, value: id);
  }

  Future<String?> getLastProfileId() async {
    return await storage.read(key: _lastProfileIdKey);
  }

  // End-to-End Encryption Settings
  Future<bool> isE2eBackupEnabled() async {
    final value = await storage.read(key: _e2eEnabledKey);
    return value == 'true';
  }

  Future<void> setE2eBackupEnabled(bool enabled) async {
    await storage.write(key: _e2eEnabledKey, value: enabled.toString());
  }

  Future<String?> getE2ePasswordHash() async {
    return await storage.read(key: _e2ePasswordHashKey);
  }

  Future<void> setE2ePasswordHash(String? hash) async {
    if (hash == null) {
      await storage.delete(key: _e2ePasswordHashKey);
    } else {
      await storage.write(key: _e2ePasswordHashKey, value: hash);
    }
  }

  Future<String?> getE2eSalt() async {
    return await storage.read(key: _e2eSaltKey);
  }

  Future<void> setE2eSalt(String? salt) async {
    if (salt == null) {
      await storage.delete(key: _e2eSaltKey);
    } else {
      await storage.write(key: _e2eSaltKey, value: salt);
    }
  }

  Future<String?> getE2eRecoveryKey() async {
    return await storage.read(key: _e2eRecoveryKey);
  }

  Future<void> setE2eRecoveryKey(String? recoveryKey) async {
    if (recoveryKey == null) {
      await storage.delete(key: _e2eRecoveryKey);
    } else {
      await storage.write(key: _e2eRecoveryKey, value: recoveryKey);
    }
  }

  Future<String?> getE2eCachedPassword() async {
    return await storage.read(key: _e2eCachedPassKey);
  }

  Future<void> setE2eCachedPassword(String? password) async {
    if (password == null) {
      await storage.delete(key: _e2eCachedPassKey);
    } else {
      await storage.write(key: _e2eCachedPassKey, value: password);
    }
  }

  Future<void> clearE2eSettings() async {
    await storage.delete(key: _e2eEnabledKey);
    await storage.delete(key: _e2ePasswordHashKey);
    await storage.delete(key: _e2eSaltKey);
    await storage.delete(key: _e2eRecoveryKey);
    await storage.delete(key: _e2eCachedPassKey);
  }

  // Backup Frequency & Scheduling Settings
  Future<BackupFrequency> getBackupFrequency() async {
    final value = await storage.read(key: _backupFrequencyKey);
    return BackupFrequency.fromString(value);
  }

  Future<void> setBackupFrequency(BackupFrequency frequency) async {
    await storage.write(key: _backupFrequencyKey, value: frequency.name);
  }

  Future<bool> getBackupWifiOnly() async {
    final value = await storage.read(key: _backupWifiOnlyKey);
    // Defaults to true (Wi-Fi only)
    return value != 'false';
  }

  Future<void> setBackupWifiOnly(bool wifiOnly) async {
    await storage.write(key: _backupWifiOnlyKey, value: wifiOnly.toString());
  }

  Future<DateTime?> getLastAutoBackupTime() async {
    final value = await storage.read(key: _lastAutoBackupTimeKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> setLastAutoBackupTime(DateTime dateTime) async {
    await storage.write(
      key: _lastAutoBackupTimeKey,
      value: dateTime.toIso8601String(),
    );
  }

  static const _localMasterKey = 'local_hardware_master_key';

  /// Retrieves the hardware-backed 256-bit AES master key, or auto-generates
  /// a cryptographically secure random 32-byte key if it doesn't exist yet.
  Future<String> getOrCreateLocalMasterKey() async {
    final existing = await storage.read(key: _localMasterKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    final keyHex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    await storage.write(key: _localMasterKey, value: keyHex);
    return keyHex;
  }

  static const _strictBiometricsOnlyKey = 'strict_biometrics_only';

  Future<bool> isStrictBiometricsOnly() async {
    final value = await storage.read(key: _strictBiometricsOnlyKey);
    return value == 'true';
  }

  Future<void> setStrictBiometricsOnly(bool enabled) async {
    await storage.write(key: _strictBiometricsOnlyKey, value: enabled.toString());
  }

  Future<String?> getLocalMasterKey() async {
    return await storage.read(key: _localMasterKey);
  }

  Future<void> setLocalMasterKey(String key) async {
    await storage.write(key: _localMasterKey, value: key);
  }

  Future<void> clearLocalMasterKey() async {
    await storage.delete(key: _localMasterKey);
  }

  // Profile Share Sync Frequency & Settings
  Future<ShareSyncFrequency> getShareSyncFrequency() async {
    final value = await storage.read(key: _shareSyncFrequencyKey);
    return ShareSyncFrequency.fromString(value);
  }

  Future<void> setShareSyncFrequency(ShareSyncFrequency frequency) async {
    await storage.write(key: _shareSyncFrequencyKey, value: frequency.name);
  }

  Future<bool> getShareSyncWifiOnly() async {
    final value = await storage.read(key: _shareSyncWifiOnlyKey);
    return value != 'false'; // Defaults to true
  }

  Future<void> setShareSyncWifiOnly(bool wifiOnly) async {
    await storage.write(key: _shareSyncWifiOnlyKey, value: wifiOnly.toString());
  }

  // Active Share Configurations (per profile)
  Future<void> saveActiveShareConfig(ActiveShareConfig config) async {
    await storage.write(
      key: '$_activeSharePrefix${config.profileId}',
      value: config.encodeToJsonString(),
    );
  }

  Future<ActiveShareConfig?> getActiveShareConfig(String profileId) async {
    final value = await storage.read(key: '$_activeSharePrefix$profileId');
    if (value == null) return null;
    return ActiveShareConfig.decodeFromJsonString(value);
  }

  Future<List<ActiveShareConfig>> getAllActiveShareConfigs() async {
    final allKeys = await storage.readAll();
    final configs = <ActiveShareConfig>[];
    for (final entry in allKeys.entries) {
      if (entry.key.startsWith(_activeSharePrefix)) {
        final config = ActiveShareConfig.decodeFromJsonString(entry.value);
        if (config != null) {
          configs.add(config);
        }
      }
    }
    return configs;
  }

  Future<void> deleteActiveShareConfig(String profileId) async {
    await storage.delete(key: '$_activeSharePrefix$profileId');
  }
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});