import 'package:drift/drift.dart';

@DataClassName('ProfileEntry')
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get middleNames => text().named('middleNames')();
  TextColumn get surname => text()();
  TextColumn get dateOfBirth => text().named('dateOfBirth')();
  TextColumn get bloodType => text().named('bloodType')();
  TextColumn get gender => text()();
  TextColumn get isOrganDonor => text().named('isOrganDonor').withDefault(const Constant('false'))();
  TextColumn get trackOvulation => text().named('trackOvulation').nullable().withDefault(const Constant('true'))();
  TextColumn get isArchived => text().named('isArchived').nullable().withDefault(const Constant('false'))();
  TextColumn get archivedAt => text().named('archivedAt').nullable()();
  TextColumn get chronicConditions => text().named('chronicConditions').nullable().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('HistoryEntry')
class History extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().named('profileId')();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get date => text()();
  TextColumn get eventType => text().named('eventType').nullable().withDefault(const Constant('other'))();
  TextColumn get hasTime => text().named('hasTime').nullable().withDefault(const Constant('true'))();
  TextColumn get provider => text().nullable()();
  TextColumn get facility => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AttachmentEntry')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get historyId => text().named('historyId')();
  TextColumn get filename => text()();
  TextColumn get uploadDate => text().named('uploadDate')();
  IntColumn get byteLength => integer().named('byteLength')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AllergyEntry')
class Allergy extends Table {
  @override
  String get tableName => 'allergy';

  TextColumn get id => text()();
  TextColumn get profileId => text().named('profileId')();
  TextColumn get name => text()();
  TextColumn get note => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MedicationEntry')
class Medications extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().named('profileId')();
  TextColumn get name => text()();
  TextColumn get dosage => text()();
  TextColumn get type => text().nullable().withDefault(const Constant('Other'))();
  TextColumn get notificationEnabled => text().named('notificationEnabled').nullable().withDefault(const Constant('false'))();
  TextColumn get alarmEnabled => text().named('alarmEnabled').nullable().withDefault(const Constant('false'))();
  TextColumn get timeOfDay => text().named('timeOfDay')();
  TextColumn get isActive => text().named('isActive').nullable().withDefault(const Constant('true'))();
  TextColumn get daysOfWeek => text().named('daysOfWeek').nullable()();
  TextColumn get timesOfDay => text().named('timesOfDay').nullable()();
  TextColumn get isAsNeeded => text().named('isAsNeeded').nullable().withDefault(const Constant('false'))();
  TextColumn get trackInventory => text().named('trackInventory').nullable().withDefault(const Constant('false'))();
  RealColumn get stockQuantity => real().named('stockQuantity').nullable().withDefault(const Constant(0.0))();
  RealColumn get lowStockThreshold => real().named('lowStockThreshold').nullable().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MedicationLogEntry')
class MedicationLogs extends Table {
  @override
  String get tableName => 'medication_logs';

  TextColumn get id => text()();
  TextColumn get medicationId => text().named('medicationId')();
  TextColumn get timestamp => text()();
  TextColumn get isTaken => text().named('isTaken').nullable().withDefault(const Constant('true'))();
  TextColumn get dosage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CheckupEntry')
class Checkups extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().named('profileId')();
  TextColumn get name => text()();
  IntColumn get frequencyInMonths => integer().named('frequencyInMonths')();
  TextColumn get iconName => text().named('iconName').nullable()();
  TextColumn get isCustomInterval => text().named('isCustomInterval').nullable().withDefault(const Constant('false'))();
  TextColumn get isActive => text().named('isActive').nullable().withDefault(const Constant('true'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CheckupLogEntry')
class CheckupLogs extends Table {
  @override
  String get tableName => 'checkup_logs';

  TextColumn get id => text()();
  TextColumn get checkupId => text().named('checkupId')();
  TextColumn get dateCompleted => text().named('dateCompleted')();
  TextColumn get location => text().nullable()();
  TextColumn get doctorName => text().named('doctorName').nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PeriodCycleEntry')
class PeriodCycles extends Table {
  @override
  String get tableName => 'period_cycles';

  TextColumn get id => text()();
  TextColumn get profileId => text().named('profileId')();
  TextColumn get startDate => text().named('startDate')();
  TextColumn get endDate => text().named('endDate').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PeriodLogEntry')
class PeriodLogs extends Table {
  @override
  String get tableName => 'period_logs';

  TextColumn get id => text()();
  TextColumn get cycleId => text().named('cycleId')();
  TextColumn get date => text()();
  TextColumn get flowLevel => text().named('flowLevel').nullable()();
  TextColumn get moods => text().nullable()();
  TextColumn get physicalSymptoms => text().named('physicalSymptoms').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('VitalLogEntry')
class VitalLogs extends Table {
  @override
  String get tableName => 'vital_logs';

  TextColumn get id => text()();
  TextColumn get profileId => text().named('profileId')();
  TextColumn get type => text()();
  TextColumn get date => text()();
  RealColumn get value1 => real()();
  RealColumn get value2 => real().nullable()();
  TextColumn get unit => text()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SettingEntry')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('EmergencyContactEntry')
class EmergencyContacts extends Table {
  @override
  String get tableName => 'emergency_contacts';

  TextColumn get id => text()();
  TextColumn get profileId => text().named('profileId')();
  TextColumn get name => text()();
  TextColumn get relationship => text()();
  TextColumn get phoneNumber => text().named('phoneNumber')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LockScreenSettingEntry')
class LockScreenSettings extends Table {
  @override
  String get tableName => 'lock_screen_settings';

  TextColumn get profileId => text().named('profileId')();
  TextColumn get showName => text().named('showName').nullable().withDefault(const Constant('true'))();
  TextColumn get showAge => text().named('showAge').nullable().withDefault(const Constant('true'))();
  TextColumn get showBloodType => text().named('showBloodType').nullable().withDefault(const Constant('true'))();
  TextColumn get showOrganDonor => text().named('showOrganDonor').nullable().withDefault(const Constant('true'))();
  TextColumn get showChronicConditions => text().named('showChronicConditions').nullable().withDefault(const Constant('true'))();
  TextColumn get showAllergies => text().named('showAllergies').nullable().withDefault(const Constant('true'))();
  TextColumn get showMedications => text().named('showMedications').nullable().withDefault(const Constant('true'))();
  TextColumn get showContacts => text().named('showContacts').nullable().withDefault(const Constant('true'))();
  TextColumn get isEnabled => text().named('isEnabled').nullable().withDefault(const Constant('false'))();

  @override
  Set<Column> get primaryKey => {profileId};
}
