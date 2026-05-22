import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();
final formatter = DateFormat('yyyy-MM-dd HH:mm');
final dateFormatterOnly = DateFormat('yyyy-MM-dd');

enum EventType {
  period,
  checkup,
  procedure,
  labTest,
  psychologistVisit,
  specialistConsultation,
  hospitalStay,
  therapy,
  vaccination,
  dentalTreatment,
  imaging,
  other,
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.period:
        return 'Period';
      case EventType.checkup:
        return 'Checkup';
      case EventType.procedure:
        return 'Procedure';
      case EventType.labTest:
        return 'Lab Test';
      case EventType.psychologistVisit:
        return 'Psychologist Visit';
      case EventType.specialistConsultation:
        return 'Specialist Visit';
      case EventType.hospitalStay:
        return 'Hospital / ER';
      case EventType.therapy:
        return 'Therapy Session';
      case EventType.vaccination:
        return 'Vaccination';
      case EventType.dentalTreatment:
        return 'Dental Treatment';
      case EventType.imaging:
        return 'Imaging Study';
      case EventType.other:
        return 'Other';
    }
  }
}

class HistoryEvent {
  HistoryEvent({
    required this.profileId,
    required this.title,
    required this.description,
    required this.date,
    this.eventType = EventType.other,
    this.hasTime = true,
    this.provider,
    this.facility,
    String? id,
    int? attachmentCount,
  }) : id = id ?? uuid.v4(), attachmentCount = attachmentCount ?? 0;

  final String id;
  final String profileId;
  final String title;
  final String description;
  final DateTime date;
  final EventType eventType;
  final bool hasTime;
  final String? provider;
  final String? facility;
  final int attachmentCount;

  String get formattedDate {
    if (hasTime) {
      return formatter.format(date);
    } else {
      return dateFormatterOnly.format(date);
    }
  }
}
