import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/checkup.dart';
import 'package:open_cloud_health/models/checkup_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/repositories/checkups_repository.dart';
import 'package:open_cloud_health/utils/result.dart';
import 'package:open_cloud_health/utils/standard_checkups.dart';

enum CheckupStatus {
  dueNow,
  upcoming,
}

class CheckupWithStatus {
  final Checkup checkup;
  final CheckupLog? latestLog;
  final CheckupStatus status;
  final DateTime? nextDueDate;

  CheckupWithStatus({
    required this.checkup,
    this.latestLog,
    required this.status,
    this.nextDueDate,
  });

  bool get isOverdue => status == CheckupStatus.dueNow;
}

class CheckupsNotifier extends FamilyAsyncNotifier<List<CheckupWithStatus>, String> {
  CheckupsRepository get _repository => ref.read(checkupsRepositoryProvider);

  @override
  Future<List<CheckupWithStatus>> build(String arg) async {
    // 1. Get the profile
    final profiles = ref.watch(profilesProvider).value;
    if (profiles == null) return [];
    
    final profile = profiles.firstWhere((p) => p.id == arg, orElse: () => throw Exception('Profile not found'));

    // 2. Sync standard checkups if missing
    await _syncStandardCheckups(profile);

    // 3. Load all checkups and their statuses
    return _loadCheckupsWithStatus();
  }

  Future<void> _syncStandardCheckups(Profile profile) async {
    final existingCheckups = await _repository.loadCheckups(profile.id);
    
    // 1. Remove standard checkups that no longer apply
    for (final checkup in existingCheckups) {
      final templateIndex = standardCheckups.indexWhere((t) => t.name == checkup.name);
      if (templateIndex != -1) {
        final template = standardCheckups[templateIndex];
        if (!template.appliesTo(profile)) {
          await _repository.deleteCheckup(checkup.id);
        }
      }
    }

    // Load remaining existing checkups after deletion
    final remainingCheckups = await _repository.loadCheckups(profile.id);
    final remainingNames = remainingCheckups.map((c) => c.name).toSet();

    // 2. Add standard checkups that now apply
    for (final template in standardCheckups) {
      if (template.appliesTo(profile) && !remainingNames.contains(template.name)) {
        final newCheckup = Checkup(
          profileId: profile.id,
          name: template.name,
          frequencyInMonths: template.frequencyInMonths,
          iconName: template.iconName,
        );
        await _repository.addCheckup(newCheckup);
      }
    }
  }

  Future<List<CheckupWithStatus>> _loadCheckupsWithStatus() async {
    final checkups = await _repository.loadCheckups(arg);
    final List<CheckupWithStatus> result = [];
    final now = DateTime.now();
    // Normalize 'now' to start of day for comparison
    final today = DateTime(now.year, now.month, now.day);

    for (final checkup in checkups) {
      final latestLog = await _repository.getLatestLogForCheckup(checkup.id);
      
      CheckupStatus status;
      DateTime? nextDueDate;

      if (latestLog == null) {
        status = CheckupStatus.dueNow;
      } else {
        // Calculate next due date
        nextDueDate = DateTime(
          latestLog.dateCompleted.year,
          latestLog.dateCompleted.month + checkup.frequencyInMonths,
          latestLog.dateCompleted.day,
        );

        if (nextDueDate.isBefore(today) || nextDueDate.isAtSameMomentAs(today)) {
          status = CheckupStatus.dueNow;
        } else {
          status = CheckupStatus.upcoming;
        }
      }

      result.add(CheckupWithStatus(
        checkup: checkup,
        latestLog: latestLog,
        status: status,
        nextDueDate: nextDueDate,
      ));
    }
    
    // Sort: Due Now first, then by nextDueDate ascending
    result.sort((a, b) {
      if (a.status == CheckupStatus.dueNow && b.status == CheckupStatus.upcoming) {
        return -1;
      }
      if (a.status == CheckupStatus.upcoming && b.status == CheckupStatus.dueNow) {
        return 1;
      }
      
      if (a.nextDueDate != null && b.nextDueDate != null) {
        return a.nextDueDate!.compareTo(b.nextDueDate!);
      }
      
      return 0;
    });

    return result;
  }

  Future<Result<void, Exception>> logCheckup(String checkupId, DateTime dateCompleted) async {
    try {
      final log = CheckupLog(
        checkupId: checkupId,
        dateCompleted: dateCompleted,
      );
      await _repository.addCheckupLog(log);
      
      // Refresh state
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _loadCheckupsWithStatus());
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> addCustomCheckup(String name, int frequencyInMonths) async {
    try {
      final checkup = Checkup(
        profileId: arg,
        name: name,
        frequencyInMonths: frequencyInMonths,
        iconName: 'event', // default icon
      );
      await _repository.addCheckup(checkup);
      
      // Refresh state
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _loadCheckupsWithStatus());
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> deleteCheckup(String id) async {
     try {
      await _repository.deleteCheckup(id);
      
      // Refresh state
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _loadCheckupsWithStatus());
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}

final checkupsProvider =
    AsyncNotifierProvider.family<CheckupsNotifier, List<CheckupWithStatus>, String>(
        CheckupsNotifier.new);
