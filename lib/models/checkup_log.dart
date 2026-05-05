import 'package:uuid/uuid.dart';

const uuid = Uuid();

class CheckupLog {
  CheckupLog({
    required this.checkupId,
    required this.dateCompleted,
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String checkupId;
  final DateTime dateCompleted;
}
