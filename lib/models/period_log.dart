import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum FlowLevel { spotting, light, medium, heavy }
enum Mood { happy, calm, irritable, sad, anxious }
enum PhysicalSymptom { cramps, headache, bloating, breastTenderness }

class PeriodLog {
  PeriodLog({
    required this.cycleId,
    required this.date,
    this.flowLevel,
    this.moods = const [],
    this.physicalSymptoms = const [],
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String cycleId;
  final DateTime date;
  final FlowLevel? flowLevel;
  final List<Mood> moods;
  final List<PhysicalSymptom> physicalSymptoms;
}
