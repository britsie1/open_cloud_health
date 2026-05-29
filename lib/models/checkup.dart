import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Checkup {
  Checkup({
    required this.profileId,
    required this.name,
    required this.frequencyInMonths,
    this.iconName,
    String? id,
    this.isCustomInterval = false,
    this.isActive = true,
  }) : id = id ?? uuid.v4();

  final String id;
  final String profileId;
  final String name;
  final int frequencyInMonths;
  final String? iconName;
  final bool isCustomInterval;
  final bool isActive;

  Checkup copyWith({
    String? id,
    String? profileId,
    String? name,
    int? frequencyInMonths,
    String? iconName,
    bool? isCustomInterval,
    bool? isActive,
  }) {
    return Checkup(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      frequencyInMonths: frequencyInMonths ?? this.frequencyInMonths,
      iconName: iconName ?? this.iconName,
      isCustomInterval: isCustomInterval ?? this.isCustomInterval,
      isActive: isActive ?? this.isActive,
    );
  }
}
