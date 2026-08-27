import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/insurance_policy.dart';
import 'package:open_cloud_health/repositories/shared_profiles_repository.dart';

class InsuranceRepository {
  final AppDatabase _db;
  final SharedProfilesRepository? _sharedRepo;

  InsuranceRepository(this._db, [this._sharedRepo]);

  InsurancePolicy _mapEntry(InsuranceEntry row) {
    return InsurancePolicy(
      id: row.id,
      profileId: row.profileId,
      provider: row.provider,
      planName: row.planName,
      policyNumber: row.policyNumber,
      groupNumber: row.groupNumber,
      subscriberName: row.subscriberName,
      memberId: row.memberId,
      emergencyPhone: row.emergencyPhone,
      frontCardImagePath: row.frontCardImage,
      backCardImagePath: row.backCardImage,
      notes: row.notes,
    );
  }

  Future<InsurancePolicy?> getInsurance(String profileId) async {
    if (_sharedRepo != null && await _sharedRepo.isSharedProfile(profileId)) {
      return _sharedRepo.getInsurance(profileId);
    }
    final query = _db.select(_db.insurance)..where((tbl) => tbl.profileId.equals(profileId));
    final data = await query.getSingleOrNull();
    return data != null ? _mapEntry(data) : null;
  }

  Stream<InsurancePolicy?> watchInsurance(String profileId) async* {
    if (_sharedRepo != null && await _sharedRepo.isSharedProfile(profileId)) {
      yield await _sharedRepo.getInsurance(profileId);
      return;
    }
    final query = _db.select(_db.insurance)..where((tbl) => tbl.profileId.equals(profileId));
    yield* query.watchSingleOrNull().map((data) => data != null ? _mapEntry(data) : null);
  }

  Future<void> saveInsurance(InsurancePolicy policy) async {
    await _db.into(_db.insurance).insertOnConflictUpdate(
      InsuranceEntry(
        id: policy.id,
        profileId: policy.profileId,
        provider: policy.provider,
        planName: policy.planName,
        policyNumber: policy.policyNumber,
        groupNumber: policy.groupNumber,
        subscriberName: policy.subscriberName,
        memberId: policy.memberId,
        emergencyPhone: policy.emergencyPhone,
        frontCardImage: policy.frontCardImagePath,
        backCardImage: policy.backCardImagePath,
        notes: policy.notes,
      ),
    );
  }

  Future<void> deleteInsurance(String id) async {
    await (_db.delete(_db.insurance)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> deleteInsuranceByProfileId(String profileId) async {
    await (_db.delete(_db.insurance)..where((tbl) => tbl.profileId.equals(profileId))).go();
  }
}

final insuranceRepositoryProvider = Provider<InsuranceRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sharedRepo = ref.watch(sharedProfilesRepositoryProvider);
  return InsuranceRepository(db, sharedRepo);
});
