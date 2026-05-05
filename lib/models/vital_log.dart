import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum VitalType { bloodPressure, heartRate, weight, bloodSugar }

class VitalLog {
  VitalLog({
    required this.profileId,
    required this.type,
    required this.date,
    required this.value1,
    this.value2,
    required this.unit,
    this.note,
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String profileId;
  final VitalType type;
  final DateTime date;
  final double value1; // Systolic for BP, or the main value for others
  final double? value2; // Diastolic for BP, null for others
  final String unit; // e.g. 'mmHg', 'bpm', 'kg', 'mg/dL'
  final String? note;
}
