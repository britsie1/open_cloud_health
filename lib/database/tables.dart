import 'package:drift/drift.dart';

@DataClassName('ProfileEntry')
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get middleNames => text().named('middleNames')();
  TextColumn get surname => text()();
  DateTimeColumn get dateOfBirth => dateTime().named('dateOfBirth')();
  TextColumn get bloodType => text().named('bloodType')();
  TextColumn get gender => text()();
  BoolColumn get isOrganDonor => boolean().named('isOrganDonor').withDefault(const Constant(false))();
  BoolColumn get trackOvulation => boolean().named('trackOvulation').nullable().withDefault(const Constant(true))();
  BoolColumn get isArchived => boolean().named('isArchived').nullable().withDefault(const Constant(false))();
  DateTimeColumn get archivedAt => dateTime().named('archivedAt').nullable()();
  TextColumn get chronicConditions => text().named('chronicConditions').nullable().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('HistoryEntry')
class History extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().named('profileId').references(Profiles, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get description => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get eventType => text().named('eventType').nullable().withDefault(const Constant('other'))();
  BoolColumn get hasTime => boolean().named('hasTime').nullable().withDefault(const Constant(true))();
  TextColumn get provider => text().nullable()();
  TextColumn get facility => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AttachmentEntry')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get historyId => text().named('historyId').references(History, #id, onDelete: KeyAction.cascade)();
  TextColumn get filename => text()();
  DateTimeColumn get uploadDate => dateTime().named('uploadDate')();
  IntColumn get byteLength => integer().named('byteLength')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AllergyEntry')
class Allergy extends Table {
  @override
  String get tableName => 'allergy';

  TextColumn get id => text()();
  TextColumn get profileId => text().named('profileId').references(Profiles, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get note => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MedicationEntry')
class Medications extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().named('profileId').references(Profiles, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get dosage => text()();
  TextColumn get type => text().nullable().withDefault(const Constant('Other'))();
  BoolColumn get notificationEnabled => boolean().named('notificationEnabled').nullable().withDefault(const Constant(false))();
  BoolColumn get alarmEnabled => boolean().named('alarmEnabled').nullable().withDefault(const Constant(false))();
  TextColumn get timeOfDay => text().named('timeOfDay')();
  BoolColumn get isActive => boolean().named('isActive').nullable().withDefault(const Constant(true))();
  TextColumn get daysOfWeek => text().named('daysOfWeek').nullable()();
  TextColumn get timesOfDay => text().named('timesOfDay').nullable()();
  BoolColumn get isAsNeeded => boolean().named('isAsNeeded').nullable().withDefault(const Constant(false))();
  BoolColumn get trackInventory => boolean().named('trackInventory').nullable().withDefault(const Constant(false))();
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
  TextColumn get medicationId => text().named('medicationId').references(Medications, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isTaken => boolean().named('isTaken').nullable().withDefault(const Constant(true))();
  TextColumn get dosage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CheckupEntry')
class Checkups extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().named('profileId').references(Profiles, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get frequencyInMonths => integer().named('frequencyInMonths')();
  TextColumn get iconName => text().named('iconName').nullable()();
  BoolColumn get isCustomInterval => boolean().named('isCustomInterval').nullable().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().named('isActive').nullable().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CheckupLogEntry')
class CheckupLogs extends Table {
  @override
  String get tableName => 'checkup_logs';

  TextColumn get id => text()();
  TextColumn get checkupId => text().named('checkupId').references(Checkups, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get dateCompleted => dateTime().named('dateCompleted')();
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
  TextColumn get profileId => text().named('profileId').references(Profiles, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startDate => dateTime().named('startDate')();
  DateTimeColumn get endDate => dateTime().named('endDate').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PeriodLogEntry')
class PeriodLogs extends Table {
  @override
  String get tableName => 'period_logs';

  TextColumn get id => text()();
  TextColumn get cycleId => text().named('cycleId').references(PeriodCycles, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
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
  TextColumn get profileId => text().named('profileId').references(Profiles, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  DateTimeColumn get date => dateTime()();
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
  TextColumn get profileId => text().named('profileId').references(Profiles, #id, onDelete: KeyAction.cascade)();
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

  TextColumn get profileId => text().named('profileId').references(Profiles, #id, onDelete: KeyAction.cascade)();
  BoolColumn get showName => boolean().named('showName').nullable().withDefault(const Constant(true))();
  BoolColumn get showAge => boolean().named('showAge').nullable().withDefault(const Constant(true))();
  BoolColumn get showBloodType => boolean().named('showBloodType').nullable().withDefault(const Constant(true))();
  BoolColumn get showOrganDonor => boolean().named('showOrganDonor').nullable().withDefault(const Constant(true))();
  BoolColumn get showChronicConditions => boolean().named('showChronicConditions').nullable().withDefault(const Constant(true))();
  BoolColumn get showAllergies => boolean().named('showAllergies').nullable().withDefault(const Constant(true))();
  BoolColumn get showMedications => boolean().named('showMedications').nullable().withDefault(const Constant(true))();
  BoolColumn get showContacts => boolean().named('showContacts').nullable().withDefault(const Constant(true))();
  BoolColumn get showInsurance => boolean().named('showInsurance').nullable().withDefault(const Constant(true))();
  BoolColumn get isEnabled => boolean().named('isEnabled').nullable().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {profileId};
}

@DataClassName('InsuranceEntry')
class Insurance extends Table {
  @override
  String get tableName => 'insurance';

  TextColumn get id => text()();
  TextColumn get profileId => text().named('profileId').references(Profiles, #id, onDelete: KeyAction.cascade)();
  TextColumn get provider => text()();
  TextColumn get planName => text().named('planName').nullable()();
  TextColumn get policyNumber => text().named('policyNumber')();
  TextColumn get groupNumber => text().named('groupNumber').nullable()();
  TextColumn get subscriberName => text().named('subscriberName').nullable()();
  TextColumn get memberId => text().named('memberId').nullable()();
  TextColumn get emergencyPhone => text().named('emergencyPhone').nullable()();
  TextColumn get frontCardImage => text().named('frontCardImage').nullable()();
  TextColumn get backCardImage => text().named('backCardImage').nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
