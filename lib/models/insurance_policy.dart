import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class InsurancePolicy {
  InsurancePolicy({
    required this.profileId,
    required this.provider,
    this.planName,
    required this.policyNumber,
    this.groupNumber,
    this.subscriberName,
    this.memberId,
    this.emergencyPhone,
    this.frontCardImagePath,
    this.backCardImagePath,
    this.notes,
    String? id,
  }) : id = id ?? _uuid.v4();

  final String id;
  final String profileId;
  final String provider; // e.g. "Discovery Health", "Blue Cross Blue Shield"
  final String? planName; // e.g. "Classic Comprehensive", "Gold PPO"
  final String policyNumber; // Policy / Membership #
  final String? groupNumber; // Group #
  final String? subscriberName; // Primary Insured / Main Member
  final String? memberId; // Member ID / Dependent Code
  final String? emergencyPhone; // Pre-authorization / 24hr Emergency Hotline
  final String? frontCardImagePath; // Front card photo path or filename
  final String? backCardImagePath; // Back card photo path or filename
  final String? notes;

  InsurancePolicy copyWith({
    String? id,
    String? profileId,
    String? provider,
    String? planName,
    String? policyNumber,
    String? groupNumber,
    String? subscriberName,
    String? memberId,
    String? emergencyPhone,
    String? frontCardImagePath,
    String? backCardImagePath,
    String? notes,
  }) {
    return InsurancePolicy(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      provider: provider ?? this.provider,
      planName: planName ?? this.planName,
      policyNumber: policyNumber ?? this.policyNumber,
      groupNumber: groupNumber ?? this.groupNumber,
      subscriberName: subscriberName ?? this.subscriberName,
      memberId: memberId ?? this.memberId,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      frontCardImagePath: frontCardImagePath ?? this.frontCardImagePath,
      backCardImagePath: backCardImagePath ?? this.backCardImagePath,
      notes: notes ?? this.notes,
    );
  }
}
