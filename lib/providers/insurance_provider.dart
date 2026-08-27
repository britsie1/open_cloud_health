import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/insurance_policy.dart';
import 'package:open_cloud_health/repositories/insurance_repository.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/utils/result.dart';

class InsuranceNotifier extends FamilyAsyncNotifier<InsurancePolicy?, String> {
  InsuranceRepository get _repository => ref.read(insuranceRepositoryProvider);
  FileService get _fileService => ref.read(fileServiceProvider);

  @override
  Future<InsurancePolicy?> build(String arg) async {
    final sub = ref.watch(insuranceRepositoryProvider).watchInsurance(arg).listen((insurance) {
      state = AsyncValue.data(insurance);
    });
    ref.onDispose(sub.cancel);
    return _repository.getInsurance(arg);
  }

  Future<Result<void, Exception>> saveInsurance(InsurancePolicy policy) async {
    try {
      await _repository.saveInsurance(policy);
      await refreshInsurance();
      await ref.read(notificationServiceProvider).syncEmergencyNotification(arg);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> deleteInsurance(String id) async {
    try {
      await _repository.deleteInsurance(id);
      await _fileService.deleteInsuranceCardImages(arg);
      await refreshInsurance();
      await ref.read(notificationServiceProvider).syncEmergencyNotification(arg);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<String> saveCardImage(String side, File file) async {
    final path = await _fileService.saveInsuranceCardImage(arg, side, file);
    final current = state.value;
    if (current != null) {
      final updated = side == 'front'
          ? current.copyWith(frontCardImagePath: path)
          : current.copyWith(backCardImagePath: path);
      await _repository.saveInsurance(updated);
      await refreshInsurance();
    }
    return path;
  }

  Future<String> getCardImagePath(String side) async {
    return _fileService.getInsuranceCardPath(arg, side);
  }

  Future<void> refreshInsurance() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getInsurance(arg));
  }
}

final insuranceProvider =
    AsyncNotifierProvider.family<InsuranceNotifier, InsurancePolicy?, String>(
        InsuranceNotifier.new);
