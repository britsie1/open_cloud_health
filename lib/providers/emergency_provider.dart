import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/repositories/emergency_repository.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/utils/result.dart';

class EmergencyContactsNotifier extends FamilyAsyncNotifier<List<EmergencyContact>, String> {
  EmergencyRepository get _repository => ref.read(emergencyRepositoryProvider);

  @override
  Future<List<EmergencyContact>> build(String arg) async {
    final sub = ref.watch(emergencyRepositoryProvider).watchEmergencyContacts(arg).listen((contacts) {
      state = AsyncValue.data(contacts);
    });
    ref.onDispose(sub.cancel);
    return _repository.getEmergencyContacts(arg);
  }

  Future<Result<void, Exception>> addContact(EmergencyContact contact) async {
    try {
      await _repository.addEmergencyContact(contact);
      await refreshContacts();
      // Sync emergency notification
      await ref.read(notificationServiceProvider).syncEmergencyNotification(arg);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> deleteContact(String id) async {
    try {
      await _repository.deleteEmergencyContact(id);
      await refreshContacts();
      // Sync emergency notification
      await ref.read(notificationServiceProvider).syncEmergencyNotification(arg);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<void> refreshContacts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getEmergencyContacts(arg));
  }
}

final emergencyContactsProvider =
    AsyncNotifierProvider.family<EmergencyContactsNotifier, List<EmergencyContact>, String>(
        EmergencyContactsNotifier.new);

class LockScreenSettingsNotifier extends FamilyAsyncNotifier<LockScreenSetting, String> {
  EmergencyRepository get _repository => ref.read(emergencyRepositoryProvider);

  @override
  Future<LockScreenSetting> build(String arg) async {
    final sub = ref.watch(emergencyRepositoryProvider).watchLockScreenSetting(arg).listen((setting) {
      state = AsyncValue.data(setting);
    });
    ref.onDispose(sub.cancel);
    return _repository.getLockScreenSetting(arg);
  }

  Future<Result<void, Exception>> updateSettings(LockScreenSetting setting) async {
    try {
      await _repository.saveLockScreenSetting(setting);
      state = AsyncValue.data(setting);
      // Sync emergency notification
      await ref.read(notificationServiceProvider).syncEmergencyNotification(arg);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}

final lockScreenSettingsProvider =
    AsyncNotifierProvider.family<LockScreenSettingsNotifier, LockScreenSetting, String>(
        LockScreenSettingsNotifier.new);

class PrimaryProfileIdNotifier extends AsyncNotifier<String?> {
  EmergencyRepository get _repository => ref.read(emergencyRepositoryProvider);

  @override
  Future<String?> build() async {
    return _repository.getPrimaryProfileId();
  }

  Future<void> setPrimaryProfileId(String? profileId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.setPrimaryProfileId(profileId);
      state = AsyncValue.data(profileId);
      // Sync emergency notification
      if (profileId != null) {
        await ref.read(notificationServiceProvider).syncEmergencyNotification(profileId);
      } else {
        await ref.read(notificationServiceProvider).syncEmergencyNotification('');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final primaryProfileIdProvider = AsyncNotifierProvider<PrimaryProfileIdNotifier, String?>(PrimaryProfileIdNotifier.new);
