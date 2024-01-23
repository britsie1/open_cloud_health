import 'package:uuid/uuid.dart';

const uuid = Uuid();

class HistoryEvent {
 HistoryEvent({required this.userId, required this.title, required this.description, required this.date, String? id}) : id = id ?? uuid.v4();

 final String id;
 final String userId;
 final String title;
 final String description;
 final DateTime date;
}