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
    this.isAsNeeded = false,
    this.trackInventory = false,
    this.stockQuantity = 0.0,
    this.lowStockThreshold = 0.0,
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
  final bool isAsNeeded;
  final bool trackInventory;
  final double stockQuantity;
  final double lowStockThreshold;

  String get timeFormatted {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get stockQuantityFormatted => formatStockQuantity(stockQuantity);
  String get lowStockThresholdFormatted => formatStockQuantity(lowStockThreshold);

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
    bool? isAsNeeded,
    bool? trackInventory,
    double? stockQuantity,
    double? lowStockThreshold,
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
      isAsNeeded: isAsNeeded ?? this.isAsNeeded,
      trackInventory: trackInventory ?? this.trackInventory,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }
}

double parseDosageQuantity(String dosage) {
  final regex = RegExp(r'([0-9]+(?:\.[0-9]+)?)');
  final match = regex.firstMatch(dosage);
  if (match != null) {
    return double.tryParse(match.group(1)!) ?? 1.0;
  }
  return 1.0;
}

String formatStockQuantity(double stock) {
  if (stock == stock.roundToDouble()) {
    return stock.round().toString();
  }
  final str = stock.toStringAsFixed(2);
  if (str.endsWith('.00')) {
    return str.substring(0, str.length - 3);
  } else if (str.endsWith('0')) {
    return str.substring(0, str.length - 1);
  }
  return str;
}
