import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Medication {
  Medication({
    required this.profileId,
    required this.name,
    required this.dosage,
    TimeOfDay? timeOfDay,
    this.type = 'Other',
    this.notificationEnabled = false,
    this.alarmEnabled = false,
    this.isActive = true,
    List<int>? daysOfWeek,
    List<TimeOfDay>? timesOfDay,
    String? id,
  })  : id = id ?? uuid.v4(),
        daysOfWeek = daysOfWeek ?? const [1, 2, 3, 4, 5, 6, 7],
        timesOfDay = timesOfDay ?? (timeOfDay != null ? [timeOfDay] : const [TimeOfDay(hour: 8, minute: 0)]),
        timeOfDay = timeOfDay ?? (timesOfDay != null && timesOfDay.isNotEmpty ? timesOfDay.first : const TimeOfDay(hour: 8, minute: 0));

  final String id;
  final String profileId;
  final String name;
  final String dosage;
  final String type;
  final bool notificationEnabled;
  final bool alarmEnabled;
  final TimeOfDay timeOfDay;
  final bool isActive;
  final List<int> daysOfWeek;
  final List<TimeOfDay> timesOfDay;

  String get timeFormatted {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Medication copyWith({
    String? id,
    String? profileId,
    String? name,
    String? dosage,
    String? type,
    bool? notificationEnabled,
    bool? alarmEnabled,
    TimeOfDay? timeOfDay,
    bool? isActive,
    List<int>? daysOfWeek,
    List<TimeOfDay>? timesOfDay,
  }) {
    return Medication(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      type: type ?? this.type,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      isActive: isActive ?? this.isActive,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      timesOfDay: timesOfDay ?? this.timesOfDay,
    );
  }
}
