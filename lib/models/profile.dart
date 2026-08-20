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
      this.trackOvulation = true,
      this.isArchived = false,
      this.archivedAt,
      this.chronicConditions = const [],
      this.isShared = false,
      this.isReadOnly = false,
      this.sharedBy,
      this.lastSyncedAt,
      this.shareFileId,
      this.shareEncryptionKey,
      this.shareDownloadUrl,
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
  final bool trackOvulation;
  final bool isArchived;
  final DateTime? archivedAt;
  final List<String> chronicConditions;
  final bool isShared;
  final bool isReadOnly;
  final String? sharedBy;
  final DateTime? lastSyncedAt;
  final String? shareFileId;
  final String? shareEncryptionKey;
  final String? shareDownloadUrl;

  String get formattedDate {
    return formatter.format(dateOfBirth);
  }

  int get age {
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}
