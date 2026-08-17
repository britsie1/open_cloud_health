import 'package:open_cloud_health/utils/format_utils.dart';

/// Holds Google Drive storage quota, user details, and app backup metrics.
class GoogleStorageInfo {
  final int totalBytes;
  final int usedBytes;
  final int driveUsedBytes;
  final int trashUsedBytes;
  final int appBackupBytes;
  final String? userEmail;
  final String? displayName;
  final String? photoUrl;
  final String? lastBackupDateTime;

  const GoogleStorageInfo({
    required this.totalBytes,
    required this.usedBytes,
    this.driveUsedBytes = 0,
    this.trashUsedBytes = 0,
    this.appBackupBytes = 0,
    this.userEmail,
    this.displayName,
    this.photoUrl,
    this.lastBackupDateTime,
  });

  /// Indicates if Google quota is unlimited or unrestricted.
  bool get isUnlimited => totalBytes <= 0;

  /// Remaining available storage bytes in the user's Google Account.
  int get availableBytes {
    if (isUnlimited) return -1;
    final remaining = totalBytes - usedBytes;
    return remaining > 0 ? remaining : 0;
  }

  /// Usage fraction between 0.0 and 1.0 for progress indicators.
  double get usageFraction {
    if (isUnlimited || totalBytes <= 0) return 0.0;
    final fraction = usedBytes / totalBytes;
    return fraction.clamp(0.0, 1.0);
  }

  /// Formatted total storage (e.g. "15.0 GB" or "Unlimited").
  String get formattedTotal =>
      isUnlimited ? 'Unlimited' : FormatUtils.formatBytes(totalBytes);

  /// Formatted used storage (e.g. "4.5 GB").
  String get formattedUsed => FormatUtils.formatBytes(usedBytes);

  /// Formatted available storage (e.g. "10.5 GB" or "Unlimited").
  String get formattedAvailable =>
      isUnlimited ? 'Unlimited' : FormatUtils.formatBytes(availableBytes);

  /// Formatted size of medical data backed up to Google Drive (e.g. "3.2 MB").
  String get formattedAppBackup => FormatUtils.formatBytes(appBackupBytes);

  /// Creates a copy with optional updated fields.
  GoogleStorageInfo copyWith({
    int? totalBytes,
    int? usedBytes,
    int? driveUsedBytes,
    int? trashUsedBytes,
    int? appBackupBytes,
    String? userEmail,
    String? displayName,
    String? photoUrl,
    String? lastBackupDateTime,
  }) {
    return GoogleStorageInfo(
      totalBytes: totalBytes ?? this.totalBytes,
      usedBytes: usedBytes ?? this.usedBytes,
      driveUsedBytes: driveUsedBytes ?? this.driveUsedBytes,
      trashUsedBytes: trashUsedBytes ?? this.trashUsedBytes,
      appBackupBytes: appBackupBytes ?? this.appBackupBytes,
      userEmail: userEmail ?? this.userEmail,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      lastBackupDateTime: lastBackupDateTime ?? this.lastBackupDateTime,
    );
  }
}
