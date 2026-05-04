import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Medication {
  Medication({
    required this.profileId,
    required this.name,
    required this.dosage,
    required this.timeOfDay,
    this.isActive = true,
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String profileId;
  final String name;
  final String dosage;
  final TimeOfDay timeOfDay;
  final bool isActive;

  String get timeFormatted {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
