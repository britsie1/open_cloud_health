import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/profile_share_config.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';

final activeShareConfigsProvider = FutureProvider<Map<String, ActiveShareConfig>>((ref) async {
  final secureStorage = ref.watch(secureStorageProvider);
  final configs = await secureStorage.getAllActiveShareConfigs();
  return {for (var c in configs) c.profileId: c};
});
