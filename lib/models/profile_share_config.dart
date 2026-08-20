import 'dart:convert';
import 'package:open_cloud_health/models/profile_share_models.dart';

enum ShareSyncFrequency {
  manual,
  daily,
  weekly;

  String get displayName {
    switch (this) {
      case ShareSyncFrequency.manual:
        return 'Only when I update share';
      case ShareSyncFrequency.daily:
        return 'Daily (Idle Night Hours)';
      case ShareSyncFrequency.weekly:
        return 'Weekly';
    }
  }

  String get description {
    switch (this) {
      case ShareSyncFrequency.manual:
        return 'Shared profiles are only updated when you tap "Push Update".';
      case ShareSyncFrequency.daily:
        return 'Automatically updates shared records on Google Drive once a day.';
      case ShareSyncFrequency.weekly:
        return 'Automatically updates shared records on Google Drive once a week.';
    }
  }

  Duration? get interval {
    switch (this) {
      case ShareSyncFrequency.daily:
        return const Duration(days: 1);
      case ShareSyncFrequency.weekly:
        return const Duration(days: 7);
      case ShareSyncFrequency.manual:
        return null;
    }
  }

  bool get isAutomated =>
      this == ShareSyncFrequency.daily || this == ShareSyncFrequency.weekly;

  /// Returns true if a share sync is due given the last sync timestamp.
  bool isDue({
    DateTime? lastSync,
    DateTime? now,
    bool enforceIdleHours = true,
    int startIdleHour = 2,
    int endIdleHour = 5,
  }) {
    if (!isAutomated) return false;

    final currentTime = now ?? DateTime.now();
    final currentHour = currentTime.hour;
    final isIdleWindow = currentHour >= startIdleHour && currentHour < endIdleHour;

    if (lastSync == null) {
      return !enforceIdleHours || isIdleWindow;
    }

    final diff = currentTime.difference(lastSync);
    final targetInterval = interval!;

    if (diff < targetInterval) {
      return false;
    }

    if (diff >= targetInterval * 2) {
      return true;
    }

    if (!enforceIdleHours) {
      return true;
    }

    return isIdleWindow;
  }

  static ShareSyncFrequency fromString(String? value) {
    if (value == null) return ShareSyncFrequency.manual;
    switch (value.toLowerCase().trim()) {
      case 'daily':
        return ShareSyncFrequency.daily;
      case 'weekly':
        return ShareSyncFrequency.weekly;
      case 'manual':
      default:
        return ShareSyncFrequency.manual;
    }
  }
}

/// Represents the active share configuration stored on the sharer's device.
class ActiveShareConfig {
  final String profileId;
  final String driveFileId;
  final String encryptionKey;
  final ShareModuleOptions options;
  final DateTime createdAt;
  final DateTime lastSyncedAt;
  final String sharedBy;
  final String profileName;

  const ActiveShareConfig({
    required this.profileId,
    required this.driveFileId,
    required this.encryptionKey,
    required this.options,
    required this.createdAt,
    required this.lastSyncedAt,
    required this.sharedBy,
    required this.profileName,
  });

  ActiveShareConfig copyWith({
    String? profileId,
    String? driveFileId,
    String? encryptionKey,
    ShareModuleOptions? options,
    DateTime? createdAt,
    DateTime? lastSyncedAt,
    String? sharedBy,
    String? profileName,
  }) {
    return ActiveShareConfig(
      profileId: profileId ?? this.profileId,
      driveFileId: driveFileId ?? this.driveFileId,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      options: options ?? this.options,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      sharedBy: sharedBy ?? this.sharedBy,
      profileName: profileName ?? this.profileName,
    );
  }

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'driveFileId': driveFileId,
        'encryptionKey': encryptionKey,
        'options': options.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'lastSyncedAt': lastSyncedAt.toIso8601String(),
        'sharedBy': sharedBy,
        'profileName': profileName,
      };

  factory ActiveShareConfig.fromJson(Map<String, dynamic> json) =>
      ActiveShareConfig(
        profileId: json['profileId'] as String,
        driveFileId: json['driveFileId'] as String,
        encryptionKey: json['encryptionKey'] as String,
        options: ShareModuleOptions.fromJson(
            Map<String, dynamic>.from(json['options'] as Map)),
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastSyncedAt: DateTime.parse(json['lastSyncedAt'] as String),
        sharedBy: json['sharedBy'] as String? ?? 'Open Cloud Health User',
        profileName: json['profileName'] as String? ?? 'Profile',
      );

  String encodeToJsonString() => jsonEncode(toJson());

  static ActiveShareConfig? decodeFromJsonString(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return ActiveShareConfig.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
