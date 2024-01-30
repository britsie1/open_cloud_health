import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();
final formatter = DateFormat('yyyy-MM-dd HH:mm');

class HistoryEvent {
 HistoryEvent({required this.profileId, required this.title, required this.description, required this.date, String? id}) : id = id ?? uuid.v4();

 final String id;
 final String profileId;
 final String title;
 final String description;
 final DateTime date;

 String get formattedDate {
    return formatter.format(date);
  }
}