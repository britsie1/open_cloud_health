import 'package:uuid/uuid.dart';

const uuid = Uuid();

class PeriodCycle {
  PeriodCycle({
    required this.profileId,
    required this.startDate,
    this.endDate,
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String profileId;
  final DateTime startDate;
  final DateTime? endDate;

  int? get cycleLength {
    if (endDate == null) return null;
    return endDate!.difference(startDate).inDays + 1; // Inclusive of start day
  }
}
