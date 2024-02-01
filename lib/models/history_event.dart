import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();
final formatter = DateFormat('yyyy-MM-dd HH:mm');

class HistoryEvent {
  HistoryEvent(
      {required this.profileId,
      required this.title,
      required this.description,
      required this.date,
      String? id,
      int? attachmentCount})
      : id = id ?? uuid.v4(), attachmentCount = attachmentCount ?? 0;

  final String id;
  final String profileId;
  final String title;
  final String description;
  final DateTime date;
  final int attachmentCount;

  String get formattedDate {
    return formatter.format(date);
  }
}
