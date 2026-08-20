import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/services/profile_sharing_service.dart';

class BackupSchedulerService {
  final Ref _ref;
  Timer? _periodicTimer;

  BackupSchedulerService(this._ref);

  /// Initializes the background backup scheduler.
  /// Runs a due check immediately and starts a periodic heartbeat check.
  void initialize() {
    _periodicTimer?.cancel();

    // Run initial check after a short delay so app startup is fast
    Future.delayed(const Duration(seconds: 3), () {
      checkAndRunDueBackup();
    });

    // Check periodically every hour
    _periodicTimer = Timer.periodic(const Duration(hours: 1), (_) {
      checkAndRunDueBackup();
    });
  }

  /// Evaluates and runs scheduled backup and share syncs if due.
  Future<bool> checkAndRunDueBackup({bool enforceIdleHours = true}) async {
    bool backupSuccess = false;
    try {
      final backupService = _ref.read(backupServiceProvider);
      backupSuccess = await backupService.performScheduledBackupIfDue(
        enforceIdleHours: enforceIdleHours,
      );
    } catch (e) {
      debugPrint('BackupSchedulerService backup check error: $e');
    }

    try {
      final sharingService = _ref.read(profileSharingServiceProvider);
      final syncedCount = await sharingService.performScheduledShareSyncsIfDue(
        enforceIdleHours: enforceIdleHours,
      );
      if (syncedCount > 0) {
        debugPrint('BackupSchedulerService synced $syncedCount shared profile(s).');
      }
    } catch (e) {
      debugPrint('BackupSchedulerService share sync check error: $e');
    }

    return backupSuccess;
  }

  void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}

final backupSchedulerServiceProvider = Provider<BackupSchedulerService>((ref) {
  final service = BackupSchedulerService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
