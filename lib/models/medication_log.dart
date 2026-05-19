import 'package:uuid/uuid.dart';

const uuid = Uuid();

class MedicationLog {
  MedicationLog({
    required this.medicationId,
    required this.timestamp,
    this.isTaken = true,
    this.dosage,
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String medicationId;
  final DateTime timestamp;
  final bool isTaken;
  final String? dosage;

  MedicationLog copyWith({
    String? id,
    String? medicationId,
    DateTime? timestamp,
    bool? isTaken,
    String? dosage,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      timestamp: timestamp ?? this.timestamp,
      isTaken: isTaken ?? this.isTaken,
      dosage: dosage ?? this.dosage,
    );
  }
}
