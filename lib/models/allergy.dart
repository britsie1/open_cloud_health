import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Allergy {
  Allergy({
    required this.profileId,
    required this.name,
    required this.note,
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String profileId;
  final String name;
  final String note;
}
