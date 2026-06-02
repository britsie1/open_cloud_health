import 'package:uuid/uuid.dart';

const uuid = Uuid();

class EmergencyContact {
  EmergencyContact({
    required this.profileId,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String profileId;
  final String name;
  final String relationship;
  final String phoneNumber;
}
