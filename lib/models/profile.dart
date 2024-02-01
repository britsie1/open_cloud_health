import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

final formatter = DateFormat('yyyy-MM-dd');

enum Gender { male, female }

const uuid = Uuid();

class Profile {
  Profile(
      {required this.name,
      required this.middleNames,
      required this.surname,
      required this.dateOfBirth,
      required this.gender,
      required this.bloodType,
      required this.isOrganDonor,
      String? id})
      : id = id ?? uuid.v4();

  final String id;
  final String name;
  final String middleNames;
  final String surname;
  final DateTime dateOfBirth;
  final Gender gender;
  final String bloodType;
  final bool isOrganDonor;

  String get formattedDate {
    return formatter.format(dateOfBirth);
  }
}
