import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Checkup {
  Checkup({
    required this.profileId,
    required this.name,
    required this.frequencyInMonths,
    this.iconName,
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String profileId;
  final String name;
  final int frequencyInMonths;
  final String? iconName;
}
