import 'package:uuid/uuid.dart';

const uuid = Uuid();

class MedicationLog {
  MedicationLog({
    required this.medicationId,
    required this.timestamp,
    this.isTaken = true,
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String medicationId;
  final DateTime timestamp;
  final bool isTaken;
}
