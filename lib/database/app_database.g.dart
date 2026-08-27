// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, ProfileEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _middleNamesMeta =
      const VerificationMeta('middleNames');
  @override
  late final GeneratedColumn<String> middleNames = GeneratedColumn<String>(
      'middleNames', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surnameMeta =
      const VerificationMeta('surname');
  @override
  late final GeneratedColumn<String> surname = GeneratedColumn<String>(
      'surname', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateOfBirthMeta =
      const VerificationMeta('dateOfBirth');
  @override
  late final GeneratedColumn<DateTime> dateOfBirth = GeneratedColumn<DateTime>(
      'dateOfBirth', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _bloodTypeMeta =
      const VerificationMeta('bloodType');
  @override
  late final GeneratedColumn<String> bloodType = GeneratedColumn<String>(
      'bloodType', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isOrganDonorMeta =
      const VerificationMeta('isOrganDonor');
  @override
  late final GeneratedColumn<bool> isOrganDonor = GeneratedColumn<bool>(
      'isOrganDonor', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("isOrganDonor" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _trackOvulationMeta =
      const VerificationMeta('trackOvulation');
  @override
  late final GeneratedColumn<bool> trackOvulation = GeneratedColumn<bool>(
      'trackOvulation', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("trackOvulation" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'isArchived', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("isArchived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
      'archivedAt', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _chronicConditionsMeta =
      const VerificationMeta('chronicConditions');
  @override
  late final GeneratedColumn<String> chronicConditions =
      GeneratedColumn<String>('chronicConditions', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        middleNames,
        surname,
        dateOfBirth,
        bloodType,
        gender,
        isOrganDonor,
        trackOvulation,
        isArchived,
        archivedAt,
        chronicConditions
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(Insertable<ProfileEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('middleNames')) {
      context.handle(
          _middleNamesMeta,
          middleNames.isAcceptableOrUnknown(
              data['middleNames']!, _middleNamesMeta));
    } else if (isInserting) {
      context.missing(_middleNamesMeta);
    }
    if (data.containsKey('surname')) {
      context.handle(_surnameMeta,
          surname.isAcceptableOrUnknown(data['surname']!, _surnameMeta));
    } else if (isInserting) {
      context.missing(_surnameMeta);
    }
    if (data.containsKey('dateOfBirth')) {
      context.handle(
          _dateOfBirthMeta,
          dateOfBirth.isAcceptableOrUnknown(
              data['dateOfBirth']!, _dateOfBirthMeta));
    } else if (isInserting) {
      context.missing(_dateOfBirthMeta);
    }
    if (data.containsKey('bloodType')) {
      context.handle(_bloodTypeMeta,
          bloodType.isAcceptableOrUnknown(data['bloodType']!, _bloodTypeMeta));
    } else if (isInserting) {
      context.missing(_bloodTypeMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('isOrganDonor')) {
      context.handle(
          _isOrganDonorMeta,
          isOrganDonor.isAcceptableOrUnknown(
              data['isOrganDonor']!, _isOrganDonorMeta));
    }
    if (data.containsKey('trackOvulation')) {
      context.handle(
          _trackOvulationMeta,
          trackOvulation.isAcceptableOrUnknown(
              data['trackOvulation']!, _trackOvulationMeta));
    }
    if (data.containsKey('isArchived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['isArchived']!, _isArchivedMeta));
    }
    if (data.containsKey('archivedAt')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archivedAt']!, _archivedAtMeta));
    }
    if (data.containsKey('chronicConditions')) {
      context.handle(
          _chronicConditionsMeta,
          chronicConditions.isAcceptableOrUnknown(
              data['chronicConditions']!, _chronicConditionsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      middleNames: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}middleNames'])!,
      surname: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}surname'])!,
      dateOfBirth: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}dateOfBirth'])!,
      bloodType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bloodType'])!,
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender'])!,
      isOrganDonor: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}isOrganDonor'])!,
      trackOvulation: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}trackOvulation']),
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}isArchived']),
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}archivedAt']),
      chronicConditions: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}chronicConditions']),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class ProfileEntry extends DataClass implements Insertable<ProfileEntry> {
  final String id;
  final String name;
  final String middleNames;
  final String surname;
  final DateTime dateOfBirth;
  final String bloodType;
  final String gender;
  final bool isOrganDonor;
  final bool? trackOvulation;
  final bool? isArchived;
  final DateTime? archivedAt;
  final String? chronicConditions;
  const ProfileEntry(
      {required this.id,
      required this.name,
      required this.middleNames,
      required this.surname,
      required this.dateOfBirth,
      required this.bloodType,
      required this.gender,
      required this.isOrganDonor,
      this.trackOvulation,
      this.isArchived,
      this.archivedAt,
      this.chronicConditions});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['middleNames'] = Variable<String>(middleNames);
    map['surname'] = Variable<String>(surname);
    map['dateOfBirth'] = Variable<DateTime>(dateOfBirth);
    map['bloodType'] = Variable<String>(bloodType);
    map['gender'] = Variable<String>(gender);
    map['isOrganDonor'] = Variable<bool>(isOrganDonor);
    if (!nullToAbsent || trackOvulation != null) {
      map['trackOvulation'] = Variable<bool>(trackOvulation);
    }
    if (!nullToAbsent || isArchived != null) {
      map['isArchived'] = Variable<bool>(isArchived);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archivedAt'] = Variable<DateTime>(archivedAt);
    }
    if (!nullToAbsent || chronicConditions != null) {
      map['chronicConditions'] = Variable<String>(chronicConditions);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      middleNames: Value(middleNames),
      surname: Value(surname),
      dateOfBirth: Value(dateOfBirth),
      bloodType: Value(bloodType),
      gender: Value(gender),
      isOrganDonor: Value(isOrganDonor),
      trackOvulation: trackOvulation == null && nullToAbsent
          ? const Value.absent()
          : Value(trackOvulation),
      isArchived: isArchived == null && nullToAbsent
          ? const Value.absent()
          : Value(isArchived),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      chronicConditions: chronicConditions == null && nullToAbsent
          ? const Value.absent()
          : Value(chronicConditions),
    );
  }

  factory ProfileEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      middleNames: serializer.fromJson<String>(json['middleNames']),
      surname: serializer.fromJson<String>(json['surname']),
      dateOfBirth: serializer.fromJson<DateTime>(json['dateOfBirth']),
      bloodType: serializer.fromJson<String>(json['bloodType']),
      gender: serializer.fromJson<String>(json['gender']),
      isOrganDonor: serializer.fromJson<bool>(json['isOrganDonor']),
      trackOvulation: serializer.fromJson<bool?>(json['trackOvulation']),
      isArchived: serializer.fromJson<bool?>(json['isArchived']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      chronicConditions:
          serializer.fromJson<String?>(json['chronicConditions']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'middleNames': serializer.toJson<String>(middleNames),
      'surname': serializer.toJson<String>(surname),
      'dateOfBirth': serializer.toJson<DateTime>(dateOfBirth),
      'bloodType': serializer.toJson<String>(bloodType),
      'gender': serializer.toJson<String>(gender),
      'isOrganDonor': serializer.toJson<bool>(isOrganDonor),
      'trackOvulation': serializer.toJson<bool?>(trackOvulation),
      'isArchived': serializer.toJson<bool?>(isArchived),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'chronicConditions': serializer.toJson<String?>(chronicConditions),
    };
  }

  ProfileEntry copyWith(
          {String? id,
          String? name,
          String? middleNames,
          String? surname,
          DateTime? dateOfBirth,
          String? bloodType,
          String? gender,
          bool? isOrganDonor,
          Value<bool?> trackOvulation = const Value.absent(),
          Value<bool?> isArchived = const Value.absent(),
          Value<DateTime?> archivedAt = const Value.absent(),
          Value<String?> chronicConditions = const Value.absent()}) =>
      ProfileEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        middleNames: middleNames ?? this.middleNames,
        surname: surname ?? this.surname,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        bloodType: bloodType ?? this.bloodType,
        gender: gender ?? this.gender,
        isOrganDonor: isOrganDonor ?? this.isOrganDonor,
        trackOvulation:
            trackOvulation.present ? trackOvulation.value : this.trackOvulation,
        isArchived: isArchived.present ? isArchived.value : this.isArchived,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
        chronicConditions: chronicConditions.present
            ? chronicConditions.value
            : this.chronicConditions,
      );
  ProfileEntry copyWithCompanion(ProfilesCompanion data) {
    return ProfileEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      middleNames:
          data.middleNames.present ? data.middleNames.value : this.middleNames,
      surname: data.surname.present ? data.surname.value : this.surname,
      dateOfBirth:
          data.dateOfBirth.present ? data.dateOfBirth.value : this.dateOfBirth,
      bloodType: data.bloodType.present ? data.bloodType.value : this.bloodType,
      gender: data.gender.present ? data.gender.value : this.gender,
      isOrganDonor: data.isOrganDonor.present
          ? data.isOrganDonor.value
          : this.isOrganDonor,
      trackOvulation: data.trackOvulation.present
          ? data.trackOvulation.value
          : this.trackOvulation,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      chronicConditions: data.chronicConditions.present
          ? data.chronicConditions.value
          : this.chronicConditions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('middleNames: $middleNames, ')
          ..write('surname: $surname, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('bloodType: $bloodType, ')
          ..write('gender: $gender, ')
          ..write('isOrganDonor: $isOrganDonor, ')
          ..write('trackOvulation: $trackOvulation, ')
          ..write('isArchived: $isArchived, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('chronicConditions: $chronicConditions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      middleNames,
      surname,
      dateOfBirth,
      bloodType,
      gender,
      isOrganDonor,
      trackOvulation,
      isArchived,
      archivedAt,
      chronicConditions);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.middleNames == this.middleNames &&
          other.surname == this.surname &&
          other.dateOfBirth == this.dateOfBirth &&
          other.bloodType == this.bloodType &&
          other.gender == this.gender &&
          other.isOrganDonor == this.isOrganDonor &&
          other.trackOvulation == this.trackOvulation &&
          other.isArchived == this.isArchived &&
          other.archivedAt == this.archivedAt &&
          other.chronicConditions == this.chronicConditions);
}

class ProfilesCompanion extends UpdateCompanion<ProfileEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> middleNames;
  final Value<String> surname;
  final Value<DateTime> dateOfBirth;
  final Value<String> bloodType;
  final Value<String> gender;
  final Value<bool> isOrganDonor;
  final Value<bool?> trackOvulation;
  final Value<bool?> isArchived;
  final Value<DateTime?> archivedAt;
  final Value<String?> chronicConditions;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.middleNames = const Value.absent(),
    this.surname = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.bloodType = const Value.absent(),
    this.gender = const Value.absent(),
    this.isOrganDonor = const Value.absent(),
    this.trackOvulation = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.chronicConditions = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String name,
    required String middleNames,
    required String surname,
    required DateTime dateOfBirth,
    required String bloodType,
    required String gender,
    this.isOrganDonor = const Value.absent(),
    this.trackOvulation = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.chronicConditions = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        middleNames = Value(middleNames),
        surname = Value(surname),
        dateOfBirth = Value(dateOfBirth),
        bloodType = Value(bloodType),
        gender = Value(gender);
  static Insertable<ProfileEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? middleNames,
    Expression<String>? surname,
    Expression<DateTime>? dateOfBirth,
    Expression<String>? bloodType,
    Expression<String>? gender,
    Expression<bool>? isOrganDonor,
    Expression<bool>? trackOvulation,
    Expression<bool>? isArchived,
    Expression<DateTime>? archivedAt,
    Expression<String>? chronicConditions,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (middleNames != null) 'middleNames': middleNames,
      if (surname != null) 'surname': surname,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (bloodType != null) 'bloodType': bloodType,
      if (gender != null) 'gender': gender,
      if (isOrganDonor != null) 'isOrganDonor': isOrganDonor,
      if (trackOvulation != null) 'trackOvulation': trackOvulation,
      if (isArchived != null) 'isArchived': isArchived,
      if (archivedAt != null) 'archivedAt': archivedAt,
      if (chronicConditions != null) 'chronicConditions': chronicConditions,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? middleNames,
      Value<String>? surname,
      Value<DateTime>? dateOfBirth,
      Value<String>? bloodType,
      Value<String>? gender,
      Value<bool>? isOrganDonor,
      Value<bool?>? trackOvulation,
      Value<bool?>? isArchived,
      Value<DateTime?>? archivedAt,
      Value<String?>? chronicConditions,
      Value<int>? rowid}) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      middleNames: middleNames ?? this.middleNames,
      surname: surname ?? this.surname,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodType: bloodType ?? this.bloodType,
      gender: gender ?? this.gender,
      isOrganDonor: isOrganDonor ?? this.isOrganDonor,
      trackOvulation: trackOvulation ?? this.trackOvulation,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (middleNames.present) {
      map['middleNames'] = Variable<String>(middleNames.value);
    }
    if (surname.present) {
      map['surname'] = Variable<String>(surname.value);
    }
    if (dateOfBirth.present) {
      map['dateOfBirth'] = Variable<DateTime>(dateOfBirth.value);
    }
    if (bloodType.present) {
      map['bloodType'] = Variable<String>(bloodType.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (isOrganDonor.present) {
      map['isOrganDonor'] = Variable<bool>(isOrganDonor.value);
    }
    if (trackOvulation.present) {
      map['trackOvulation'] = Variable<bool>(trackOvulation.value);
    }
    if (isArchived.present) {
      map['isArchived'] = Variable<bool>(isArchived.value);
    }
    if (archivedAt.present) {
      map['archivedAt'] = Variable<DateTime>(archivedAt.value);
    }
    if (chronicConditions.present) {
      map['chronicConditions'] = Variable<String>(chronicConditions.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('middleNames: $middleNames, ')
          ..write('surname: $surname, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('bloodType: $bloodType, ')
          ..write('gender: $gender, ')
          ..write('isOrganDonor: $isOrganDonor, ')
          ..write('trackOvulation: $trackOvulation, ')
          ..write('isArchived: $isArchived, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('chronicConditions: $chronicConditions, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistoryTable extends History
    with TableInfo<$HistoryTable, HistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profileId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES profiles (id) ON DELETE CASCADE'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _eventTypeMeta =
      const VerificationMeta('eventType');
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
      'eventType', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('other'));
  static const VerificationMeta _hasTimeMeta =
      const VerificationMeta('hasTime');
  @override
  late final GeneratedColumn<bool> hasTime = GeneratedColumn<bool>(
      'hasTime', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("hasTime" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _providerMeta =
      const VerificationMeta('provider');
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
      'provider', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _facilityMeta =
      const VerificationMeta('facility');
  @override
  late final GeneratedColumn<String> facility = GeneratedColumn<String>(
      'facility', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        title,
        description,
        date,
        eventType,
        hasTime,
        provider,
        facility
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history';
  @override
  VerificationContext validateIntegrity(Insertable<HistoryEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profileId')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profileId']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('eventType')) {
      context.handle(_eventTypeMeta,
          eventType.isAcceptableOrUnknown(data['eventType']!, _eventTypeMeta));
    }
    if (data.containsKey('hasTime')) {
      context.handle(_hasTimeMeta,
          hasTime.isAcceptableOrUnknown(data['hasTime']!, _hasTimeMeta));
    }
    if (data.containsKey('provider')) {
      context.handle(_providerMeta,
          provider.isAcceptableOrUnknown(data['provider']!, _providerMeta));
    }
    if (data.containsKey('facility')) {
      context.handle(_facilityMeta,
          facility.isAcceptableOrUnknown(data['facility']!, _facilityMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profileId'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      eventType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}eventType']),
      hasTime: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}hasTime']),
      provider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider']),
      facility: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}facility']),
    );
  }

  @override
  $HistoryTable createAlias(String alias) {
    return $HistoryTable(attachedDatabase, alias);
  }
}

class HistoryEntry extends DataClass implements Insertable<HistoryEntry> {
  final String id;
  final String profileId;
  final String title;
  final String description;
  final DateTime date;
  final String? eventType;
  final bool? hasTime;
  final String? provider;
  final String? facility;
  const HistoryEntry(
      {required this.id,
      required this.profileId,
      required this.title,
      required this.description,
      required this.date,
      this.eventType,
      this.hasTime,
      this.provider,
      this.facility});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profileId'] = Variable<String>(profileId);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || eventType != null) {
      map['eventType'] = Variable<String>(eventType);
    }
    if (!nullToAbsent || hasTime != null) {
      map['hasTime'] = Variable<bool>(hasTime);
    }
    if (!nullToAbsent || provider != null) {
      map['provider'] = Variable<String>(provider);
    }
    if (!nullToAbsent || facility != null) {
      map['facility'] = Variable<String>(facility);
    }
    return map;
  }

  HistoryCompanion toCompanion(bool nullToAbsent) {
    return HistoryCompanion(
      id: Value(id),
      profileId: Value(profileId),
      title: Value(title),
      description: Value(description),
      date: Value(date),
      eventType: eventType == null && nullToAbsent
          ? const Value.absent()
          : Value(eventType),
      hasTime: hasTime == null && nullToAbsent
          ? const Value.absent()
          : Value(hasTime),
      provider: provider == null && nullToAbsent
          ? const Value.absent()
          : Value(provider),
      facility: facility == null && nullToAbsent
          ? const Value.absent()
          : Value(facility),
    );
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryEntry(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      date: serializer.fromJson<DateTime>(json['date']),
      eventType: serializer.fromJson<String?>(json['eventType']),
      hasTime: serializer.fromJson<bool?>(json['hasTime']),
      provider: serializer.fromJson<String?>(json['provider']),
      facility: serializer.fromJson<String?>(json['facility']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'date': serializer.toJson<DateTime>(date),
      'eventType': serializer.toJson<String?>(eventType),
      'hasTime': serializer.toJson<bool?>(hasTime),
      'provider': serializer.toJson<String?>(provider),
      'facility': serializer.toJson<String?>(facility),
    };
  }

  HistoryEntry copyWith(
          {String? id,
          String? profileId,
          String? title,
          String? description,
          DateTime? date,
          Value<String?> eventType = const Value.absent(),
          Value<bool?> hasTime = const Value.absent(),
          Value<String?> provider = const Value.absent(),
          Value<String?> facility = const Value.absent()}) =>
      HistoryEntry(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        title: title ?? this.title,
        description: description ?? this.description,
        date: date ?? this.date,
        eventType: eventType.present ? eventType.value : this.eventType,
        hasTime: hasTime.present ? hasTime.value : this.hasTime,
        provider: provider.present ? provider.value : this.provider,
        facility: facility.present ? facility.value : this.facility,
      );
  HistoryEntry copyWithCompanion(HistoryCompanion data) {
    return HistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      date: data.date.present ? data.date.value : this.date,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      hasTime: data.hasTime.present ? data.hasTime.value : this.hasTime,
      provider: data.provider.present ? data.provider.value : this.provider,
      facility: data.facility.present ? data.facility.value : this.facility,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryEntry(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('date: $date, ')
          ..write('eventType: $eventType, ')
          ..write('hasTime: $hasTime, ')
          ..write('provider: $provider, ')
          ..write('facility: $facility')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, title, description, date,
      eventType, hasTime, provider, facility);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryEntry &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.title == this.title &&
          other.description == this.description &&
          other.date == this.date &&
          other.eventType == this.eventType &&
          other.hasTime == this.hasTime &&
          other.provider == this.provider &&
          other.facility == this.facility);
}

class HistoryCompanion extends UpdateCompanion<HistoryEntry> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> title;
  final Value<String> description;
  final Value<DateTime> date;
  final Value<String?> eventType;
  final Value<bool?> hasTime;
  final Value<String?> provider;
  final Value<String?> facility;
  final Value<int> rowid;
  const HistoryCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.date = const Value.absent(),
    this.eventType = const Value.absent(),
    this.hasTime = const Value.absent(),
    this.provider = const Value.absent(),
    this.facility = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryCompanion.insert({
    required String id,
    required String profileId,
    required String title,
    required String description,
    required DateTime date,
    this.eventType = const Value.absent(),
    this.hasTime = const Value.absent(),
    this.provider = const Value.absent(),
    this.facility = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        title = Value(title),
        description = Value(description),
        date = Value(date);
  static Insertable<HistoryEntry> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? date,
    Expression<String>? eventType,
    Expression<bool>? hasTime,
    Expression<String>? provider,
    Expression<String>? facility,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profileId': profileId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (date != null) 'date': date,
      if (eventType != null) 'eventType': eventType,
      if (hasTime != null) 'hasTime': hasTime,
      if (provider != null) 'provider': provider,
      if (facility != null) 'facility': facility,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<String>? title,
      Value<String>? description,
      Value<DateTime>? date,
      Value<String?>? eventType,
      Value<bool?>? hasTime,
      Value<String?>? provider,
      Value<String?>? facility,
      Value<int>? rowid}) {
    return HistoryCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      eventType: eventType ?? this.eventType,
      hasTime: hasTime ?? this.hasTime,
      provider: provider ?? this.provider,
      facility: facility ?? this.facility,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profileId'] = Variable<String>(profileId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (eventType.present) {
      map['eventType'] = Variable<String>(eventType.value);
    }
    if (hasTime.present) {
      map['hasTime'] = Variable<bool>(hasTime.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (facility.present) {
      map['facility'] = Variable<String>(facility.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('date: $date, ')
          ..write('eventType: $eventType, ')
          ..write('hasTime: $hasTime, ')
          ..write('provider: $provider, ')
          ..write('facility: $facility, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, AttachmentEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _historyIdMeta =
      const VerificationMeta('historyId');
  @override
  late final GeneratedColumn<String> historyId = GeneratedColumn<String>(
      'historyId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES history (id) ON DELETE CASCADE'));
  static const VerificationMeta _filenameMeta =
      const VerificationMeta('filename');
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
      'filename', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _uploadDateMeta =
      const VerificationMeta('uploadDate');
  @override
  late final GeneratedColumn<DateTime> uploadDate = GeneratedColumn<DateTime>(
      'uploadDate', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _byteLengthMeta =
      const VerificationMeta('byteLength');
  @override
  late final GeneratedColumn<int> byteLength = GeneratedColumn<int>(
      'byteLength', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, historyId, filename, uploadDate, byteLength];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(Insertable<AttachmentEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('historyId')) {
      context.handle(_historyIdMeta,
          historyId.isAcceptableOrUnknown(data['historyId']!, _historyIdMeta));
    } else if (isInserting) {
      context.missing(_historyIdMeta);
    }
    if (data.containsKey('filename')) {
      context.handle(_filenameMeta,
          filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta));
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('uploadDate')) {
      context.handle(
          _uploadDateMeta,
          uploadDate.isAcceptableOrUnknown(
              data['uploadDate']!, _uploadDateMeta));
    } else if (isInserting) {
      context.missing(_uploadDateMeta);
    }
    if (data.containsKey('byteLength')) {
      context.handle(
          _byteLengthMeta,
          byteLength.isAcceptableOrUnknown(
              data['byteLength']!, _byteLengthMeta));
    } else if (isInserting) {
      context.missing(_byteLengthMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttachmentEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      historyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}historyId'])!,
      filename: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}filename'])!,
      uploadDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}uploadDate'])!,
      byteLength: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}byteLength'])!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class AttachmentEntry extends DataClass implements Insertable<AttachmentEntry> {
  final String id;
  final String historyId;
  final String filename;
  final DateTime uploadDate;
  final int byteLength;
  const AttachmentEntry(
      {required this.id,
      required this.historyId,
      required this.filename,
      required this.uploadDate,
      required this.byteLength});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['historyId'] = Variable<String>(historyId);
    map['filename'] = Variable<String>(filename);
    map['uploadDate'] = Variable<DateTime>(uploadDate);
    map['byteLength'] = Variable<int>(byteLength);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      historyId: Value(historyId),
      filename: Value(filename),
      uploadDate: Value(uploadDate),
      byteLength: Value(byteLength),
    );
  }

  factory AttachmentEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentEntry(
      id: serializer.fromJson<String>(json['id']),
      historyId: serializer.fromJson<String>(json['historyId']),
      filename: serializer.fromJson<String>(json['filename']),
      uploadDate: serializer.fromJson<DateTime>(json['uploadDate']),
      byteLength: serializer.fromJson<int>(json['byteLength']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'historyId': serializer.toJson<String>(historyId),
      'filename': serializer.toJson<String>(filename),
      'uploadDate': serializer.toJson<DateTime>(uploadDate),
      'byteLength': serializer.toJson<int>(byteLength),
    };
  }

  AttachmentEntry copyWith(
          {String? id,
          String? historyId,
          String? filename,
          DateTime? uploadDate,
          int? byteLength}) =>
      AttachmentEntry(
        id: id ?? this.id,
        historyId: historyId ?? this.historyId,
        filename: filename ?? this.filename,
        uploadDate: uploadDate ?? this.uploadDate,
        byteLength: byteLength ?? this.byteLength,
      );
  AttachmentEntry copyWithCompanion(AttachmentsCompanion data) {
    return AttachmentEntry(
      id: data.id.present ? data.id.value : this.id,
      historyId: data.historyId.present ? data.historyId.value : this.historyId,
      filename: data.filename.present ? data.filename.value : this.filename,
      uploadDate:
          data.uploadDate.present ? data.uploadDate.value : this.uploadDate,
      byteLength:
          data.byteLength.present ? data.byteLength.value : this.byteLength,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentEntry(')
          ..write('id: $id, ')
          ..write('historyId: $historyId, ')
          ..write('filename: $filename, ')
          ..write('uploadDate: $uploadDate, ')
          ..write('byteLength: $byteLength')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, historyId, filename, uploadDate, byteLength);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentEntry &&
          other.id == this.id &&
          other.historyId == this.historyId &&
          other.filename == this.filename &&
          other.uploadDate == this.uploadDate &&
          other.byteLength == this.byteLength);
}

class AttachmentsCompanion extends UpdateCompanion<AttachmentEntry> {
  final Value<String> id;
  final Value<String> historyId;
  final Value<String> filename;
  final Value<DateTime> uploadDate;
  final Value<int> byteLength;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.historyId = const Value.absent(),
    this.filename = const Value.absent(),
    this.uploadDate = const Value.absent(),
    this.byteLength = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String historyId,
    required String filename,
    required DateTime uploadDate,
    required int byteLength,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        historyId = Value(historyId),
        filename = Value(filename),
        uploadDate = Value(uploadDate),
        byteLength = Value(byteLength);
  static Insertable<AttachmentEntry> custom({
    Expression<String>? id,
    Expression<String>? historyId,
    Expression<String>? filename,
    Expression<DateTime>? uploadDate,
    Expression<int>? byteLength,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (historyId != null) 'historyId': historyId,
      if (filename != null) 'filename': filename,
      if (uploadDate != null) 'uploadDate': uploadDate,
      if (byteLength != null) 'byteLength': byteLength,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? historyId,
      Value<String>? filename,
      Value<DateTime>? uploadDate,
      Value<int>? byteLength,
      Value<int>? rowid}) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      historyId: historyId ?? this.historyId,
      filename: filename ?? this.filename,
      uploadDate: uploadDate ?? this.uploadDate,
      byteLength: byteLength ?? this.byteLength,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (historyId.present) {
      map['historyId'] = Variable<String>(historyId.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (uploadDate.present) {
      map['uploadDate'] = Variable<DateTime>(uploadDate.value);
    }
    if (byteLength.present) {
      map['byteLength'] = Variable<int>(byteLength.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('historyId: $historyId, ')
          ..write('filename: $filename, ')
          ..write('uploadDate: $uploadDate, ')
          ..write('byteLength: $byteLength, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AllergyTable extends Allergy
    with TableInfo<$AllergyTable, AllergyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AllergyTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profileId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES profiles (id) ON DELETE CASCADE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, profileId, name, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'allergy';
  @override
  VerificationContext validateIntegrity(Insertable<AllergyEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profileId')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profileId']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AllergyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AllergyEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profileId'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
    );
  }

  @override
  $AllergyTable createAlias(String alias) {
    return $AllergyTable(attachedDatabase, alias);
  }
}

class AllergyEntry extends DataClass implements Insertable<AllergyEntry> {
  final String id;
  final String profileId;
  final String name;
  final String note;
  const AllergyEntry(
      {required this.id,
      required this.profileId,
      required this.name,
      required this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profileId'] = Variable<String>(profileId);
    map['name'] = Variable<String>(name);
    map['note'] = Variable<String>(note);
    return map;
  }

  AllergyCompanion toCompanion(bool nullToAbsent) {
    return AllergyCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      note: Value(note),
    );
  }

  factory AllergyEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AllergyEntry(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'name': serializer.toJson<String>(name),
      'note': serializer.toJson<String>(note),
    };
  }

  AllergyEntry copyWith(
          {String? id, String? profileId, String? name, String? note}) =>
      AllergyEntry(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        name: name ?? this.name,
        note: note ?? this.note,
      );
  AllergyEntry copyWithCompanion(AllergyCompanion data) {
    return AllergyEntry(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AllergyEntry(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, name, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AllergyEntry &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.note == this.note);
}

class AllergyCompanion extends UpdateCompanion<AllergyEntry> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> name;
  final Value<String> note;
  final Value<int> rowid;
  const AllergyCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AllergyCompanion.insert({
    required String id,
    required String profileId,
    required String name,
    required String note,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        name = Value(name),
        note = Value(note);
  static Insertable<AllergyEntry> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? name,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profileId': profileId,
      if (name != null) 'name': name,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AllergyCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<String>? name,
      Value<String>? note,
      Value<int>? rowid}) {
    return AllergyCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profileId'] = Variable<String>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AllergyCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationsTable extends Medications
    with TableInfo<$MedicationsTable, MedicationEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profileId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES profiles (id) ON DELETE CASCADE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dosageMeta = const VerificationMeta('dosage');
  @override
  late final GeneratedColumn<String> dosage = GeneratedColumn<String>(
      'dosage', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Other'));
  static const VerificationMeta _notificationEnabledMeta =
      const VerificationMeta('notificationEnabled');
  @override
  late final GeneratedColumn<bool> notificationEnabled = GeneratedColumn<bool>(
      'notificationEnabled', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notificationEnabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _alarmEnabledMeta =
      const VerificationMeta('alarmEnabled');
  @override
  late final GeneratedColumn<bool> alarmEnabled = GeneratedColumn<bool>(
      'alarmEnabled', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("alarmEnabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _timeOfDayMeta =
      const VerificationMeta('timeOfDay');
  @override
  late final GeneratedColumn<String> timeOfDay = GeneratedColumn<String>(
      'timeOfDay', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'isActive', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("isActive" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _daysOfWeekMeta =
      const VerificationMeta('daysOfWeek');
  @override
  late final GeneratedColumn<String> daysOfWeek = GeneratedColumn<String>(
      'daysOfWeek', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timesOfDayMeta =
      const VerificationMeta('timesOfDay');
  @override
  late final GeneratedColumn<String> timesOfDay = GeneratedColumn<String>(
      'timesOfDay', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isAsNeededMeta =
      const VerificationMeta('isAsNeeded');
  @override
  late final GeneratedColumn<bool> isAsNeeded = GeneratedColumn<bool>(
      'isAsNeeded', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("isAsNeeded" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _trackInventoryMeta =
      const VerificationMeta('trackInventory');
  @override
  late final GeneratedColumn<bool> trackInventory = GeneratedColumn<bool>(
      'trackInventory', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("trackInventory" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _stockQuantityMeta =
      const VerificationMeta('stockQuantity');
  @override
  late final GeneratedColumn<double> stockQuantity = GeneratedColumn<double>(
      'stockQuantity', aliasedName, true,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _lowStockThresholdMeta =
      const VerificationMeta('lowStockThreshold');
  @override
  late final GeneratedColumn<double> lowStockThreshold =
      GeneratedColumn<double>('lowStockThreshold', aliasedName, true,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        name,
        dosage,
        type,
        notificationEnabled,
        alarmEnabled,
        timeOfDay,
        isActive,
        daysOfWeek,
        timesOfDay,
        isAsNeeded,
        trackInventory,
        stockQuantity,
        lowStockThreshold
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(Insertable<MedicationEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profileId')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profileId']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dosage')) {
      context.handle(_dosageMeta,
          dosage.isAcceptableOrUnknown(data['dosage']!, _dosageMeta));
    } else if (isInserting) {
      context.missing(_dosageMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('notificationEnabled')) {
      context.handle(
          _notificationEnabledMeta,
          notificationEnabled.isAcceptableOrUnknown(
              data['notificationEnabled']!, _notificationEnabledMeta));
    }
    if (data.containsKey('alarmEnabled')) {
      context.handle(
          _alarmEnabledMeta,
          alarmEnabled.isAcceptableOrUnknown(
              data['alarmEnabled']!, _alarmEnabledMeta));
    }
    if (data.containsKey('timeOfDay')) {
      context.handle(_timeOfDayMeta,
          timeOfDay.isAcceptableOrUnknown(data['timeOfDay']!, _timeOfDayMeta));
    } else if (isInserting) {
      context.missing(_timeOfDayMeta);
    }
    if (data.containsKey('isActive')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['isActive']!, _isActiveMeta));
    }
    if (data.containsKey('daysOfWeek')) {
      context.handle(
          _daysOfWeekMeta,
          daysOfWeek.isAcceptableOrUnknown(
              data['daysOfWeek']!, _daysOfWeekMeta));
    }
    if (data.containsKey('timesOfDay')) {
      context.handle(
          _timesOfDayMeta,
          timesOfDay.isAcceptableOrUnknown(
              data['timesOfDay']!, _timesOfDayMeta));
    }
    if (data.containsKey('isAsNeeded')) {
      context.handle(
          _isAsNeededMeta,
          isAsNeeded.isAcceptableOrUnknown(
              data['isAsNeeded']!, _isAsNeededMeta));
    }
    if (data.containsKey('trackInventory')) {
      context.handle(
          _trackInventoryMeta,
          trackInventory.isAcceptableOrUnknown(
              data['trackInventory']!, _trackInventoryMeta));
    }
    if (data.containsKey('stockQuantity')) {
      context.handle(
          _stockQuantityMeta,
          stockQuantity.isAcceptableOrUnknown(
              data['stockQuantity']!, _stockQuantityMeta));
    }
    if (data.containsKey('lowStockThreshold')) {
      context.handle(
          _lowStockThresholdMeta,
          lowStockThreshold.isAcceptableOrUnknown(
              data['lowStockThreshold']!, _lowStockThresholdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profileId'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      dosage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dosage'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type']),
      notificationEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}notificationEnabled']),
      alarmEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}alarmEnabled']),
      timeOfDay: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timeOfDay'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}isActive']),
      daysOfWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}daysOfWeek']),
      timesOfDay: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timesOfDay']),
      isAsNeeded: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}isAsNeeded']),
      trackInventory: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}trackInventory']),
      stockQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stockQuantity']),
      lowStockThreshold: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}lowStockThreshold']),
    );
  }

  @override
  $MedicationsTable createAlias(String alias) {
    return $MedicationsTable(attachedDatabase, alias);
  }
}

class MedicationEntry extends DataClass implements Insertable<MedicationEntry> {
  final String id;
  final String profileId;
  final String name;
  final String dosage;
  final String? type;
  final bool? notificationEnabled;
  final bool? alarmEnabled;
  final String timeOfDay;
  final bool? isActive;
  final String? daysOfWeek;
  final String? timesOfDay;
  final bool? isAsNeeded;
  final bool? trackInventory;
  final double? stockQuantity;
  final double? lowStockThreshold;
  const MedicationEntry(
      {required this.id,
      required this.profileId,
      required this.name,
      required this.dosage,
      this.type,
      this.notificationEnabled,
      this.alarmEnabled,
      required this.timeOfDay,
      this.isActive,
      this.daysOfWeek,
      this.timesOfDay,
      this.isAsNeeded,
      this.trackInventory,
      this.stockQuantity,
      this.lowStockThreshold});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profileId'] = Variable<String>(profileId);
    map['name'] = Variable<String>(name);
    map['dosage'] = Variable<String>(dosage);
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || notificationEnabled != null) {
      map['notificationEnabled'] = Variable<bool>(notificationEnabled);
    }
    if (!nullToAbsent || alarmEnabled != null) {
      map['alarmEnabled'] = Variable<bool>(alarmEnabled);
    }
    map['timeOfDay'] = Variable<String>(timeOfDay);
    if (!nullToAbsent || isActive != null) {
      map['isActive'] = Variable<bool>(isActive);
    }
    if (!nullToAbsent || daysOfWeek != null) {
      map['daysOfWeek'] = Variable<String>(daysOfWeek);
    }
    if (!nullToAbsent || timesOfDay != null) {
      map['timesOfDay'] = Variable<String>(timesOfDay);
    }
    if (!nullToAbsent || isAsNeeded != null) {
      map['isAsNeeded'] = Variable<bool>(isAsNeeded);
    }
    if (!nullToAbsent || trackInventory != null) {
      map['trackInventory'] = Variable<bool>(trackInventory);
    }
    if (!nullToAbsent || stockQuantity != null) {
      map['stockQuantity'] = Variable<double>(stockQuantity);
    }
    if (!nullToAbsent || lowStockThreshold != null) {
      map['lowStockThreshold'] = Variable<double>(lowStockThreshold);
    }
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      dosage: Value(dosage),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      notificationEnabled: notificationEnabled == null && nullToAbsent
          ? const Value.absent()
          : Value(notificationEnabled),
      alarmEnabled: alarmEnabled == null && nullToAbsent
          ? const Value.absent()
          : Value(alarmEnabled),
      timeOfDay: Value(timeOfDay),
      isActive: isActive == null && nullToAbsent
          ? const Value.absent()
          : Value(isActive),
      daysOfWeek: daysOfWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(daysOfWeek),
      timesOfDay: timesOfDay == null && nullToAbsent
          ? const Value.absent()
          : Value(timesOfDay),
      isAsNeeded: isAsNeeded == null && nullToAbsent
          ? const Value.absent()
          : Value(isAsNeeded),
      trackInventory: trackInventory == null && nullToAbsent
          ? const Value.absent()
          : Value(trackInventory),
      stockQuantity: stockQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(stockQuantity),
      lowStockThreshold: lowStockThreshold == null && nullToAbsent
          ? const Value.absent()
          : Value(lowStockThreshold),
    );
  }

  factory MedicationEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationEntry(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      dosage: serializer.fromJson<String>(json['dosage']),
      type: serializer.fromJson<String?>(json['type']),
      notificationEnabled:
          serializer.fromJson<bool?>(json['notificationEnabled']),
      alarmEnabled: serializer.fromJson<bool?>(json['alarmEnabled']),
      timeOfDay: serializer.fromJson<String>(json['timeOfDay']),
      isActive: serializer.fromJson<bool?>(json['isActive']),
      daysOfWeek: serializer.fromJson<String?>(json['daysOfWeek']),
      timesOfDay: serializer.fromJson<String?>(json['timesOfDay']),
      isAsNeeded: serializer.fromJson<bool?>(json['isAsNeeded']),
      trackInventory: serializer.fromJson<bool?>(json['trackInventory']),
      stockQuantity: serializer.fromJson<double?>(json['stockQuantity']),
      lowStockThreshold:
          serializer.fromJson<double?>(json['lowStockThreshold']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'name': serializer.toJson<String>(name),
      'dosage': serializer.toJson<String>(dosage),
      'type': serializer.toJson<String?>(type),
      'notificationEnabled': serializer.toJson<bool?>(notificationEnabled),
      'alarmEnabled': serializer.toJson<bool?>(alarmEnabled),
      'timeOfDay': serializer.toJson<String>(timeOfDay),
      'isActive': serializer.toJson<bool?>(isActive),
      'daysOfWeek': serializer.toJson<String?>(daysOfWeek),
      'timesOfDay': serializer.toJson<String?>(timesOfDay),
      'isAsNeeded': serializer.toJson<bool?>(isAsNeeded),
      'trackInventory': serializer.toJson<bool?>(trackInventory),
      'stockQuantity': serializer.toJson<double?>(stockQuantity),
      'lowStockThreshold': serializer.toJson<double?>(lowStockThreshold),
    };
  }

  MedicationEntry copyWith(
          {String? id,
          String? profileId,
          String? name,
          String? dosage,
          Value<String?> type = const Value.absent(),
          Value<bool?> notificationEnabled = const Value.absent(),
          Value<bool?> alarmEnabled = const Value.absent(),
          String? timeOfDay,
          Value<bool?> isActive = const Value.absent(),
          Value<String?> daysOfWeek = const Value.absent(),
          Value<String?> timesOfDay = const Value.absent(),
          Value<bool?> isAsNeeded = const Value.absent(),
          Value<bool?> trackInventory = const Value.absent(),
          Value<double?> stockQuantity = const Value.absent(),
          Value<double?> lowStockThreshold = const Value.absent()}) =>
      MedicationEntry(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        name: name ?? this.name,
        dosage: dosage ?? this.dosage,
        type: type.present ? type.value : this.type,
        notificationEnabled: notificationEnabled.present
            ? notificationEnabled.value
            : this.notificationEnabled,
        alarmEnabled:
            alarmEnabled.present ? alarmEnabled.value : this.alarmEnabled,
        timeOfDay: timeOfDay ?? this.timeOfDay,
        isActive: isActive.present ? isActive.value : this.isActive,
        daysOfWeek: daysOfWeek.present ? daysOfWeek.value : this.daysOfWeek,
        timesOfDay: timesOfDay.present ? timesOfDay.value : this.timesOfDay,
        isAsNeeded: isAsNeeded.present ? isAsNeeded.value : this.isAsNeeded,
        trackInventory:
            trackInventory.present ? trackInventory.value : this.trackInventory,
        stockQuantity:
            stockQuantity.present ? stockQuantity.value : this.stockQuantity,
        lowStockThreshold: lowStockThreshold.present
            ? lowStockThreshold.value
            : this.lowStockThreshold,
      );
  MedicationEntry copyWithCompanion(MedicationsCompanion data) {
    return MedicationEntry(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      dosage: data.dosage.present ? data.dosage.value : this.dosage,
      type: data.type.present ? data.type.value : this.type,
      notificationEnabled: data.notificationEnabled.present
          ? data.notificationEnabled.value
          : this.notificationEnabled,
      alarmEnabled: data.alarmEnabled.present
          ? data.alarmEnabled.value
          : this.alarmEnabled,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      daysOfWeek:
          data.daysOfWeek.present ? data.daysOfWeek.value : this.daysOfWeek,
      timesOfDay:
          data.timesOfDay.present ? data.timesOfDay.value : this.timesOfDay,
      isAsNeeded:
          data.isAsNeeded.present ? data.isAsNeeded.value : this.isAsNeeded,
      trackInventory: data.trackInventory.present
          ? data.trackInventory.value
          : this.trackInventory,
      stockQuantity: data.stockQuantity.present
          ? data.stockQuantity.value
          : this.stockQuantity,
      lowStockThreshold: data.lowStockThreshold.present
          ? data.lowStockThreshold.value
          : this.lowStockThreshold,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationEntry(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('dosage: $dosage, ')
          ..write('type: $type, ')
          ..write('notificationEnabled: $notificationEnabled, ')
          ..write('alarmEnabled: $alarmEnabled, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('isActive: $isActive, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('timesOfDay: $timesOfDay, ')
          ..write('isAsNeeded: $isAsNeeded, ')
          ..write('trackInventory: $trackInventory, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('lowStockThreshold: $lowStockThreshold')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      profileId,
      name,
      dosage,
      type,
      notificationEnabled,
      alarmEnabled,
      timeOfDay,
      isActive,
      daysOfWeek,
      timesOfDay,
      isAsNeeded,
      trackInventory,
      stockQuantity,
      lowStockThreshold);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationEntry &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.dosage == this.dosage &&
          other.type == this.type &&
          other.notificationEnabled == this.notificationEnabled &&
          other.alarmEnabled == this.alarmEnabled &&
          other.timeOfDay == this.timeOfDay &&
          other.isActive == this.isActive &&
          other.daysOfWeek == this.daysOfWeek &&
          other.timesOfDay == this.timesOfDay &&
          other.isAsNeeded == this.isAsNeeded &&
          other.trackInventory == this.trackInventory &&
          other.stockQuantity == this.stockQuantity &&
          other.lowStockThreshold == this.lowStockThreshold);
}

class MedicationsCompanion extends UpdateCompanion<MedicationEntry> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> name;
  final Value<String> dosage;
  final Value<String?> type;
  final Value<bool?> notificationEnabled;
  final Value<bool?> alarmEnabled;
  final Value<String> timeOfDay;
  final Value<bool?> isActive;
  final Value<String?> daysOfWeek;
  final Value<String?> timesOfDay;
  final Value<bool?> isAsNeeded;
  final Value<bool?> trackInventory;
  final Value<double?> stockQuantity;
  final Value<double?> lowStockThreshold;
  final Value<int> rowid;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.dosage = const Value.absent(),
    this.type = const Value.absent(),
    this.notificationEnabled = const Value.absent(),
    this.alarmEnabled = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.isActive = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.timesOfDay = const Value.absent(),
    this.isAsNeeded = const Value.absent(),
    this.trackInventory = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationsCompanion.insert({
    required String id,
    required String profileId,
    required String name,
    required String dosage,
    this.type = const Value.absent(),
    this.notificationEnabled = const Value.absent(),
    this.alarmEnabled = const Value.absent(),
    required String timeOfDay,
    this.isActive = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.timesOfDay = const Value.absent(),
    this.isAsNeeded = const Value.absent(),
    this.trackInventory = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        name = Value(name),
        dosage = Value(dosage),
        timeOfDay = Value(timeOfDay);
  static Insertable<MedicationEntry> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? name,
    Expression<String>? dosage,
    Expression<String>? type,
    Expression<bool>? notificationEnabled,
    Expression<bool>? alarmEnabled,
    Expression<String>? timeOfDay,
    Expression<bool>? isActive,
    Expression<String>? daysOfWeek,
    Expression<String>? timesOfDay,
    Expression<bool>? isAsNeeded,
    Expression<bool>? trackInventory,
    Expression<double>? stockQuantity,
    Expression<double>? lowStockThreshold,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profileId': profileId,
      if (name != null) 'name': name,
      if (dosage != null) 'dosage': dosage,
      if (type != null) 'type': type,
      if (notificationEnabled != null)
        'notificationEnabled': notificationEnabled,
      if (alarmEnabled != null) 'alarmEnabled': alarmEnabled,
      if (timeOfDay != null) 'timeOfDay': timeOfDay,
      if (isActive != null) 'isActive': isActive,
      if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
      if (timesOfDay != null) 'timesOfDay': timesOfDay,
      if (isAsNeeded != null) 'isAsNeeded': isAsNeeded,
      if (trackInventory != null) 'trackInventory': trackInventory,
      if (stockQuantity != null) 'stockQuantity': stockQuantity,
      if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<String>? name,
      Value<String>? dosage,
      Value<String?>? type,
      Value<bool?>? notificationEnabled,
      Value<bool?>? alarmEnabled,
      Value<String>? timeOfDay,
      Value<bool?>? isActive,
      Value<String?>? daysOfWeek,
      Value<String?>? timesOfDay,
      Value<bool?>? isAsNeeded,
      Value<bool?>? trackInventory,
      Value<double?>? stockQuantity,
      Value<double?>? lowStockThreshold,
      Value<int>? rowid}) {
    return MedicationsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      type: type ?? this.type,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      isActive: isActive ?? this.isActive,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      timesOfDay: timesOfDay ?? this.timesOfDay,
      isAsNeeded: isAsNeeded ?? this.isAsNeeded,
      trackInventory: trackInventory ?? this.trackInventory,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profileId'] = Variable<String>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dosage.present) {
      map['dosage'] = Variable<String>(dosage.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (notificationEnabled.present) {
      map['notificationEnabled'] = Variable<bool>(notificationEnabled.value);
    }
    if (alarmEnabled.present) {
      map['alarmEnabled'] = Variable<bool>(alarmEnabled.value);
    }
    if (timeOfDay.present) {
      map['timeOfDay'] = Variable<String>(timeOfDay.value);
    }
    if (isActive.present) {
      map['isActive'] = Variable<bool>(isActive.value);
    }
    if (daysOfWeek.present) {
      map['daysOfWeek'] = Variable<String>(daysOfWeek.value);
    }
    if (timesOfDay.present) {
      map['timesOfDay'] = Variable<String>(timesOfDay.value);
    }
    if (isAsNeeded.present) {
      map['isAsNeeded'] = Variable<bool>(isAsNeeded.value);
    }
    if (trackInventory.present) {
      map['trackInventory'] = Variable<bool>(trackInventory.value);
    }
    if (stockQuantity.present) {
      map['stockQuantity'] = Variable<double>(stockQuantity.value);
    }
    if (lowStockThreshold.present) {
      map['lowStockThreshold'] = Variable<double>(lowStockThreshold.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('dosage: $dosage, ')
          ..write('type: $type, ')
          ..write('notificationEnabled: $notificationEnabled, ')
          ..write('alarmEnabled: $alarmEnabled, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('isActive: $isActive, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('timesOfDay: $timesOfDay, ')
          ..write('isAsNeeded: $isAsNeeded, ')
          ..write('trackInventory: $trackInventory, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationLogsTable extends MedicationLogs
    with TableInfo<$MedicationLogsTable, MedicationLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _medicationIdMeta =
      const VerificationMeta('medicationId');
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
      'medicationId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES medications (id) ON DELETE CASCADE'));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isTakenMeta =
      const VerificationMeta('isTaken');
  @override
  late final GeneratedColumn<bool> isTaken = GeneratedColumn<bool>(
      'isTaken', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("isTaken" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _dosageMeta = const VerificationMeta('dosage');
  @override
  late final GeneratedColumn<String> dosage = GeneratedColumn<String>(
      'dosage', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, medicationId, timestamp, isTaken, dosage];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_logs';
  @override
  VerificationContext validateIntegrity(Insertable<MedicationLogEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('medicationId')) {
      context.handle(
          _medicationIdMeta,
          medicationId.isAcceptableOrUnknown(
              data['medicationId']!, _medicationIdMeta));
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('isTaken')) {
      context.handle(_isTakenMeta,
          isTaken.isAcceptableOrUnknown(data['isTaken']!, _isTakenMeta));
    }
    if (data.containsKey('dosage')) {
      context.handle(_dosageMeta,
          dosage.isAcceptableOrUnknown(data['dosage']!, _dosageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationLogEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      medicationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}medicationId'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      isTaken: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}isTaken']),
      dosage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dosage']),
    );
  }

  @override
  $MedicationLogsTable createAlias(String alias) {
    return $MedicationLogsTable(attachedDatabase, alias);
  }
}

class MedicationLogEntry extends DataClass
    implements Insertable<MedicationLogEntry> {
  final String id;
  final String medicationId;
  final DateTime timestamp;
  final bool? isTaken;
  final String? dosage;
  const MedicationLogEntry(
      {required this.id,
      required this.medicationId,
      required this.timestamp,
      this.isTaken,
      this.dosage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['medicationId'] = Variable<String>(medicationId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || isTaken != null) {
      map['isTaken'] = Variable<bool>(isTaken);
    }
    if (!nullToAbsent || dosage != null) {
      map['dosage'] = Variable<String>(dosage);
    }
    return map;
  }

  MedicationLogsCompanion toCompanion(bool nullToAbsent) {
    return MedicationLogsCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      timestamp: Value(timestamp),
      isTaken: isTaken == null && nullToAbsent
          ? const Value.absent()
          : Value(isTaken),
      dosage:
          dosage == null && nullToAbsent ? const Value.absent() : Value(dosage),
    );
  }

  factory MedicationLogEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationLogEntry(
      id: serializer.fromJson<String>(json['id']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      isTaken: serializer.fromJson<bool?>(json['isTaken']),
      dosage: serializer.fromJson<String?>(json['dosage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'medicationId': serializer.toJson<String>(medicationId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'isTaken': serializer.toJson<bool?>(isTaken),
      'dosage': serializer.toJson<String?>(dosage),
    };
  }

  MedicationLogEntry copyWith(
          {String? id,
          String? medicationId,
          DateTime? timestamp,
          Value<bool?> isTaken = const Value.absent(),
          Value<String?> dosage = const Value.absent()}) =>
      MedicationLogEntry(
        id: id ?? this.id,
        medicationId: medicationId ?? this.medicationId,
        timestamp: timestamp ?? this.timestamp,
        isTaken: isTaken.present ? isTaken.value : this.isTaken,
        dosage: dosage.present ? dosage.value : this.dosage,
      );
  MedicationLogEntry copyWithCompanion(MedicationLogsCompanion data) {
    return MedicationLogEntry(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isTaken: data.isTaken.present ? data.isTaken.value : this.isTaken,
      dosage: data.dosage.present ? data.dosage.value : this.dosage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationLogEntry(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('timestamp: $timestamp, ')
          ..write('isTaken: $isTaken, ')
          ..write('dosage: $dosage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, medicationId, timestamp, isTaken, dosage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationLogEntry &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.timestamp == this.timestamp &&
          other.isTaken == this.isTaken &&
          other.dosage == this.dosage);
}

class MedicationLogsCompanion extends UpdateCompanion<MedicationLogEntry> {
  final Value<String> id;
  final Value<String> medicationId;
  final Value<DateTime> timestamp;
  final Value<bool?> isTaken;
  final Value<String?> dosage;
  final Value<int> rowid;
  const MedicationLogsCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isTaken = const Value.absent(),
    this.dosage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationLogsCompanion.insert({
    required String id,
    required String medicationId,
    required DateTime timestamp,
    this.isTaken = const Value.absent(),
    this.dosage = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        medicationId = Value(medicationId),
        timestamp = Value(timestamp);
  static Insertable<MedicationLogEntry> custom({
    Expression<String>? id,
    Expression<String>? medicationId,
    Expression<DateTime>? timestamp,
    Expression<bool>? isTaken,
    Expression<String>? dosage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medicationId': medicationId,
      if (timestamp != null) 'timestamp': timestamp,
      if (isTaken != null) 'isTaken': isTaken,
      if (dosage != null) 'dosage': dosage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? medicationId,
      Value<DateTime>? timestamp,
      Value<bool?>? isTaken,
      Value<String?>? dosage,
      Value<int>? rowid}) {
    return MedicationLogsCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      timestamp: timestamp ?? this.timestamp,
      isTaken: isTaken ?? this.isTaken,
      dosage: dosage ?? this.dosage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (medicationId.present) {
      map['medicationId'] = Variable<String>(medicationId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (isTaken.present) {
      map['isTaken'] = Variable<bool>(isTaken.value);
    }
    if (dosage.present) {
      map['dosage'] = Variable<String>(dosage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationLogsCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('timestamp: $timestamp, ')
          ..write('isTaken: $isTaken, ')
          ..write('dosage: $dosage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CheckupsTable extends Checkups
    with TableInfo<$CheckupsTable, CheckupEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profileId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES profiles (id) ON DELETE CASCADE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _frequencyInMonthsMeta =
      const VerificationMeta('frequencyInMonths');
  @override
  late final GeneratedColumn<int> frequencyInMonths = GeneratedColumn<int>(
      'frequencyInMonths', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _iconNameMeta =
      const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
      'iconName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isCustomIntervalMeta =
      const VerificationMeta('isCustomInterval');
  @override
  late final GeneratedColumn<bool> isCustomInterval = GeneratedColumn<bool>(
      'isCustomInterval', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("isCustomInterval" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'isActive', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("isActive" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        name,
        frequencyInMonths,
        iconName,
        isCustomInterval,
        isActive
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checkups';
  @override
  VerificationContext validateIntegrity(Insertable<CheckupEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profileId')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profileId']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('frequencyInMonths')) {
      context.handle(
          _frequencyInMonthsMeta,
          frequencyInMonths.isAcceptableOrUnknown(
              data['frequencyInMonths']!, _frequencyInMonthsMeta));
    } else if (isInserting) {
      context.missing(_frequencyInMonthsMeta);
    }
    if (data.containsKey('iconName')) {
      context.handle(_iconNameMeta,
          iconName.isAcceptableOrUnknown(data['iconName']!, _iconNameMeta));
    }
    if (data.containsKey('isCustomInterval')) {
      context.handle(
          _isCustomIntervalMeta,
          isCustomInterval.isAcceptableOrUnknown(
              data['isCustomInterval']!, _isCustomIntervalMeta));
    }
    if (data.containsKey('isActive')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['isActive']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CheckupEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckupEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profileId'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      frequencyInMonths: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}frequencyInMonths'])!,
      iconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}iconName']),
      isCustomInterval: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}isCustomInterval']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}isActive']),
    );
  }

  @override
  $CheckupsTable createAlias(String alias) {
    return $CheckupsTable(attachedDatabase, alias);
  }
}

class CheckupEntry extends DataClass implements Insertable<CheckupEntry> {
  final String id;
  final String profileId;
  final String name;
  final int frequencyInMonths;
  final String? iconName;
  final bool? isCustomInterval;
  final bool? isActive;
  const CheckupEntry(
      {required this.id,
      required this.profileId,
      required this.name,
      required this.frequencyInMonths,
      this.iconName,
      this.isCustomInterval,
      this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profileId'] = Variable<String>(profileId);
    map['name'] = Variable<String>(name);
    map['frequencyInMonths'] = Variable<int>(frequencyInMonths);
    if (!nullToAbsent || iconName != null) {
      map['iconName'] = Variable<String>(iconName);
    }
    if (!nullToAbsent || isCustomInterval != null) {
      map['isCustomInterval'] = Variable<bool>(isCustomInterval);
    }
    if (!nullToAbsent || isActive != null) {
      map['isActive'] = Variable<bool>(isActive);
    }
    return map;
  }

  CheckupsCompanion toCompanion(bool nullToAbsent) {
    return CheckupsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      frequencyInMonths: Value(frequencyInMonths),
      iconName: iconName == null && nullToAbsent
          ? const Value.absent()
          : Value(iconName),
      isCustomInterval: isCustomInterval == null && nullToAbsent
          ? const Value.absent()
          : Value(isCustomInterval),
      isActive: isActive == null && nullToAbsent
          ? const Value.absent()
          : Value(isActive),
    );
  }

  factory CheckupEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckupEntry(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      frequencyInMonths: serializer.fromJson<int>(json['frequencyInMonths']),
      iconName: serializer.fromJson<String?>(json['iconName']),
      isCustomInterval: serializer.fromJson<bool?>(json['isCustomInterval']),
      isActive: serializer.fromJson<bool?>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'name': serializer.toJson<String>(name),
      'frequencyInMonths': serializer.toJson<int>(frequencyInMonths),
      'iconName': serializer.toJson<String?>(iconName),
      'isCustomInterval': serializer.toJson<bool?>(isCustomInterval),
      'isActive': serializer.toJson<bool?>(isActive),
    };
  }

  CheckupEntry copyWith(
          {String? id,
          String? profileId,
          String? name,
          int? frequencyInMonths,
          Value<String?> iconName = const Value.absent(),
          Value<bool?> isCustomInterval = const Value.absent(),
          Value<bool?> isActive = const Value.absent()}) =>
      CheckupEntry(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        name: name ?? this.name,
        frequencyInMonths: frequencyInMonths ?? this.frequencyInMonths,
        iconName: iconName.present ? iconName.value : this.iconName,
        isCustomInterval: isCustomInterval.present
            ? isCustomInterval.value
            : this.isCustomInterval,
        isActive: isActive.present ? isActive.value : this.isActive,
      );
  CheckupEntry copyWithCompanion(CheckupsCompanion data) {
    return CheckupEntry(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      frequencyInMonths: data.frequencyInMonths.present
          ? data.frequencyInMonths.value
          : this.frequencyInMonths,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      isCustomInterval: data.isCustomInterval.present
          ? data.isCustomInterval.value
          : this.isCustomInterval,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckupEntry(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('frequencyInMonths: $frequencyInMonths, ')
          ..write('iconName: $iconName, ')
          ..write('isCustomInterval: $isCustomInterval, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, name, frequencyInMonths,
      iconName, isCustomInterval, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckupEntry &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.frequencyInMonths == this.frequencyInMonths &&
          other.iconName == this.iconName &&
          other.isCustomInterval == this.isCustomInterval &&
          other.isActive == this.isActive);
}

class CheckupsCompanion extends UpdateCompanion<CheckupEntry> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> name;
  final Value<int> frequencyInMonths;
  final Value<String?> iconName;
  final Value<bool?> isCustomInterval;
  final Value<bool?> isActive;
  final Value<int> rowid;
  const CheckupsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.frequencyInMonths = const Value.absent(),
    this.iconName = const Value.absent(),
    this.isCustomInterval = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheckupsCompanion.insert({
    required String id,
    required String profileId,
    required String name,
    required int frequencyInMonths,
    this.iconName = const Value.absent(),
    this.isCustomInterval = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        name = Value(name),
        frequencyInMonths = Value(frequencyInMonths);
  static Insertable<CheckupEntry> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? name,
    Expression<int>? frequencyInMonths,
    Expression<String>? iconName,
    Expression<bool>? isCustomInterval,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profileId': profileId,
      if (name != null) 'name': name,
      if (frequencyInMonths != null) 'frequencyInMonths': frequencyInMonths,
      if (iconName != null) 'iconName': iconName,
      if (isCustomInterval != null) 'isCustomInterval': isCustomInterval,
      if (isActive != null) 'isActive': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheckupsCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<String>? name,
      Value<int>? frequencyInMonths,
      Value<String?>? iconName,
      Value<bool?>? isCustomInterval,
      Value<bool?>? isActive,
      Value<int>? rowid}) {
    return CheckupsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      frequencyInMonths: frequencyInMonths ?? this.frequencyInMonths,
      iconName: iconName ?? this.iconName,
      isCustomInterval: isCustomInterval ?? this.isCustomInterval,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profileId'] = Variable<String>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (frequencyInMonths.present) {
      map['frequencyInMonths'] = Variable<int>(frequencyInMonths.value);
    }
    if (iconName.present) {
      map['iconName'] = Variable<String>(iconName.value);
    }
    if (isCustomInterval.present) {
      map['isCustomInterval'] = Variable<bool>(isCustomInterval.value);
    }
    if (isActive.present) {
      map['isActive'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckupsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('frequencyInMonths: $frequencyInMonths, ')
          ..write('iconName: $iconName, ')
          ..write('isCustomInterval: $isCustomInterval, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CheckupLogsTable extends CheckupLogs
    with TableInfo<$CheckupLogsTable, CheckupLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckupLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _checkupIdMeta =
      const VerificationMeta('checkupId');
  @override
  late final GeneratedColumn<String> checkupId = GeneratedColumn<String>(
      'checkupId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES checkups (id) ON DELETE CASCADE'));
  static const VerificationMeta _dateCompletedMeta =
      const VerificationMeta('dateCompleted');
  @override
  late final GeneratedColumn<DateTime> dateCompleted =
      GeneratedColumn<DateTime>('dateCompleted', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _doctorNameMeta =
      const VerificationMeta('doctorName');
  @override
  late final GeneratedColumn<String> doctorName = GeneratedColumn<String>(
      'doctorName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, checkupId, dateCompleted, location, doctorName, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checkup_logs';
  @override
  VerificationContext validateIntegrity(Insertable<CheckupLogEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('checkupId')) {
      context.handle(_checkupIdMeta,
          checkupId.isAcceptableOrUnknown(data['checkupId']!, _checkupIdMeta));
    } else if (isInserting) {
      context.missing(_checkupIdMeta);
    }
    if (data.containsKey('dateCompleted')) {
      context.handle(
          _dateCompletedMeta,
          dateCompleted.isAcceptableOrUnknown(
              data['dateCompleted']!, _dateCompletedMeta));
    } else if (isInserting) {
      context.missing(_dateCompletedMeta);
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('doctorName')) {
      context.handle(
          _doctorNameMeta,
          doctorName.isAcceptableOrUnknown(
              data['doctorName']!, _doctorNameMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CheckupLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckupLogEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      checkupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checkupId'])!,
      dateCompleted: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}dateCompleted'])!,
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      doctorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doctorName']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $CheckupLogsTable createAlias(String alias) {
    return $CheckupLogsTable(attachedDatabase, alias);
  }
}

class CheckupLogEntry extends DataClass implements Insertable<CheckupLogEntry> {
  final String id;
  final String checkupId;
  final DateTime dateCompleted;
  final String? location;
  final String? doctorName;
  final String? notes;
  const CheckupLogEntry(
      {required this.id,
      required this.checkupId,
      required this.dateCompleted,
      this.location,
      this.doctorName,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['checkupId'] = Variable<String>(checkupId);
    map['dateCompleted'] = Variable<DateTime>(dateCompleted);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || doctorName != null) {
      map['doctorName'] = Variable<String>(doctorName);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  CheckupLogsCompanion toCompanion(bool nullToAbsent) {
    return CheckupLogsCompanion(
      id: Value(id),
      checkupId: Value(checkupId),
      dateCompleted: Value(dateCompleted),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      doctorName: doctorName == null && nullToAbsent
          ? const Value.absent()
          : Value(doctorName),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory CheckupLogEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckupLogEntry(
      id: serializer.fromJson<String>(json['id']),
      checkupId: serializer.fromJson<String>(json['checkupId']),
      dateCompleted: serializer.fromJson<DateTime>(json['dateCompleted']),
      location: serializer.fromJson<String?>(json['location']),
      doctorName: serializer.fromJson<String?>(json['doctorName']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'checkupId': serializer.toJson<String>(checkupId),
      'dateCompleted': serializer.toJson<DateTime>(dateCompleted),
      'location': serializer.toJson<String?>(location),
      'doctorName': serializer.toJson<String?>(doctorName),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  CheckupLogEntry copyWith(
          {String? id,
          String? checkupId,
          DateTime? dateCompleted,
          Value<String?> location = const Value.absent(),
          Value<String?> doctorName = const Value.absent(),
          Value<String?> notes = const Value.absent()}) =>
      CheckupLogEntry(
        id: id ?? this.id,
        checkupId: checkupId ?? this.checkupId,
        dateCompleted: dateCompleted ?? this.dateCompleted,
        location: location.present ? location.value : this.location,
        doctorName: doctorName.present ? doctorName.value : this.doctorName,
        notes: notes.present ? notes.value : this.notes,
      );
  CheckupLogEntry copyWithCompanion(CheckupLogsCompanion data) {
    return CheckupLogEntry(
      id: data.id.present ? data.id.value : this.id,
      checkupId: data.checkupId.present ? data.checkupId.value : this.checkupId,
      dateCompleted: data.dateCompleted.present
          ? data.dateCompleted.value
          : this.dateCompleted,
      location: data.location.present ? data.location.value : this.location,
      doctorName:
          data.doctorName.present ? data.doctorName.value : this.doctorName,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckupLogEntry(')
          ..write('id: $id, ')
          ..write('checkupId: $checkupId, ')
          ..write('dateCompleted: $dateCompleted, ')
          ..write('location: $location, ')
          ..write('doctorName: $doctorName, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, checkupId, dateCompleted, location, doctorName, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckupLogEntry &&
          other.id == this.id &&
          other.checkupId == this.checkupId &&
          other.dateCompleted == this.dateCompleted &&
          other.location == this.location &&
          other.doctorName == this.doctorName &&
          other.notes == this.notes);
}

class CheckupLogsCompanion extends UpdateCompanion<CheckupLogEntry> {
  final Value<String> id;
  final Value<String> checkupId;
  final Value<DateTime> dateCompleted;
  final Value<String?> location;
  final Value<String?> doctorName;
  final Value<String?> notes;
  final Value<int> rowid;
  const CheckupLogsCompanion({
    this.id = const Value.absent(),
    this.checkupId = const Value.absent(),
    this.dateCompleted = const Value.absent(),
    this.location = const Value.absent(),
    this.doctorName = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheckupLogsCompanion.insert({
    required String id,
    required String checkupId,
    required DateTime dateCompleted,
    this.location = const Value.absent(),
    this.doctorName = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        checkupId = Value(checkupId),
        dateCompleted = Value(dateCompleted);
  static Insertable<CheckupLogEntry> custom({
    Expression<String>? id,
    Expression<String>? checkupId,
    Expression<DateTime>? dateCompleted,
    Expression<String>? location,
    Expression<String>? doctorName,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (checkupId != null) 'checkupId': checkupId,
      if (dateCompleted != null) 'dateCompleted': dateCompleted,
      if (location != null) 'location': location,
      if (doctorName != null) 'doctorName': doctorName,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheckupLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? checkupId,
      Value<DateTime>? dateCompleted,
      Value<String?>? location,
      Value<String?>? doctorName,
      Value<String?>? notes,
      Value<int>? rowid}) {
    return CheckupLogsCompanion(
      id: id ?? this.id,
      checkupId: checkupId ?? this.checkupId,
      dateCompleted: dateCompleted ?? this.dateCompleted,
      location: location ?? this.location,
      doctorName: doctorName ?? this.doctorName,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (checkupId.present) {
      map['checkupId'] = Variable<String>(checkupId.value);
    }
    if (dateCompleted.present) {
      map['dateCompleted'] = Variable<DateTime>(dateCompleted.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (doctorName.present) {
      map['doctorName'] = Variable<String>(doctorName.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckupLogsCompanion(')
          ..write('id: $id, ')
          ..write('checkupId: $checkupId, ')
          ..write('dateCompleted: $dateCompleted, ')
          ..write('location: $location, ')
          ..write('doctorName: $doctorName, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeriodCyclesTable extends PeriodCycles
    with TableInfo<$PeriodCyclesTable, PeriodCycleEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodCyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profileId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES profiles (id) ON DELETE CASCADE'));
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'startDate', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'endDate', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, profileId, startDate, endDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'period_cycles';
  @override
  VerificationContext validateIntegrity(Insertable<PeriodCycleEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profileId')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profileId']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('startDate')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['startDate']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('endDate')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['endDate']!, _endDateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeriodCycleEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeriodCycleEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profileId'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}startDate'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}endDate']),
    );
  }

  @override
  $PeriodCyclesTable createAlias(String alias) {
    return $PeriodCyclesTable(attachedDatabase, alias);
  }
}

class PeriodCycleEntry extends DataClass
    implements Insertable<PeriodCycleEntry> {
  final String id;
  final String profileId;
  final DateTime startDate;
  final DateTime? endDate;
  const PeriodCycleEntry(
      {required this.id,
      required this.profileId,
      required this.startDate,
      this.endDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profileId'] = Variable<String>(profileId);
    map['startDate'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['endDate'] = Variable<DateTime>(endDate);
    }
    return map;
  }

  PeriodCyclesCompanion toCompanion(bool nullToAbsent) {
    return PeriodCyclesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
    );
  }

  factory PeriodCycleEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodCycleEntry(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
    };
  }

  PeriodCycleEntry copyWith(
          {String? id,
          String? profileId,
          DateTime? startDate,
          Value<DateTime?> endDate = const Value.absent()}) =>
      PeriodCycleEntry(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
      );
  PeriodCycleEntry copyWithCompanion(PeriodCyclesCompanion data) {
    return PeriodCycleEntry(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodCycleEntry(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, startDate, endDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodCycleEntry &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate);
}

class PeriodCyclesCompanion extends UpdateCompanion<PeriodCycleEntry> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<int> rowid;
  const PeriodCyclesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeriodCyclesCompanion.insert({
    required String id,
    required String profileId,
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        startDate = Value(startDate);
  static Insertable<PeriodCycleEntry> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profileId': profileId,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeriodCyclesCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<DateTime>? startDate,
      Value<DateTime?>? endDate,
      Value<int>? rowid}) {
    return PeriodCyclesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profileId'] = Variable<String>(profileId.value);
    }
    if (startDate.present) {
      map['startDate'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['endDate'] = Variable<DateTime>(endDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodCyclesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeriodLogsTable extends PeriodLogs
    with TableInfo<$PeriodLogsTable, PeriodLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cycleIdMeta =
      const VerificationMeta('cycleId');
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
      'cycleId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES period_cycles (id) ON DELETE CASCADE'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _flowLevelMeta =
      const VerificationMeta('flowLevel');
  @override
  late final GeneratedColumn<String> flowLevel = GeneratedColumn<String>(
      'flowLevel', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _moodsMeta = const VerificationMeta('moods');
  @override
  late final GeneratedColumn<String> moods = GeneratedColumn<String>(
      'moods', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _physicalSymptomsMeta =
      const VerificationMeta('physicalSymptoms');
  @override
  late final GeneratedColumn<String> physicalSymptoms = GeneratedColumn<String>(
      'physicalSymptoms', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, cycleId, date, flowLevel, moods, physicalSymptoms];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'period_logs';
  @override
  VerificationContext validateIntegrity(Insertable<PeriodLogEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cycleId')) {
      context.handle(_cycleIdMeta,
          cycleId.isAcceptableOrUnknown(data['cycleId']!, _cycleIdMeta));
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('flowLevel')) {
      context.handle(_flowLevelMeta,
          flowLevel.isAcceptableOrUnknown(data['flowLevel']!, _flowLevelMeta));
    }
    if (data.containsKey('moods')) {
      context.handle(
          _moodsMeta, moods.isAcceptableOrUnknown(data['moods']!, _moodsMeta));
    }
    if (data.containsKey('physicalSymptoms')) {
      context.handle(
          _physicalSymptomsMeta,
          physicalSymptoms.isAcceptableOrUnknown(
              data['physicalSymptoms']!, _physicalSymptomsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeriodLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeriodLogEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      cycleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cycleId'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      flowLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}flowLevel']),
      moods: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}moods']),
      physicalSymptoms: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}physicalSymptoms']),
    );
  }

  @override
  $PeriodLogsTable createAlias(String alias) {
    return $PeriodLogsTable(attachedDatabase, alias);
  }
}

class PeriodLogEntry extends DataClass implements Insertable<PeriodLogEntry> {
  final String id;
  final String cycleId;
  final DateTime date;
  final String? flowLevel;
  final String? moods;
  final String? physicalSymptoms;
  const PeriodLogEntry(
      {required this.id,
      required this.cycleId,
      required this.date,
      this.flowLevel,
      this.moods,
      this.physicalSymptoms});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cycleId'] = Variable<String>(cycleId);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || flowLevel != null) {
      map['flowLevel'] = Variable<String>(flowLevel);
    }
    if (!nullToAbsent || moods != null) {
      map['moods'] = Variable<String>(moods);
    }
    if (!nullToAbsent || physicalSymptoms != null) {
      map['physicalSymptoms'] = Variable<String>(physicalSymptoms);
    }
    return map;
  }

  PeriodLogsCompanion toCompanion(bool nullToAbsent) {
    return PeriodLogsCompanion(
      id: Value(id),
      cycleId: Value(cycleId),
      date: Value(date),
      flowLevel: flowLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(flowLevel),
      moods:
          moods == null && nullToAbsent ? const Value.absent() : Value(moods),
      physicalSymptoms: physicalSymptoms == null && nullToAbsent
          ? const Value.absent()
          : Value(physicalSymptoms),
    );
  }

  factory PeriodLogEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodLogEntry(
      id: serializer.fromJson<String>(json['id']),
      cycleId: serializer.fromJson<String>(json['cycleId']),
      date: serializer.fromJson<DateTime>(json['date']),
      flowLevel: serializer.fromJson<String?>(json['flowLevel']),
      moods: serializer.fromJson<String?>(json['moods']),
      physicalSymptoms: serializer.fromJson<String?>(json['physicalSymptoms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cycleId': serializer.toJson<String>(cycleId),
      'date': serializer.toJson<DateTime>(date),
      'flowLevel': serializer.toJson<String?>(flowLevel),
      'moods': serializer.toJson<String?>(moods),
      'physicalSymptoms': serializer.toJson<String?>(physicalSymptoms),
    };
  }

  PeriodLogEntry copyWith(
          {String? id,
          String? cycleId,
          DateTime? date,
          Value<String?> flowLevel = const Value.absent(),
          Value<String?> moods = const Value.absent(),
          Value<String?> physicalSymptoms = const Value.absent()}) =>
      PeriodLogEntry(
        id: id ?? this.id,
        cycleId: cycleId ?? this.cycleId,
        date: date ?? this.date,
        flowLevel: flowLevel.present ? flowLevel.value : this.flowLevel,
        moods: moods.present ? moods.value : this.moods,
        physicalSymptoms: physicalSymptoms.present
            ? physicalSymptoms.value
            : this.physicalSymptoms,
      );
  PeriodLogEntry copyWithCompanion(PeriodLogsCompanion data) {
    return PeriodLogEntry(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      date: data.date.present ? data.date.value : this.date,
      flowLevel: data.flowLevel.present ? data.flowLevel.value : this.flowLevel,
      moods: data.moods.present ? data.moods.value : this.moods,
      physicalSymptoms: data.physicalSymptoms.present
          ? data.physicalSymptoms.value
          : this.physicalSymptoms,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodLogEntry(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('date: $date, ')
          ..write('flowLevel: $flowLevel, ')
          ..write('moods: $moods, ')
          ..write('physicalSymptoms: $physicalSymptoms')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, cycleId, date, flowLevel, moods, physicalSymptoms);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodLogEntry &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.date == this.date &&
          other.flowLevel == this.flowLevel &&
          other.moods == this.moods &&
          other.physicalSymptoms == this.physicalSymptoms);
}

class PeriodLogsCompanion extends UpdateCompanion<PeriodLogEntry> {
  final Value<String> id;
  final Value<String> cycleId;
  final Value<DateTime> date;
  final Value<String?> flowLevel;
  final Value<String?> moods;
  final Value<String?> physicalSymptoms;
  final Value<int> rowid;
  const PeriodLogsCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.date = const Value.absent(),
    this.flowLevel = const Value.absent(),
    this.moods = const Value.absent(),
    this.physicalSymptoms = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeriodLogsCompanion.insert({
    required String id,
    required String cycleId,
    required DateTime date,
    this.flowLevel = const Value.absent(),
    this.moods = const Value.absent(),
    this.physicalSymptoms = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        cycleId = Value(cycleId),
        date = Value(date);
  static Insertable<PeriodLogEntry> custom({
    Expression<String>? id,
    Expression<String>? cycleId,
    Expression<DateTime>? date,
    Expression<String>? flowLevel,
    Expression<String>? moods,
    Expression<String>? physicalSymptoms,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycleId': cycleId,
      if (date != null) 'date': date,
      if (flowLevel != null) 'flowLevel': flowLevel,
      if (moods != null) 'moods': moods,
      if (physicalSymptoms != null) 'physicalSymptoms': physicalSymptoms,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeriodLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? cycleId,
      Value<DateTime>? date,
      Value<String?>? flowLevel,
      Value<String?>? moods,
      Value<String?>? physicalSymptoms,
      Value<int>? rowid}) {
    return PeriodLogsCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      date: date ?? this.date,
      flowLevel: flowLevel ?? this.flowLevel,
      moods: moods ?? this.moods,
      physicalSymptoms: physicalSymptoms ?? this.physicalSymptoms,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cycleId.present) {
      map['cycleId'] = Variable<String>(cycleId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (flowLevel.present) {
      map['flowLevel'] = Variable<String>(flowLevel.value);
    }
    if (moods.present) {
      map['moods'] = Variable<String>(moods.value);
    }
    if (physicalSymptoms.present) {
      map['physicalSymptoms'] = Variable<String>(physicalSymptoms.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodLogsCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('date: $date, ')
          ..write('flowLevel: $flowLevel, ')
          ..write('moods: $moods, ')
          ..write('physicalSymptoms: $physicalSymptoms, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VitalLogsTable extends VitalLogs
    with TableInfo<$VitalLogsTable, VitalLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VitalLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profileId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES profiles (id) ON DELETE CASCADE'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _value1Meta = const VerificationMeta('value1');
  @override
  late final GeneratedColumn<double> value1 = GeneratedColumn<double>(
      'value1', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _value2Meta = const VerificationMeta('value2');
  @override
  late final GeneratedColumn<double> value2 = GeneratedColumn<double>(
      'value2', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, profileId, type, date, value1, value2, unit, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vital_logs';
  @override
  VerificationContext validateIntegrity(Insertable<VitalLogEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profileId')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profileId']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('value1')) {
      context.handle(_value1Meta,
          value1.isAcceptableOrUnknown(data['value1']!, _value1Meta));
    } else if (isInserting) {
      context.missing(_value1Meta);
    }
    if (data.containsKey('value2')) {
      context.handle(_value2Meta,
          value2.isAcceptableOrUnknown(data['value2']!, _value2Meta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VitalLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VitalLogEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profileId'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      value1: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value1'])!,
      value2: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value2']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $VitalLogsTable createAlias(String alias) {
    return $VitalLogsTable(attachedDatabase, alias);
  }
}

class VitalLogEntry extends DataClass implements Insertable<VitalLogEntry> {
  final String id;
  final String profileId;
  final String type;
  final DateTime date;
  final double value1;
  final double? value2;
  final String unit;
  final String? note;
  const VitalLogEntry(
      {required this.id,
      required this.profileId,
      required this.type,
      required this.date,
      required this.value1,
      this.value2,
      required this.unit,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profileId'] = Variable<String>(profileId);
    map['type'] = Variable<String>(type);
    map['date'] = Variable<DateTime>(date);
    map['value1'] = Variable<double>(value1);
    if (!nullToAbsent || value2 != null) {
      map['value2'] = Variable<double>(value2);
    }
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  VitalLogsCompanion toCompanion(bool nullToAbsent) {
    return VitalLogsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      type: Value(type),
      date: Value(date),
      value1: Value(value1),
      value2:
          value2 == null && nullToAbsent ? const Value.absent() : Value(value2),
      unit: Value(unit),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory VitalLogEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VitalLogEntry(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      type: serializer.fromJson<String>(json['type']),
      date: serializer.fromJson<DateTime>(json['date']),
      value1: serializer.fromJson<double>(json['value1']),
      value2: serializer.fromJson<double?>(json['value2']),
      unit: serializer.fromJson<String>(json['unit']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'type': serializer.toJson<String>(type),
      'date': serializer.toJson<DateTime>(date),
      'value1': serializer.toJson<double>(value1),
      'value2': serializer.toJson<double?>(value2),
      'unit': serializer.toJson<String>(unit),
      'note': serializer.toJson<String?>(note),
    };
  }

  VitalLogEntry copyWith(
          {String? id,
          String? profileId,
          String? type,
          DateTime? date,
          double? value1,
          Value<double?> value2 = const Value.absent(),
          String? unit,
          Value<String?> note = const Value.absent()}) =>
      VitalLogEntry(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        type: type ?? this.type,
        date: date ?? this.date,
        value1: value1 ?? this.value1,
        value2: value2.present ? value2.value : this.value2,
        unit: unit ?? this.unit,
        note: note.present ? note.value : this.note,
      );
  VitalLogEntry copyWithCompanion(VitalLogsCompanion data) {
    return VitalLogEntry(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      type: data.type.present ? data.type.value : this.type,
      date: data.date.present ? data.date.value : this.date,
      value1: data.value1.present ? data.value1.value : this.value1,
      value2: data.value2.present ? data.value2.value : this.value2,
      unit: data.unit.present ? data.unit.value : this.unit,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VitalLogEntry(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('type: $type, ')
          ..write('date: $date, ')
          ..write('value1: $value1, ')
          ..write('value2: $value2, ')
          ..write('unit: $unit, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileId, type, date, value1, value2, unit, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VitalLogEntry &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.type == this.type &&
          other.date == this.date &&
          other.value1 == this.value1 &&
          other.value2 == this.value2 &&
          other.unit == this.unit &&
          other.note == this.note);
}

class VitalLogsCompanion extends UpdateCompanion<VitalLogEntry> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> type;
  final Value<DateTime> date;
  final Value<double> value1;
  final Value<double?> value2;
  final Value<String> unit;
  final Value<String?> note;
  final Value<int> rowid;
  const VitalLogsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.type = const Value.absent(),
    this.date = const Value.absent(),
    this.value1 = const Value.absent(),
    this.value2 = const Value.absent(),
    this.unit = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VitalLogsCompanion.insert({
    required String id,
    required String profileId,
    required String type,
    required DateTime date,
    required double value1,
    this.value2 = const Value.absent(),
    required String unit,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        type = Value(type),
        date = Value(date),
        value1 = Value(value1),
        unit = Value(unit);
  static Insertable<VitalLogEntry> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? type,
    Expression<DateTime>? date,
    Expression<double>? value1,
    Expression<double>? value2,
    Expression<String>? unit,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profileId': profileId,
      if (type != null) 'type': type,
      if (date != null) 'date': date,
      if (value1 != null) 'value1': value1,
      if (value2 != null) 'value2': value2,
      if (unit != null) 'unit': unit,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VitalLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<String>? type,
      Value<DateTime>? date,
      Value<double>? value1,
      Value<double?>? value2,
      Value<String>? unit,
      Value<String?>? note,
      Value<int>? rowid}) {
    return VitalLogsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      type: type ?? this.type,
      date: date ?? this.date,
      value1: value1 ?? this.value1,
      value2: value2 ?? this.value2,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profileId'] = Variable<String>(profileId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (value1.present) {
      map['value1'] = Variable<double>(value1.value);
    }
    if (value2.present) {
      map['value2'] = Variable<double>(value2.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VitalLogsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('type: $type, ')
          ..write('date: $date, ')
          ..write('value1: $value1, ')
          ..write('value2: $value2, ')
          ..write('unit: $unit, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingEntry(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingEntry extends DataClass implements Insertable<SettingEntry> {
  final String key;
  final String? value;
  const SettingEntry({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
    );
  }

  factory SettingEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  SettingEntry copyWith(
          {String? key, Value<String?> value = const Value.absent()}) =>
      SettingEntry(
        key: key ?? this.key,
        value: value.present ? value.value : this.value,
      );
  SettingEntry copyWithCompanion(SettingsCompanion data) {
    return SettingEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingEntry> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<SettingEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? key, Value<String?>? value, Value<int>? rowid}) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmergencyContactsTable extends EmergencyContacts
    with TableInfo<$EmergencyContactsTable, EmergencyContactEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmergencyContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profileId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES profiles (id) ON DELETE CASCADE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _relationshipMeta =
      const VerificationMeta('relationship');
  @override
  late final GeneratedColumn<String> relationship = GeneratedColumn<String>(
      'relationship', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneNumberMeta =
      const VerificationMeta('phoneNumber');
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
      'phoneNumber', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, profileId, name, relationship, phoneNumber];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emergency_contacts';
  @override
  VerificationContext validateIntegrity(
      Insertable<EmergencyContactEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profileId')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profileId']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('relationship')) {
      context.handle(
          _relationshipMeta,
          relationship.isAcceptableOrUnknown(
              data['relationship']!, _relationshipMeta));
    } else if (isInserting) {
      context.missing(_relationshipMeta);
    }
    if (data.containsKey('phoneNumber')) {
      context.handle(
          _phoneNumberMeta,
          phoneNumber.isAcceptableOrUnknown(
              data['phoneNumber']!, _phoneNumberMeta));
    } else if (isInserting) {
      context.missing(_phoneNumberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmergencyContactEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmergencyContactEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profileId'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      relationship: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relationship'])!,
      phoneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phoneNumber'])!,
    );
  }

  @override
  $EmergencyContactsTable createAlias(String alias) {
    return $EmergencyContactsTable(attachedDatabase, alias);
  }
}

class EmergencyContactEntry extends DataClass
    implements Insertable<EmergencyContactEntry> {
  final String id;
  final String profileId;
  final String name;
  final String relationship;
  final String phoneNumber;
  const EmergencyContactEntry(
      {required this.id,
      required this.profileId,
      required this.name,
      required this.relationship,
      required this.phoneNumber});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profileId'] = Variable<String>(profileId);
    map['name'] = Variable<String>(name);
    map['relationship'] = Variable<String>(relationship);
    map['phoneNumber'] = Variable<String>(phoneNumber);
    return map;
  }

  EmergencyContactsCompanion toCompanion(bool nullToAbsent) {
    return EmergencyContactsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      relationship: Value(relationship),
      phoneNumber: Value(phoneNumber),
    );
  }

  factory EmergencyContactEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmergencyContactEntry(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      relationship: serializer.fromJson<String>(json['relationship']),
      phoneNumber: serializer.fromJson<String>(json['phoneNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'name': serializer.toJson<String>(name),
      'relationship': serializer.toJson<String>(relationship),
      'phoneNumber': serializer.toJson<String>(phoneNumber),
    };
  }

  EmergencyContactEntry copyWith(
          {String? id,
          String? profileId,
          String? name,
          String? relationship,
          String? phoneNumber}) =>
      EmergencyContactEntry(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        name: name ?? this.name,
        relationship: relationship ?? this.relationship,
        phoneNumber: phoneNumber ?? this.phoneNumber,
      );
  EmergencyContactEntry copyWithCompanion(EmergencyContactsCompanion data) {
    return EmergencyContactEntry(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      relationship: data.relationship.present
          ? data.relationship.value
          : this.relationship,
      phoneNumber:
          data.phoneNumber.present ? data.phoneNumber.value : this.phoneNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyContactEntry(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('relationship: $relationship, ')
          ..write('phoneNumber: $phoneNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileId, name, relationship, phoneNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmergencyContactEntry &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.relationship == this.relationship &&
          other.phoneNumber == this.phoneNumber);
}

class EmergencyContactsCompanion
    extends UpdateCompanion<EmergencyContactEntry> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> name;
  final Value<String> relationship;
  final Value<String> phoneNumber;
  final Value<int> rowid;
  const EmergencyContactsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.relationship = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmergencyContactsCompanion.insert({
    required String id,
    required String profileId,
    required String name,
    required String relationship,
    required String phoneNumber,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        name = Value(name),
        relationship = Value(relationship),
        phoneNumber = Value(phoneNumber);
  static Insertable<EmergencyContactEntry> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? name,
    Expression<String>? relationship,
    Expression<String>? phoneNumber,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profileId': profileId,
      if (name != null) 'name': name,
      if (relationship != null) 'relationship': relationship,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmergencyContactsCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<String>? name,
      Value<String>? relationship,
      Value<String>? phoneNumber,
      Value<int>? rowid}) {
    return EmergencyContactsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profileId'] = Variable<String>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (relationship.present) {
      map['relationship'] = Variable<String>(relationship.value);
    }
    if (phoneNumber.present) {
      map['phoneNumber'] = Variable<String>(phoneNumber.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyContactsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('relationship: $relationship, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LockScreenSettingsTable extends LockScreenSettings
    with TableInfo<$LockScreenSettingsTable, LockScreenSettingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LockScreenSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profileId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES profiles (id) ON DELETE CASCADE'));
  static const VerificationMeta _showNameMeta =
      const VerificationMeta('showName');
  @override
  late final GeneratedColumn<bool> showName = GeneratedColumn<bool>(
      'showName', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("showName" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showAgeMeta =
      const VerificationMeta('showAge');
  @override
  late final GeneratedColumn<bool> showAge = GeneratedColumn<bool>(
      'showAge', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("showAge" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showBloodTypeMeta =
      const VerificationMeta('showBloodType');
  @override
  late final GeneratedColumn<bool> showBloodType = GeneratedColumn<bool>(
      'showBloodType', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("showBloodType" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showOrganDonorMeta =
      const VerificationMeta('showOrganDonor');
  @override
  late final GeneratedColumn<bool> showOrganDonor = GeneratedColumn<bool>(
      'showOrganDonor', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("showOrganDonor" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showChronicConditionsMeta =
      const VerificationMeta('showChronicConditions');
  @override
  late final GeneratedColumn<bool> showChronicConditions =
      GeneratedColumn<bool>('showChronicConditions', aliasedName, true,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("showChronicConditions" IN (0, 1))'),
          defaultValue: const Constant(true));
  static const VerificationMeta _showAllergiesMeta =
      const VerificationMeta('showAllergies');
  @override
  late final GeneratedColumn<bool> showAllergies = GeneratedColumn<bool>(
      'showAllergies', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("showAllergies" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showMedicationsMeta =
      const VerificationMeta('showMedications');
  @override
  late final GeneratedColumn<bool> showMedications = GeneratedColumn<bool>(
      'showMedications', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("showMedications" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showContactsMeta =
      const VerificationMeta('showContacts');
  @override
  late final GeneratedColumn<bool> showContacts = GeneratedColumn<bool>(
      'showContacts', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("showContacts" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showInsuranceMeta =
      const VerificationMeta('showInsurance');
  @override
  late final GeneratedColumn<bool> showInsurance = GeneratedColumn<bool>(
      'showInsurance', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("showInsurance" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isEnabledMeta =
      const VerificationMeta('isEnabled');
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
      'isEnabled', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("isEnabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        profileId,
        showName,
        showAge,
        showBloodType,
        showOrganDonor,
        showChronicConditions,
        showAllergies,
        showMedications,
        showContacts,
        showInsurance,
        isEnabled
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lock_screen_settings';
  @override
  VerificationContext validateIntegrity(
      Insertable<LockScreenSettingEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profileId')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profileId']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('showName')) {
      context.handle(_showNameMeta,
          showName.isAcceptableOrUnknown(data['showName']!, _showNameMeta));
    }
    if (data.containsKey('showAge')) {
      context.handle(_showAgeMeta,
          showAge.isAcceptableOrUnknown(data['showAge']!, _showAgeMeta));
    }
    if (data.containsKey('showBloodType')) {
      context.handle(
          _showBloodTypeMeta,
          showBloodType.isAcceptableOrUnknown(
              data['showBloodType']!, _showBloodTypeMeta));
    }
    if (data.containsKey('showOrganDonor')) {
      context.handle(
          _showOrganDonorMeta,
          showOrganDonor.isAcceptableOrUnknown(
              data['showOrganDonor']!, _showOrganDonorMeta));
    }
    if (data.containsKey('showChronicConditions')) {
      context.handle(
          _showChronicConditionsMeta,
          showChronicConditions.isAcceptableOrUnknown(
              data['showChronicConditions']!, _showChronicConditionsMeta));
    }
    if (data.containsKey('showAllergies')) {
      context.handle(
          _showAllergiesMeta,
          showAllergies.isAcceptableOrUnknown(
              data['showAllergies']!, _showAllergiesMeta));
    }
    if (data.containsKey('showMedications')) {
      context.handle(
          _showMedicationsMeta,
          showMedications.isAcceptableOrUnknown(
              data['showMedications']!, _showMedicationsMeta));
    }
    if (data.containsKey('showContacts')) {
      context.handle(
          _showContactsMeta,
          showContacts.isAcceptableOrUnknown(
              data['showContacts']!, _showContactsMeta));
    }
    if (data.containsKey('showInsurance')) {
      context.handle(
          _showInsuranceMeta,
          showInsurance.isAcceptableOrUnknown(
              data['showInsurance']!, _showInsuranceMeta));
    }
    if (data.containsKey('isEnabled')) {
      context.handle(_isEnabledMeta,
          isEnabled.isAcceptableOrUnknown(data['isEnabled']!, _isEnabledMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId};
  @override
  LockScreenSettingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LockScreenSettingEntry(
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profileId'])!,
      showName: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}showName']),
      showAge: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}showAge']),
      showBloodType: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}showBloodType']),
      showOrganDonor: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}showOrganDonor']),
      showChronicConditions: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}showChronicConditions']),
      showAllergies: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}showAllergies']),
      showMedications: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}showMedications']),
      showContacts: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}showContacts']),
      showInsurance: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}showInsurance']),
      isEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}isEnabled']),
    );
  }

  @override
  $LockScreenSettingsTable createAlias(String alias) {
    return $LockScreenSettingsTable(attachedDatabase, alias);
  }
}

class LockScreenSettingEntry extends DataClass
    implements Insertable<LockScreenSettingEntry> {
  final String profileId;
  final bool? showName;
  final bool? showAge;
  final bool? showBloodType;
  final bool? showOrganDonor;
  final bool? showChronicConditions;
  final bool? showAllergies;
  final bool? showMedications;
  final bool? showContacts;
  final bool? showInsurance;
  final bool? isEnabled;
  const LockScreenSettingEntry(
      {required this.profileId,
      this.showName,
      this.showAge,
      this.showBloodType,
      this.showOrganDonor,
      this.showChronicConditions,
      this.showAllergies,
      this.showMedications,
      this.showContacts,
      this.showInsurance,
      this.isEnabled});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profileId'] = Variable<String>(profileId);
    if (!nullToAbsent || showName != null) {
      map['showName'] = Variable<bool>(showName);
    }
    if (!nullToAbsent || showAge != null) {
      map['showAge'] = Variable<bool>(showAge);
    }
    if (!nullToAbsent || showBloodType != null) {
      map['showBloodType'] = Variable<bool>(showBloodType);
    }
    if (!nullToAbsent || showOrganDonor != null) {
      map['showOrganDonor'] = Variable<bool>(showOrganDonor);
    }
    if (!nullToAbsent || showChronicConditions != null) {
      map['showChronicConditions'] = Variable<bool>(showChronicConditions);
    }
    if (!nullToAbsent || showAllergies != null) {
      map['showAllergies'] = Variable<bool>(showAllergies);
    }
    if (!nullToAbsent || showMedications != null) {
      map['showMedications'] = Variable<bool>(showMedications);
    }
    if (!nullToAbsent || showContacts != null) {
      map['showContacts'] = Variable<bool>(showContacts);
    }
    if (!nullToAbsent || showInsurance != null) {
      map['showInsurance'] = Variable<bool>(showInsurance);
    }
    if (!nullToAbsent || isEnabled != null) {
      map['isEnabled'] = Variable<bool>(isEnabled);
    }
    return map;
  }

  LockScreenSettingsCompanion toCompanion(bool nullToAbsent) {
    return LockScreenSettingsCompanion(
      profileId: Value(profileId),
      showName: showName == null && nullToAbsent
          ? const Value.absent()
          : Value(showName),
      showAge: showAge == null && nullToAbsent
          ? const Value.absent()
          : Value(showAge),
      showBloodType: showBloodType == null && nullToAbsent
          ? const Value.absent()
          : Value(showBloodType),
      showOrganDonor: showOrganDonor == null && nullToAbsent
          ? const Value.absent()
          : Value(showOrganDonor),
      showChronicConditions: showChronicConditions == null && nullToAbsent
          ? const Value.absent()
          : Value(showChronicConditions),
      showAllergies: showAllergies == null && nullToAbsent
          ? const Value.absent()
          : Value(showAllergies),
      showMedications: showMedications == null && nullToAbsent
          ? const Value.absent()
          : Value(showMedications),
      showContacts: showContacts == null && nullToAbsent
          ? const Value.absent()
          : Value(showContacts),
      showInsurance: showInsurance == null && nullToAbsent
          ? const Value.absent()
          : Value(showInsurance),
      isEnabled: isEnabled == null && nullToAbsent
          ? const Value.absent()
          : Value(isEnabled),
    );
  }

  factory LockScreenSettingEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LockScreenSettingEntry(
      profileId: serializer.fromJson<String>(json['profileId']),
      showName: serializer.fromJson<bool?>(json['showName']),
      showAge: serializer.fromJson<bool?>(json['showAge']),
      showBloodType: serializer.fromJson<bool?>(json['showBloodType']),
      showOrganDonor: serializer.fromJson<bool?>(json['showOrganDonor']),
      showChronicConditions:
          serializer.fromJson<bool?>(json['showChronicConditions']),
      showAllergies: serializer.fromJson<bool?>(json['showAllergies']),
      showMedications: serializer.fromJson<bool?>(json['showMedications']),
      showContacts: serializer.fromJson<bool?>(json['showContacts']),
      showInsurance: serializer.fromJson<bool?>(json['showInsurance']),
      isEnabled: serializer.fromJson<bool?>(json['isEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<String>(profileId),
      'showName': serializer.toJson<bool?>(showName),
      'showAge': serializer.toJson<bool?>(showAge),
      'showBloodType': serializer.toJson<bool?>(showBloodType),
      'showOrganDonor': serializer.toJson<bool?>(showOrganDonor),
      'showChronicConditions': serializer.toJson<bool?>(showChronicConditions),
      'showAllergies': serializer.toJson<bool?>(showAllergies),
      'showMedications': serializer.toJson<bool?>(showMedications),
      'showContacts': serializer.toJson<bool?>(showContacts),
      'showInsurance': serializer.toJson<bool?>(showInsurance),
      'isEnabled': serializer.toJson<bool?>(isEnabled),
    };
  }

  LockScreenSettingEntry copyWith(
          {String? profileId,
          Value<bool?> showName = const Value.absent(),
          Value<bool?> showAge = const Value.absent(),
          Value<bool?> showBloodType = const Value.absent(),
          Value<bool?> showOrganDonor = const Value.absent(),
          Value<bool?> showChronicConditions = const Value.absent(),
          Value<bool?> showAllergies = const Value.absent(),
          Value<bool?> showMedications = const Value.absent(),
          Value<bool?> showContacts = const Value.absent(),
          Value<bool?> showInsurance = const Value.absent(),
          Value<bool?> isEnabled = const Value.absent()}) =>
      LockScreenSettingEntry(
        profileId: profileId ?? this.profileId,
        showName: showName.present ? showName.value : this.showName,
        showAge: showAge.present ? showAge.value : this.showAge,
        showBloodType:
            showBloodType.present ? showBloodType.value : this.showBloodType,
        showOrganDonor:
            showOrganDonor.present ? showOrganDonor.value : this.showOrganDonor,
        showChronicConditions: showChronicConditions.present
            ? showChronicConditions.value
            : this.showChronicConditions,
        showAllergies:
            showAllergies.present ? showAllergies.value : this.showAllergies,
        showMedications: showMedications.present
            ? showMedications.value
            : this.showMedications,
        showContacts:
            showContacts.present ? showContacts.value : this.showContacts,
        showInsurance:
            showInsurance.present ? showInsurance.value : this.showInsurance,
        isEnabled: isEnabled.present ? isEnabled.value : this.isEnabled,
      );
  LockScreenSettingEntry copyWithCompanion(LockScreenSettingsCompanion data) {
    return LockScreenSettingEntry(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      showName: data.showName.present ? data.showName.value : this.showName,
      showAge: data.showAge.present ? data.showAge.value : this.showAge,
      showBloodType: data.showBloodType.present
          ? data.showBloodType.value
          : this.showBloodType,
      showOrganDonor: data.showOrganDonor.present
          ? data.showOrganDonor.value
          : this.showOrganDonor,
      showChronicConditions: data.showChronicConditions.present
          ? data.showChronicConditions.value
          : this.showChronicConditions,
      showAllergies: data.showAllergies.present
          ? data.showAllergies.value
          : this.showAllergies,
      showMedications: data.showMedications.present
          ? data.showMedications.value
          : this.showMedications,
      showContacts: data.showContacts.present
          ? data.showContacts.value
          : this.showContacts,
      showInsurance: data.showInsurance.present
          ? data.showInsurance.value
          : this.showInsurance,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LockScreenSettingEntry(')
          ..write('profileId: $profileId, ')
          ..write('showName: $showName, ')
          ..write('showAge: $showAge, ')
          ..write('showBloodType: $showBloodType, ')
          ..write('showOrganDonor: $showOrganDonor, ')
          ..write('showChronicConditions: $showChronicConditions, ')
          ..write('showAllergies: $showAllergies, ')
          ..write('showMedications: $showMedications, ')
          ..write('showContacts: $showContacts, ')
          ..write('showInsurance: $showInsurance, ')
          ..write('isEnabled: $isEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      profileId,
      showName,
      showAge,
      showBloodType,
      showOrganDonor,
      showChronicConditions,
      showAllergies,
      showMedications,
      showContacts,
      showInsurance,
      isEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LockScreenSettingEntry &&
          other.profileId == this.profileId &&
          other.showName == this.showName &&
          other.showAge == this.showAge &&
          other.showBloodType == this.showBloodType &&
          other.showOrganDonor == this.showOrganDonor &&
          other.showChronicConditions == this.showChronicConditions &&
          other.showAllergies == this.showAllergies &&
          other.showMedications == this.showMedications &&
          other.showContacts == this.showContacts &&
          other.showInsurance == this.showInsurance &&
          other.isEnabled == this.isEnabled);
}

class LockScreenSettingsCompanion
    extends UpdateCompanion<LockScreenSettingEntry> {
  final Value<String> profileId;
  final Value<bool?> showName;
  final Value<bool?> showAge;
  final Value<bool?> showBloodType;
  final Value<bool?> showOrganDonor;
  final Value<bool?> showChronicConditions;
  final Value<bool?> showAllergies;
  final Value<bool?> showMedications;
  final Value<bool?> showContacts;
  final Value<bool?> showInsurance;
  final Value<bool?> isEnabled;
  final Value<int> rowid;
  const LockScreenSettingsCompanion({
    this.profileId = const Value.absent(),
    this.showName = const Value.absent(),
    this.showAge = const Value.absent(),
    this.showBloodType = const Value.absent(),
    this.showOrganDonor = const Value.absent(),
    this.showChronicConditions = const Value.absent(),
    this.showAllergies = const Value.absent(),
    this.showMedications = const Value.absent(),
    this.showContacts = const Value.absent(),
    this.showInsurance = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LockScreenSettingsCompanion.insert({
    required String profileId,
    this.showName = const Value.absent(),
    this.showAge = const Value.absent(),
    this.showBloodType = const Value.absent(),
    this.showOrganDonor = const Value.absent(),
    this.showChronicConditions = const Value.absent(),
    this.showAllergies = const Value.absent(),
    this.showMedications = const Value.absent(),
    this.showContacts = const Value.absent(),
    this.showInsurance = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId);
  static Insertable<LockScreenSettingEntry> custom({
    Expression<String>? profileId,
    Expression<bool>? showName,
    Expression<bool>? showAge,
    Expression<bool>? showBloodType,
    Expression<bool>? showOrganDonor,
    Expression<bool>? showChronicConditions,
    Expression<bool>? showAllergies,
    Expression<bool>? showMedications,
    Expression<bool>? showContacts,
    Expression<bool>? showInsurance,
    Expression<bool>? isEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profileId': profileId,
      if (showName != null) 'showName': showName,
      if (showAge != null) 'showAge': showAge,
      if (showBloodType != null) 'showBloodType': showBloodType,
      if (showOrganDonor != null) 'showOrganDonor': showOrganDonor,
      if (showChronicConditions != null)
        'showChronicConditions': showChronicConditions,
      if (showAllergies != null) 'showAllergies': showAllergies,
      if (showMedications != null) 'showMedications': showMedications,
      if (showContacts != null) 'showContacts': showContacts,
      if (showInsurance != null) 'showInsurance': showInsurance,
      if (isEnabled != null) 'isEnabled': isEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LockScreenSettingsCompanion copyWith(
      {Value<String>? profileId,
      Value<bool?>? showName,
      Value<bool?>? showAge,
      Value<bool?>? showBloodType,
      Value<bool?>? showOrganDonor,
      Value<bool?>? showChronicConditions,
      Value<bool?>? showAllergies,
      Value<bool?>? showMedications,
      Value<bool?>? showContacts,
      Value<bool?>? showInsurance,
      Value<bool?>? isEnabled,
      Value<int>? rowid}) {
    return LockScreenSettingsCompanion(
      profileId: profileId ?? this.profileId,
      showName: showName ?? this.showName,
      showAge: showAge ?? this.showAge,
      showBloodType: showBloodType ?? this.showBloodType,
      showOrganDonor: showOrganDonor ?? this.showOrganDonor,
      showChronicConditions:
          showChronicConditions ?? this.showChronicConditions,
      showAllergies: showAllergies ?? this.showAllergies,
      showMedications: showMedications ?? this.showMedications,
      showContacts: showContacts ?? this.showContacts,
      showInsurance: showInsurance ?? this.showInsurance,
      isEnabled: isEnabled ?? this.isEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profileId'] = Variable<String>(profileId.value);
    }
    if (showName.present) {
      map['showName'] = Variable<bool>(showName.value);
    }
    if (showAge.present) {
      map['showAge'] = Variable<bool>(showAge.value);
    }
    if (showBloodType.present) {
      map['showBloodType'] = Variable<bool>(showBloodType.value);
    }
    if (showOrganDonor.present) {
      map['showOrganDonor'] = Variable<bool>(showOrganDonor.value);
    }
    if (showChronicConditions.present) {
      map['showChronicConditions'] =
          Variable<bool>(showChronicConditions.value);
    }
    if (showAllergies.present) {
      map['showAllergies'] = Variable<bool>(showAllergies.value);
    }
    if (showMedications.present) {
      map['showMedications'] = Variable<bool>(showMedications.value);
    }
    if (showContacts.present) {
      map['showContacts'] = Variable<bool>(showContacts.value);
    }
    if (showInsurance.present) {
      map['showInsurance'] = Variable<bool>(showInsurance.value);
    }
    if (isEnabled.present) {
      map['isEnabled'] = Variable<bool>(isEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LockScreenSettingsCompanion(')
          ..write('profileId: $profileId, ')
          ..write('showName: $showName, ')
          ..write('showAge: $showAge, ')
          ..write('showBloodType: $showBloodType, ')
          ..write('showOrganDonor: $showOrganDonor, ')
          ..write('showChronicConditions: $showChronicConditions, ')
          ..write('showAllergies: $showAllergies, ')
          ..write('showMedications: $showMedications, ')
          ..write('showContacts: $showContacts, ')
          ..write('showInsurance: $showInsurance, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InsuranceTable extends Insurance
    with TableInfo<$InsuranceTable, InsuranceEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InsuranceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profileId', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES profiles (id) ON DELETE CASCADE'));
  static const VerificationMeta _providerMeta =
      const VerificationMeta('provider');
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
      'provider', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planNameMeta =
      const VerificationMeta('planName');
  @override
  late final GeneratedColumn<String> planName = GeneratedColumn<String>(
      'planName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _policyNumberMeta =
      const VerificationMeta('policyNumber');
  @override
  late final GeneratedColumn<String> policyNumber = GeneratedColumn<String>(
      'policyNumber', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupNumberMeta =
      const VerificationMeta('groupNumber');
  @override
  late final GeneratedColumn<String> groupNumber = GeneratedColumn<String>(
      'groupNumber', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subscriberNameMeta =
      const VerificationMeta('subscriberName');
  @override
  late final GeneratedColumn<String> subscriberName = GeneratedColumn<String>(
      'subscriberName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _memberIdMeta =
      const VerificationMeta('memberId');
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
      'memberId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emergencyPhoneMeta =
      const VerificationMeta('emergencyPhone');
  @override
  late final GeneratedColumn<String> emergencyPhone = GeneratedColumn<String>(
      'emergencyPhone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _frontCardImageMeta =
      const VerificationMeta('frontCardImage');
  @override
  late final GeneratedColumn<String> frontCardImage = GeneratedColumn<String>(
      'frontCardImage', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _backCardImageMeta =
      const VerificationMeta('backCardImage');
  @override
  late final GeneratedColumn<String> backCardImage = GeneratedColumn<String>(
      'backCardImage', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        provider,
        planName,
        policyNumber,
        groupNumber,
        subscriberName,
        memberId,
        emergencyPhone,
        frontCardImage,
        backCardImage,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'insurance';
  @override
  VerificationContext validateIntegrity(Insertable<InsuranceEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profileId')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profileId']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(_providerMeta,
          provider.isAcceptableOrUnknown(data['provider']!, _providerMeta));
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('planName')) {
      context.handle(_planNameMeta,
          planName.isAcceptableOrUnknown(data['planName']!, _planNameMeta));
    }
    if (data.containsKey('policyNumber')) {
      context.handle(
          _policyNumberMeta,
          policyNumber.isAcceptableOrUnknown(
              data['policyNumber']!, _policyNumberMeta));
    } else if (isInserting) {
      context.missing(_policyNumberMeta);
    }
    if (data.containsKey('groupNumber')) {
      context.handle(
          _groupNumberMeta,
          groupNumber.isAcceptableOrUnknown(
              data['groupNumber']!, _groupNumberMeta));
    }
    if (data.containsKey('subscriberName')) {
      context.handle(
          _subscriberNameMeta,
          subscriberName.isAcceptableOrUnknown(
              data['subscriberName']!, _subscriberNameMeta));
    }
    if (data.containsKey('memberId')) {
      context.handle(_memberIdMeta,
          memberId.isAcceptableOrUnknown(data['memberId']!, _memberIdMeta));
    }
    if (data.containsKey('emergencyPhone')) {
      context.handle(
          _emergencyPhoneMeta,
          emergencyPhone.isAcceptableOrUnknown(
              data['emergencyPhone']!, _emergencyPhoneMeta));
    }
    if (data.containsKey('frontCardImage')) {
      context.handle(
          _frontCardImageMeta,
          frontCardImage.isAcceptableOrUnknown(
              data['frontCardImage']!, _frontCardImageMeta));
    }
    if (data.containsKey('backCardImage')) {
      context.handle(
          _backCardImageMeta,
          backCardImage.isAcceptableOrUnknown(
              data['backCardImage']!, _backCardImageMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InsuranceEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InsuranceEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profileId'])!,
      provider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider'])!,
      planName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}planName']),
      policyNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}policyNumber'])!,
      groupNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}groupNumber']),
      subscriberName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subscriberName']),
      memberId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memberId']),
      emergencyPhone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emergencyPhone']),
      frontCardImage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frontCardImage']),
      backCardImage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}backCardImage']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $InsuranceTable createAlias(String alias) {
    return $InsuranceTable(attachedDatabase, alias);
  }
}

class InsuranceEntry extends DataClass implements Insertable<InsuranceEntry> {
  final String id;
  final String profileId;
  final String provider;
  final String? planName;
  final String policyNumber;
  final String? groupNumber;
  final String? subscriberName;
  final String? memberId;
  final String? emergencyPhone;
  final String? frontCardImage;
  final String? backCardImage;
  final String? notes;
  const InsuranceEntry(
      {required this.id,
      required this.profileId,
      required this.provider,
      this.planName,
      required this.policyNumber,
      this.groupNumber,
      this.subscriberName,
      this.memberId,
      this.emergencyPhone,
      this.frontCardImage,
      this.backCardImage,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profileId'] = Variable<String>(profileId);
    map['provider'] = Variable<String>(provider);
    if (!nullToAbsent || planName != null) {
      map['planName'] = Variable<String>(planName);
    }
    map['policyNumber'] = Variable<String>(policyNumber);
    if (!nullToAbsent || groupNumber != null) {
      map['groupNumber'] = Variable<String>(groupNumber);
    }
    if (!nullToAbsent || subscriberName != null) {
      map['subscriberName'] = Variable<String>(subscriberName);
    }
    if (!nullToAbsent || memberId != null) {
      map['memberId'] = Variable<String>(memberId);
    }
    if (!nullToAbsent || emergencyPhone != null) {
      map['emergencyPhone'] = Variable<String>(emergencyPhone);
    }
    if (!nullToAbsent || frontCardImage != null) {
      map['frontCardImage'] = Variable<String>(frontCardImage);
    }
    if (!nullToAbsent || backCardImage != null) {
      map['backCardImage'] = Variable<String>(backCardImage);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  InsuranceCompanion toCompanion(bool nullToAbsent) {
    return InsuranceCompanion(
      id: Value(id),
      profileId: Value(profileId),
      provider: Value(provider),
      planName: planName == null && nullToAbsent
          ? const Value.absent()
          : Value(planName),
      policyNumber: Value(policyNumber),
      groupNumber: groupNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(groupNumber),
      subscriberName: subscriberName == null && nullToAbsent
          ? const Value.absent()
          : Value(subscriberName),
      memberId: memberId == null && nullToAbsent
          ? const Value.absent()
          : Value(memberId),
      emergencyPhone: emergencyPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(emergencyPhone),
      frontCardImage: frontCardImage == null && nullToAbsent
          ? const Value.absent()
          : Value(frontCardImage),
      backCardImage: backCardImage == null && nullToAbsent
          ? const Value.absent()
          : Value(backCardImage),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory InsuranceEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InsuranceEntry(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      provider: serializer.fromJson<String>(json['provider']),
      planName: serializer.fromJson<String?>(json['planName']),
      policyNumber: serializer.fromJson<String>(json['policyNumber']),
      groupNumber: serializer.fromJson<String?>(json['groupNumber']),
      subscriberName: serializer.fromJson<String?>(json['subscriberName']),
      memberId: serializer.fromJson<String?>(json['memberId']),
      emergencyPhone: serializer.fromJson<String?>(json['emergencyPhone']),
      frontCardImage: serializer.fromJson<String?>(json['frontCardImage']),
      backCardImage: serializer.fromJson<String?>(json['backCardImage']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'provider': serializer.toJson<String>(provider),
      'planName': serializer.toJson<String?>(planName),
      'policyNumber': serializer.toJson<String>(policyNumber),
      'groupNumber': serializer.toJson<String?>(groupNumber),
      'subscriberName': serializer.toJson<String?>(subscriberName),
      'memberId': serializer.toJson<String?>(memberId),
      'emergencyPhone': serializer.toJson<String?>(emergencyPhone),
      'frontCardImage': serializer.toJson<String?>(frontCardImage),
      'backCardImage': serializer.toJson<String?>(backCardImage),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  InsuranceEntry copyWith(
          {String? id,
          String? profileId,
          String? provider,
          Value<String?> planName = const Value.absent(),
          String? policyNumber,
          Value<String?> groupNumber = const Value.absent(),
          Value<String?> subscriberName = const Value.absent(),
          Value<String?> memberId = const Value.absent(),
          Value<String?> emergencyPhone = const Value.absent(),
          Value<String?> frontCardImage = const Value.absent(),
          Value<String?> backCardImage = const Value.absent(),
          Value<String?> notes = const Value.absent()}) =>
      InsuranceEntry(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        provider: provider ?? this.provider,
        planName: planName.present ? planName.value : this.planName,
        policyNumber: policyNumber ?? this.policyNumber,
        groupNumber: groupNumber.present ? groupNumber.value : this.groupNumber,
        subscriberName:
            subscriberName.present ? subscriberName.value : this.subscriberName,
        memberId: memberId.present ? memberId.value : this.memberId,
        emergencyPhone:
            emergencyPhone.present ? emergencyPhone.value : this.emergencyPhone,
        frontCardImage:
            frontCardImage.present ? frontCardImage.value : this.frontCardImage,
        backCardImage:
            backCardImage.present ? backCardImage.value : this.backCardImage,
        notes: notes.present ? notes.value : this.notes,
      );
  InsuranceEntry copyWithCompanion(InsuranceCompanion data) {
    return InsuranceEntry(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      provider: data.provider.present ? data.provider.value : this.provider,
      planName: data.planName.present ? data.planName.value : this.planName,
      policyNumber: data.policyNumber.present
          ? data.policyNumber.value
          : this.policyNumber,
      groupNumber:
          data.groupNumber.present ? data.groupNumber.value : this.groupNumber,
      subscriberName: data.subscriberName.present
          ? data.subscriberName.value
          : this.subscriberName,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      emergencyPhone: data.emergencyPhone.present
          ? data.emergencyPhone.value
          : this.emergencyPhone,
      frontCardImage: data.frontCardImage.present
          ? data.frontCardImage.value
          : this.frontCardImage,
      backCardImage: data.backCardImage.present
          ? data.backCardImage.value
          : this.backCardImage,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InsuranceEntry(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('provider: $provider, ')
          ..write('planName: $planName, ')
          ..write('policyNumber: $policyNumber, ')
          ..write('groupNumber: $groupNumber, ')
          ..write('subscriberName: $subscriberName, ')
          ..write('memberId: $memberId, ')
          ..write('emergencyPhone: $emergencyPhone, ')
          ..write('frontCardImage: $frontCardImage, ')
          ..write('backCardImage: $backCardImage, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      profileId,
      provider,
      planName,
      policyNumber,
      groupNumber,
      subscriberName,
      memberId,
      emergencyPhone,
      frontCardImage,
      backCardImage,
      notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InsuranceEntry &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.provider == this.provider &&
          other.planName == this.planName &&
          other.policyNumber == this.policyNumber &&
          other.groupNumber == this.groupNumber &&
          other.subscriberName == this.subscriberName &&
          other.memberId == this.memberId &&
          other.emergencyPhone == this.emergencyPhone &&
          other.frontCardImage == this.frontCardImage &&
          other.backCardImage == this.backCardImage &&
          other.notes == this.notes);
}

class InsuranceCompanion extends UpdateCompanion<InsuranceEntry> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> provider;
  final Value<String?> planName;
  final Value<String> policyNumber;
  final Value<String?> groupNumber;
  final Value<String?> subscriberName;
  final Value<String?> memberId;
  final Value<String?> emergencyPhone;
  final Value<String?> frontCardImage;
  final Value<String?> backCardImage;
  final Value<String?> notes;
  final Value<int> rowid;
  const InsuranceCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.provider = const Value.absent(),
    this.planName = const Value.absent(),
    this.policyNumber = const Value.absent(),
    this.groupNumber = const Value.absent(),
    this.subscriberName = const Value.absent(),
    this.memberId = const Value.absent(),
    this.emergencyPhone = const Value.absent(),
    this.frontCardImage = const Value.absent(),
    this.backCardImage = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InsuranceCompanion.insert({
    required String id,
    required String profileId,
    required String provider,
    this.planName = const Value.absent(),
    required String policyNumber,
    this.groupNumber = const Value.absent(),
    this.subscriberName = const Value.absent(),
    this.memberId = const Value.absent(),
    this.emergencyPhone = const Value.absent(),
    this.frontCardImage = const Value.absent(),
    this.backCardImage = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        provider = Value(provider),
        policyNumber = Value(policyNumber);
  static Insertable<InsuranceEntry> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? provider,
    Expression<String>? planName,
    Expression<String>? policyNumber,
    Expression<String>? groupNumber,
    Expression<String>? subscriberName,
    Expression<String>? memberId,
    Expression<String>? emergencyPhone,
    Expression<String>? frontCardImage,
    Expression<String>? backCardImage,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profileId': profileId,
      if (provider != null) 'provider': provider,
      if (planName != null) 'planName': planName,
      if (policyNumber != null) 'policyNumber': policyNumber,
      if (groupNumber != null) 'groupNumber': groupNumber,
      if (subscriberName != null) 'subscriberName': subscriberName,
      if (memberId != null) 'memberId': memberId,
      if (emergencyPhone != null) 'emergencyPhone': emergencyPhone,
      if (frontCardImage != null) 'frontCardImage': frontCardImage,
      if (backCardImage != null) 'backCardImage': backCardImage,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InsuranceCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<String>? provider,
      Value<String?>? planName,
      Value<String>? policyNumber,
      Value<String?>? groupNumber,
      Value<String?>? subscriberName,
      Value<String?>? memberId,
      Value<String?>? emergencyPhone,
      Value<String?>? frontCardImage,
      Value<String?>? backCardImage,
      Value<String?>? notes,
      Value<int>? rowid}) {
    return InsuranceCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      provider: provider ?? this.provider,
      planName: planName ?? this.planName,
      policyNumber: policyNumber ?? this.policyNumber,
      groupNumber: groupNumber ?? this.groupNumber,
      subscriberName: subscriberName ?? this.subscriberName,
      memberId: memberId ?? this.memberId,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      frontCardImage: frontCardImage ?? this.frontCardImage,
      backCardImage: backCardImage ?? this.backCardImage,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profileId'] = Variable<String>(profileId.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (planName.present) {
      map['planName'] = Variable<String>(planName.value);
    }
    if (policyNumber.present) {
      map['policyNumber'] = Variable<String>(policyNumber.value);
    }
    if (groupNumber.present) {
      map['groupNumber'] = Variable<String>(groupNumber.value);
    }
    if (subscriberName.present) {
      map['subscriberName'] = Variable<String>(subscriberName.value);
    }
    if (memberId.present) {
      map['memberId'] = Variable<String>(memberId.value);
    }
    if (emergencyPhone.present) {
      map['emergencyPhone'] = Variable<String>(emergencyPhone.value);
    }
    if (frontCardImage.present) {
      map['frontCardImage'] = Variable<String>(frontCardImage.value);
    }
    if (backCardImage.present) {
      map['backCardImage'] = Variable<String>(backCardImage.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InsuranceCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('provider: $provider, ')
          ..write('planName: $planName, ')
          ..write('policyNumber: $policyNumber, ')
          ..write('groupNumber: $groupNumber, ')
          ..write('subscriberName: $subscriberName, ')
          ..write('memberId: $memberId, ')
          ..write('emergencyPhone: $emergencyPhone, ')
          ..write('frontCardImage: $frontCardImage, ')
          ..write('backCardImage: $backCardImage, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $HistoryTable history = $HistoryTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $AllergyTable allergy = $AllergyTable(this);
  late final $MedicationsTable medications = $MedicationsTable(this);
  late final $MedicationLogsTable medicationLogs = $MedicationLogsTable(this);
  late final $CheckupsTable checkups = $CheckupsTable(this);
  late final $CheckupLogsTable checkupLogs = $CheckupLogsTable(this);
  late final $PeriodCyclesTable periodCycles = $PeriodCyclesTable(this);
  late final $PeriodLogsTable periodLogs = $PeriodLogsTable(this);
  late final $VitalLogsTable vitalLogs = $VitalLogsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $EmergencyContactsTable emergencyContacts =
      $EmergencyContactsTable(this);
  late final $LockScreenSettingsTable lockScreenSettings =
      $LockScreenSettingsTable(this);
  late final $InsuranceTable insurance = $InsuranceTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        profiles,
        history,
        attachments,
        allergy,
        medications,
        medicationLogs,
        checkups,
        checkupLogs,
        periodCycles,
        periodLogs,
        vitalLogs,
        settings,
        emergencyContacts,
        lockScreenSettings,
        insurance
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('profiles',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('history', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('history',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('attachments', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('profiles',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('allergy', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('profiles',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('medications', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('medications',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('medication_logs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('profiles',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('checkups', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('checkups',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('checkup_logs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('profiles',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('period_cycles', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('period_cycles',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('period_logs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('profiles',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('vital_logs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('profiles',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('emergency_contacts', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('profiles',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('lock_screen_settings', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('profiles',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('insurance', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  required String id,
  required String name,
  required String middleNames,
  required String surname,
  required DateTime dateOfBirth,
  required String bloodType,
  required String gender,
  Value<bool> isOrganDonor,
  Value<bool?> trackOvulation,
  Value<bool?> isArchived,
  Value<DateTime?> archivedAt,
  Value<String?> chronicConditions,
  Value<int> rowid,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> middleNames,
  Value<String> surname,
  Value<DateTime> dateOfBirth,
  Value<String> bloodType,
  Value<String> gender,
  Value<bool> isOrganDonor,
  Value<bool?> trackOvulation,
  Value<bool?> isArchived,
  Value<DateTime?> archivedAt,
  Value<String?> chronicConditions,
  Value<int> rowid,
});

class $$ProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProfilesTable,
    ProfileEntry,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder> {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ProfilesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ProfilesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> middleNames = const Value.absent(),
            Value<String> surname = const Value.absent(),
            Value<DateTime> dateOfBirth = const Value.absent(),
            Value<String> bloodType = const Value.absent(),
            Value<String> gender = const Value.absent(),
            Value<bool> isOrganDonor = const Value.absent(),
            Value<bool?> trackOvulation = const Value.absent(),
            Value<bool?> isArchived = const Value.absent(),
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<String?> chronicConditions = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfilesCompanion(
            id: id,
            name: name,
            middleNames: middleNames,
            surname: surname,
            dateOfBirth: dateOfBirth,
            bloodType: bloodType,
            gender: gender,
            isOrganDonor: isOrganDonor,
            trackOvulation: trackOvulation,
            isArchived: isArchived,
            archivedAt: archivedAt,
            chronicConditions: chronicConditions,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String middleNames,
            required String surname,
            required DateTime dateOfBirth,
            required String bloodType,
            required String gender,
            Value<bool> isOrganDonor = const Value.absent(),
            Value<bool?> trackOvulation = const Value.absent(),
            Value<bool?> isArchived = const Value.absent(),
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<String?> chronicConditions = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfilesCompanion.insert(
            id: id,
            name: name,
            middleNames: middleNames,
            surname: surname,
            dateOfBirth: dateOfBirth,
            bloodType: bloodType,
            gender: gender,
            isOrganDonor: isOrganDonor,
            trackOvulation: trackOvulation,
            isArchived: isArchived,
            archivedAt: archivedAt,
            chronicConditions: chronicConditions,
            rowid: rowid,
          ),
        ));
}

class $$ProfilesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get middleNames => $state.composableBuilder(
      column: $state.table.middleNames,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get surname => $state.composableBuilder(
      column: $state.table.surname,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateOfBirth => $state.composableBuilder(
      column: $state.table.dateOfBirth,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get bloodType => $state.composableBuilder(
      column: $state.table.bloodType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get gender => $state.composableBuilder(
      column: $state.table.gender,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isOrganDonor => $state.composableBuilder(
      column: $state.table.isOrganDonor,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get trackOvulation => $state.composableBuilder(
      column: $state.table.trackOvulation,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isArchived => $state.composableBuilder(
      column: $state.table.isArchived,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get archivedAt => $state.composableBuilder(
      column: $state.table.archivedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get chronicConditions => $state.composableBuilder(
      column: $state.table.chronicConditions,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter historyRefs(
      ComposableFilter Function($$HistoryTableFilterComposer f) f) {
    final $$HistoryTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.history,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder, parentComposers) => $$HistoryTableFilterComposer(
            ComposerState(
                $state.db, $state.db.history, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter allergyRefs(
      ComposableFilter Function($$AllergyTableFilterComposer f) f) {
    final $$AllergyTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.allergy,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder, parentComposers) => $$AllergyTableFilterComposer(
            ComposerState(
                $state.db, $state.db.allergy, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter medicationsRefs(
      ComposableFilter Function($$MedicationsTableFilterComposer f) f) {
    final $$MedicationsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.medications,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder, parentComposers) =>
            $$MedicationsTableFilterComposer(ComposerState($state.db,
                $state.db.medications, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter checkupsRefs(
      ComposableFilter Function($$CheckupsTableFilterComposer f) f) {
    final $$CheckupsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.checkups,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder, parentComposers) =>
            $$CheckupsTableFilterComposer(ComposerState(
                $state.db, $state.db.checkups, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter periodCyclesRefs(
      ComposableFilter Function($$PeriodCyclesTableFilterComposer f) f) {
    final $$PeriodCyclesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.periodCycles,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder, parentComposers) =>
            $$PeriodCyclesTableFilterComposer(ComposerState($state.db,
                $state.db.periodCycles, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter vitalLogsRefs(
      ComposableFilter Function($$VitalLogsTableFilterComposer f) f) {
    final $$VitalLogsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.vitalLogs,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder, parentComposers) =>
            $$VitalLogsTableFilterComposer(ComposerState(
                $state.db, $state.db.vitalLogs, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter emergencyContactsRefs(
      ComposableFilter Function($$EmergencyContactsTableFilterComposer f) f) {
    final $$EmergencyContactsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.emergencyContacts,
            getReferencedColumn: (t) => t.profileId,
            builder: (joinBuilder, parentComposers) =>
                $$EmergencyContactsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.emergencyContacts,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter lockScreenSettingsRefs(
      ComposableFilter Function($$LockScreenSettingsTableFilterComposer f) f) {
    final $$LockScreenSettingsTableFilterComposer composer = $state
        .composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.lockScreenSettings,
            getReferencedColumn: (t) => t.profileId,
            builder: (joinBuilder, parentComposers) =>
                $$LockScreenSettingsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.lockScreenSettings,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter insuranceRefs(
      ComposableFilter Function($$InsuranceTableFilterComposer f) f) {
    final $$InsuranceTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.insurance,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder, parentComposers) =>
            $$InsuranceTableFilterComposer(ComposerState(
                $state.db, $state.db.insurance, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$ProfilesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get middleNames => $state.composableBuilder(
      column: $state.table.middleNames,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get surname => $state.composableBuilder(
      column: $state.table.surname,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateOfBirth => $state.composableBuilder(
      column: $state.table.dateOfBirth,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get bloodType => $state.composableBuilder(
      column: $state.table.bloodType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get gender => $state.composableBuilder(
      column: $state.table.gender,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isOrganDonor => $state.composableBuilder(
      column: $state.table.isOrganDonor,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get trackOvulation => $state.composableBuilder(
      column: $state.table.trackOvulation,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isArchived => $state.composableBuilder(
      column: $state.table.isArchived,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get archivedAt => $state.composableBuilder(
      column: $state.table.archivedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get chronicConditions => $state.composableBuilder(
      column: $state.table.chronicConditions,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$HistoryTableCreateCompanionBuilder = HistoryCompanion Function({
  required String id,
  required String profileId,
  required String title,
  required String description,
  required DateTime date,
  Value<String?> eventType,
  Value<bool?> hasTime,
  Value<String?> provider,
  Value<String?> facility,
  Value<int> rowid,
});
typedef $$HistoryTableUpdateCompanionBuilder = HistoryCompanion Function({
  Value<String> id,
  Value<String> profileId,
  Value<String> title,
  Value<String> description,
  Value<DateTime> date,
  Value<String?> eventType,
  Value<bool?> hasTime,
  Value<String?> provider,
  Value<String?> facility,
  Value<int> rowid,
});

class $$HistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HistoryTable,
    HistoryEntry,
    $$HistoryTableFilterComposer,
    $$HistoryTableOrderingComposer,
    $$HistoryTableCreateCompanionBuilder,
    $$HistoryTableUpdateCompanionBuilder> {
  $$HistoryTableTableManager(_$AppDatabase db, $HistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$HistoryTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$HistoryTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String?> eventType = const Value.absent(),
            Value<bool?> hasTime = const Value.absent(),
            Value<String?> provider = const Value.absent(),
            Value<String?> facility = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HistoryCompanion(
            id: id,
            profileId: profileId,
            title: title,
            description: description,
            date: date,
            eventType: eventType,
            hasTime: hasTime,
            provider: provider,
            facility: facility,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required String title,
            required String description,
            required DateTime date,
            Value<String?> eventType = const Value.absent(),
            Value<bool?> hasTime = const Value.absent(),
            Value<String?> provider = const Value.absent(),
            Value<String?> facility = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HistoryCompanion.insert(
            id: id,
            profileId: profileId,
            title: title,
            description: description,
            date: date,
            eventType: eventType,
            hasTime: hasTime,
            provider: provider,
            facility: facility,
            rowid: rowid,
          ),
        ));
}

class $$HistoryTableFilterComposer
    extends FilterComposer<_$AppDatabase, $HistoryTable> {
  $$HistoryTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get eventType => $state.composableBuilder(
      column: $state.table.eventType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get hasTime => $state.composableBuilder(
      column: $state.table.hasTime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get provider => $state.composableBuilder(
      column: $state.table.provider,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get facility => $state.composableBuilder(
      column: $state.table.facility,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableFilterComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter attachmentsRefs(
      ComposableFilter Function($$AttachmentsTableFilterComposer f) f) {
    final $$AttachmentsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.attachments,
        getReferencedColumn: (t) => t.historyId,
        builder: (joinBuilder, parentComposers) =>
            $$AttachmentsTableFilterComposer(ComposerState($state.db,
                $state.db.attachments, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$HistoryTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $HistoryTable> {
  $$HistoryTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get eventType => $state.composableBuilder(
      column: $state.table.eventType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get hasTime => $state.composableBuilder(
      column: $state.table.hasTime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get provider => $state.composableBuilder(
      column: $state.table.provider,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get facility => $state.composableBuilder(
      column: $state.table.facility,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableOrderingComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$AttachmentsTableCreateCompanionBuilder = AttachmentsCompanion
    Function({
  required String id,
  required String historyId,
  required String filename,
  required DateTime uploadDate,
  required int byteLength,
  Value<int> rowid,
});
typedef $$AttachmentsTableUpdateCompanionBuilder = AttachmentsCompanion
    Function({
  Value<String> id,
  Value<String> historyId,
  Value<String> filename,
  Value<DateTime> uploadDate,
  Value<int> byteLength,
  Value<int> rowid,
});

class $$AttachmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttachmentsTable,
    AttachmentEntry,
    $$AttachmentsTableFilterComposer,
    $$AttachmentsTableOrderingComposer,
    $$AttachmentsTableCreateCompanionBuilder,
    $$AttachmentsTableUpdateCompanionBuilder> {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AttachmentsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AttachmentsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> historyId = const Value.absent(),
            Value<String> filename = const Value.absent(),
            Value<DateTime> uploadDate = const Value.absent(),
            Value<int> byteLength = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentsCompanion(
            id: id,
            historyId: historyId,
            filename: filename,
            uploadDate: uploadDate,
            byteLength: byteLength,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String historyId,
            required String filename,
            required DateTime uploadDate,
            required int byteLength,
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentsCompanion.insert(
            id: id,
            historyId: historyId,
            filename: filename,
            uploadDate: uploadDate,
            byteLength: byteLength,
            rowid: rowid,
          ),
        ));
}

class $$AttachmentsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get filename => $state.composableBuilder(
      column: $state.table.filename,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get uploadDate => $state.composableBuilder(
      column: $state.table.uploadDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get byteLength => $state.composableBuilder(
      column: $state.table.byteLength,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$HistoryTableFilterComposer get historyId {
    final $$HistoryTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.historyId,
        referencedTable: $state.db.history,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$HistoryTableFilterComposer(
            ComposerState(
                $state.db, $state.db.history, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$AttachmentsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get filename => $state.composableBuilder(
      column: $state.table.filename,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get uploadDate => $state.composableBuilder(
      column: $state.table.uploadDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get byteLength => $state.composableBuilder(
      column: $state.table.byteLength,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$HistoryTableOrderingComposer get historyId {
    final $$HistoryTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.historyId,
        referencedTable: $state.db.history,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$HistoryTableOrderingComposer(ComposerState(
                $state.db, $state.db.history, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$AllergyTableCreateCompanionBuilder = AllergyCompanion Function({
  required String id,
  required String profileId,
  required String name,
  required String note,
  Value<int> rowid,
});
typedef $$AllergyTableUpdateCompanionBuilder = AllergyCompanion Function({
  Value<String> id,
  Value<String> profileId,
  Value<String> name,
  Value<String> note,
  Value<int> rowid,
});

class $$AllergyTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AllergyTable,
    AllergyEntry,
    $$AllergyTableFilterComposer,
    $$AllergyTableOrderingComposer,
    $$AllergyTableCreateCompanionBuilder,
    $$AllergyTableUpdateCompanionBuilder> {
  $$AllergyTableTableManager(_$AppDatabase db, $AllergyTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AllergyTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AllergyTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AllergyCompanion(
            id: id,
            profileId: profileId,
            name: name,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required String name,
            required String note,
            Value<int> rowid = const Value.absent(),
          }) =>
              AllergyCompanion.insert(
            id: id,
            profileId: profileId,
            name: name,
            note: note,
            rowid: rowid,
          ),
        ));
}

class $$AllergyTableFilterComposer
    extends FilterComposer<_$AppDatabase, $AllergyTable> {
  $$AllergyTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableFilterComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$AllergyTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $AllergyTable> {
  $$AllergyTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableOrderingComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$MedicationsTableCreateCompanionBuilder = MedicationsCompanion
    Function({
  required String id,
  required String profileId,
  required String name,
  required String dosage,
  Value<String?> type,
  Value<bool?> notificationEnabled,
  Value<bool?> alarmEnabled,
  required String timeOfDay,
  Value<bool?> isActive,
  Value<String?> daysOfWeek,
  Value<String?> timesOfDay,
  Value<bool?> isAsNeeded,
  Value<bool?> trackInventory,
  Value<double?> stockQuantity,
  Value<double?> lowStockThreshold,
  Value<int> rowid,
});
typedef $$MedicationsTableUpdateCompanionBuilder = MedicationsCompanion
    Function({
  Value<String> id,
  Value<String> profileId,
  Value<String> name,
  Value<String> dosage,
  Value<String?> type,
  Value<bool?> notificationEnabled,
  Value<bool?> alarmEnabled,
  Value<String> timeOfDay,
  Value<bool?> isActive,
  Value<String?> daysOfWeek,
  Value<String?> timesOfDay,
  Value<bool?> isAsNeeded,
  Value<bool?> trackInventory,
  Value<double?> stockQuantity,
  Value<double?> lowStockThreshold,
  Value<int> rowid,
});

class $$MedicationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MedicationsTable,
    MedicationEntry,
    $$MedicationsTableFilterComposer,
    $$MedicationsTableOrderingComposer,
    $$MedicationsTableCreateCompanionBuilder,
    $$MedicationsTableUpdateCompanionBuilder> {
  $$MedicationsTableTableManager(_$AppDatabase db, $MedicationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$MedicationsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$MedicationsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> dosage = const Value.absent(),
            Value<String?> type = const Value.absent(),
            Value<bool?> notificationEnabled = const Value.absent(),
            Value<bool?> alarmEnabled = const Value.absent(),
            Value<String> timeOfDay = const Value.absent(),
            Value<bool?> isActive = const Value.absent(),
            Value<String?> daysOfWeek = const Value.absent(),
            Value<String?> timesOfDay = const Value.absent(),
            Value<bool?> isAsNeeded = const Value.absent(),
            Value<bool?> trackInventory = const Value.absent(),
            Value<double?> stockQuantity = const Value.absent(),
            Value<double?> lowStockThreshold = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MedicationsCompanion(
            id: id,
            profileId: profileId,
            name: name,
            dosage: dosage,
            type: type,
            notificationEnabled: notificationEnabled,
            alarmEnabled: alarmEnabled,
            timeOfDay: timeOfDay,
            isActive: isActive,
            daysOfWeek: daysOfWeek,
            timesOfDay: timesOfDay,
            isAsNeeded: isAsNeeded,
            trackInventory: trackInventory,
            stockQuantity: stockQuantity,
            lowStockThreshold: lowStockThreshold,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required String name,
            required String dosage,
            Value<String?> type = const Value.absent(),
            Value<bool?> notificationEnabled = const Value.absent(),
            Value<bool?> alarmEnabled = const Value.absent(),
            required String timeOfDay,
            Value<bool?> isActive = const Value.absent(),
            Value<String?> daysOfWeek = const Value.absent(),
            Value<String?> timesOfDay = const Value.absent(),
            Value<bool?> isAsNeeded = const Value.absent(),
            Value<bool?> trackInventory = const Value.absent(),
            Value<double?> stockQuantity = const Value.absent(),
            Value<double?> lowStockThreshold = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MedicationsCompanion.insert(
            id: id,
            profileId: profileId,
            name: name,
            dosage: dosage,
            type: type,
            notificationEnabled: notificationEnabled,
            alarmEnabled: alarmEnabled,
            timeOfDay: timeOfDay,
            isActive: isActive,
            daysOfWeek: daysOfWeek,
            timesOfDay: timesOfDay,
            isAsNeeded: isAsNeeded,
            trackInventory: trackInventory,
            stockQuantity: stockQuantity,
            lowStockThreshold: lowStockThreshold,
            rowid: rowid,
          ),
        ));
}

class $$MedicationsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get dosage => $state.composableBuilder(
      column: $state.table.dosage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get notificationEnabled => $state.composableBuilder(
      column: $state.table.notificationEnabled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get alarmEnabled => $state.composableBuilder(
      column: $state.table.alarmEnabled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get timeOfDay => $state.composableBuilder(
      column: $state.table.timeOfDay,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get daysOfWeek => $state.composableBuilder(
      column: $state.table.daysOfWeek,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get timesOfDay => $state.composableBuilder(
      column: $state.table.timesOfDay,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isAsNeeded => $state.composableBuilder(
      column: $state.table.isAsNeeded,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get trackInventory => $state.composableBuilder(
      column: $state.table.trackInventory,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get stockQuantity => $state.composableBuilder(
      column: $state.table.stockQuantity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get lowStockThreshold => $state.composableBuilder(
      column: $state.table.lowStockThreshold,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableFilterComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter medicationLogsRefs(
      ComposableFilter Function($$MedicationLogsTableFilterComposer f) f) {
    final $$MedicationLogsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.medicationLogs,
        getReferencedColumn: (t) => t.medicationId,
        builder: (joinBuilder, parentComposers) =>
            $$MedicationLogsTableFilterComposer(ComposerState($state.db,
                $state.db.medicationLogs, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$MedicationsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get dosage => $state.composableBuilder(
      column: $state.table.dosage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get notificationEnabled => $state.composableBuilder(
      column: $state.table.notificationEnabled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get alarmEnabled => $state.composableBuilder(
      column: $state.table.alarmEnabled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get timeOfDay => $state.composableBuilder(
      column: $state.table.timeOfDay,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get daysOfWeek => $state.composableBuilder(
      column: $state.table.daysOfWeek,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get timesOfDay => $state.composableBuilder(
      column: $state.table.timesOfDay,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isAsNeeded => $state.composableBuilder(
      column: $state.table.isAsNeeded,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get trackInventory => $state.composableBuilder(
      column: $state.table.trackInventory,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get stockQuantity => $state.composableBuilder(
      column: $state.table.stockQuantity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get lowStockThreshold => $state.composableBuilder(
      column: $state.table.lowStockThreshold,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableOrderingComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$MedicationLogsTableCreateCompanionBuilder = MedicationLogsCompanion
    Function({
  required String id,
  required String medicationId,
  required DateTime timestamp,
  Value<bool?> isTaken,
  Value<String?> dosage,
  Value<int> rowid,
});
typedef $$MedicationLogsTableUpdateCompanionBuilder = MedicationLogsCompanion
    Function({
  Value<String> id,
  Value<String> medicationId,
  Value<DateTime> timestamp,
  Value<bool?> isTaken,
  Value<String?> dosage,
  Value<int> rowid,
});

class $$MedicationLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MedicationLogsTable,
    MedicationLogEntry,
    $$MedicationLogsTableFilterComposer,
    $$MedicationLogsTableOrderingComposer,
    $$MedicationLogsTableCreateCompanionBuilder,
    $$MedicationLogsTableUpdateCompanionBuilder> {
  $$MedicationLogsTableTableManager(
      _$AppDatabase db, $MedicationLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$MedicationLogsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$MedicationLogsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> medicationId = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<bool?> isTaken = const Value.absent(),
            Value<String?> dosage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MedicationLogsCompanion(
            id: id,
            medicationId: medicationId,
            timestamp: timestamp,
            isTaken: isTaken,
            dosage: dosage,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String medicationId,
            required DateTime timestamp,
            Value<bool?> isTaken = const Value.absent(),
            Value<String?> dosage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MedicationLogsCompanion.insert(
            id: id,
            medicationId: medicationId,
            timestamp: timestamp,
            isTaken: isTaken,
            dosage: dosage,
            rowid: rowid,
          ),
        ));
}

class $$MedicationLogsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $MedicationLogsTable> {
  $$MedicationLogsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isTaken => $state.composableBuilder(
      column: $state.table.isTaken,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get dosage => $state.composableBuilder(
      column: $state.table.dosage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$MedicationsTableFilterComposer get medicationId {
    final $$MedicationsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.medicationId,
        referencedTable: $state.db.medications,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$MedicationsTableFilterComposer(ComposerState($state.db,
                $state.db.medications, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$MedicationLogsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $MedicationLogsTable> {
  $$MedicationLogsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isTaken => $state.composableBuilder(
      column: $state.table.isTaken,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get dosage => $state.composableBuilder(
      column: $state.table.dosage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$MedicationsTableOrderingComposer get medicationId {
    final $$MedicationsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.medicationId,
        referencedTable: $state.db.medications,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$MedicationsTableOrderingComposer(ComposerState($state.db,
                $state.db.medications, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$CheckupsTableCreateCompanionBuilder = CheckupsCompanion Function({
  required String id,
  required String profileId,
  required String name,
  required int frequencyInMonths,
  Value<String?> iconName,
  Value<bool?> isCustomInterval,
  Value<bool?> isActive,
  Value<int> rowid,
});
typedef $$CheckupsTableUpdateCompanionBuilder = CheckupsCompanion Function({
  Value<String> id,
  Value<String> profileId,
  Value<String> name,
  Value<int> frequencyInMonths,
  Value<String?> iconName,
  Value<bool?> isCustomInterval,
  Value<bool?> isActive,
  Value<int> rowid,
});

class $$CheckupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CheckupsTable,
    CheckupEntry,
    $$CheckupsTableFilterComposer,
    $$CheckupsTableOrderingComposer,
    $$CheckupsTableCreateCompanionBuilder,
    $$CheckupsTableUpdateCompanionBuilder> {
  $$CheckupsTableTableManager(_$AppDatabase db, $CheckupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CheckupsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CheckupsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> frequencyInMonths = const Value.absent(),
            Value<String?> iconName = const Value.absent(),
            Value<bool?> isCustomInterval = const Value.absent(),
            Value<bool?> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CheckupsCompanion(
            id: id,
            profileId: profileId,
            name: name,
            frequencyInMonths: frequencyInMonths,
            iconName: iconName,
            isCustomInterval: isCustomInterval,
            isActive: isActive,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required String name,
            required int frequencyInMonths,
            Value<String?> iconName = const Value.absent(),
            Value<bool?> isCustomInterval = const Value.absent(),
            Value<bool?> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CheckupsCompanion.insert(
            id: id,
            profileId: profileId,
            name: name,
            frequencyInMonths: frequencyInMonths,
            iconName: iconName,
            isCustomInterval: isCustomInterval,
            isActive: isActive,
            rowid: rowid,
          ),
        ));
}

class $$CheckupsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CheckupsTable> {
  $$CheckupsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get frequencyInMonths => $state.composableBuilder(
      column: $state.table.frequencyInMonths,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get iconName => $state.composableBuilder(
      column: $state.table.iconName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isCustomInterval => $state.composableBuilder(
      column: $state.table.isCustomInterval,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableFilterComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter checkupLogsRefs(
      ComposableFilter Function($$CheckupLogsTableFilterComposer f) f) {
    final $$CheckupLogsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.checkupLogs,
        getReferencedColumn: (t) => t.checkupId,
        builder: (joinBuilder, parentComposers) =>
            $$CheckupLogsTableFilterComposer(ComposerState($state.db,
                $state.db.checkupLogs, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$CheckupsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CheckupsTable> {
  $$CheckupsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get frequencyInMonths => $state.composableBuilder(
      column: $state.table.frequencyInMonths,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get iconName => $state.composableBuilder(
      column: $state.table.iconName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isCustomInterval => $state.composableBuilder(
      column: $state.table.isCustomInterval,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableOrderingComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$CheckupLogsTableCreateCompanionBuilder = CheckupLogsCompanion
    Function({
  required String id,
  required String checkupId,
  required DateTime dateCompleted,
  Value<String?> location,
  Value<String?> doctorName,
  Value<String?> notes,
  Value<int> rowid,
});
typedef $$CheckupLogsTableUpdateCompanionBuilder = CheckupLogsCompanion
    Function({
  Value<String> id,
  Value<String> checkupId,
  Value<DateTime> dateCompleted,
  Value<String?> location,
  Value<String?> doctorName,
  Value<String?> notes,
  Value<int> rowid,
});

class $$CheckupLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CheckupLogsTable,
    CheckupLogEntry,
    $$CheckupLogsTableFilterComposer,
    $$CheckupLogsTableOrderingComposer,
    $$CheckupLogsTableCreateCompanionBuilder,
    $$CheckupLogsTableUpdateCompanionBuilder> {
  $$CheckupLogsTableTableManager(_$AppDatabase db, $CheckupLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CheckupLogsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CheckupLogsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> checkupId = const Value.absent(),
            Value<DateTime> dateCompleted = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String?> doctorName = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CheckupLogsCompanion(
            id: id,
            checkupId: checkupId,
            dateCompleted: dateCompleted,
            location: location,
            doctorName: doctorName,
            notes: notes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String checkupId,
            required DateTime dateCompleted,
            Value<String?> location = const Value.absent(),
            Value<String?> doctorName = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CheckupLogsCompanion.insert(
            id: id,
            checkupId: checkupId,
            dateCompleted: dateCompleted,
            location: location,
            doctorName: doctorName,
            notes: notes,
            rowid: rowid,
          ),
        ));
}

class $$CheckupLogsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CheckupLogsTable> {
  $$CheckupLogsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateCompleted => $state.composableBuilder(
      column: $state.table.dateCompleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get location => $state.composableBuilder(
      column: $state.table.location,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get doctorName => $state.composableBuilder(
      column: $state.table.doctorName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$CheckupsTableFilterComposer get checkupId {
    final $$CheckupsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.checkupId,
        referencedTable: $state.db.checkups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CheckupsTableFilterComposer(ComposerState(
                $state.db, $state.db.checkups, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$CheckupLogsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CheckupLogsTable> {
  $$CheckupLogsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateCompleted => $state.composableBuilder(
      column: $state.table.dateCompleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get location => $state.composableBuilder(
      column: $state.table.location,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get doctorName => $state.composableBuilder(
      column: $state.table.doctorName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CheckupsTableOrderingComposer get checkupId {
    final $$CheckupsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.checkupId,
        referencedTable: $state.db.checkups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CheckupsTableOrderingComposer(ComposerState(
                $state.db, $state.db.checkups, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$PeriodCyclesTableCreateCompanionBuilder = PeriodCyclesCompanion
    Function({
  required String id,
  required String profileId,
  required DateTime startDate,
  Value<DateTime?> endDate,
  Value<int> rowid,
});
typedef $$PeriodCyclesTableUpdateCompanionBuilder = PeriodCyclesCompanion
    Function({
  Value<String> id,
  Value<String> profileId,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<int> rowid,
});

class $$PeriodCyclesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PeriodCyclesTable,
    PeriodCycleEntry,
    $$PeriodCyclesTableFilterComposer,
    $$PeriodCyclesTableOrderingComposer,
    $$PeriodCyclesTableCreateCompanionBuilder,
    $$PeriodCyclesTableUpdateCompanionBuilder> {
  $$PeriodCyclesTableTableManager(_$AppDatabase db, $PeriodCyclesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PeriodCyclesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PeriodCyclesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PeriodCyclesCompanion(
            id: id,
            profileId: profileId,
            startDate: startDate,
            endDate: endDate,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required DateTime startDate,
            Value<DateTime?> endDate = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PeriodCyclesCompanion.insert(
            id: id,
            profileId: profileId,
            startDate: startDate,
            endDate: endDate,
            rowid: rowid,
          ),
        ));
}

class $$PeriodCyclesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PeriodCyclesTable> {
  $$PeriodCyclesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get startDate => $state.composableBuilder(
      column: $state.table.startDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableFilterComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter periodLogsRefs(
      ComposableFilter Function($$PeriodLogsTableFilterComposer f) f) {
    final $$PeriodLogsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.periodLogs,
        getReferencedColumn: (t) => t.cycleId,
        builder: (joinBuilder, parentComposers) =>
            $$PeriodLogsTableFilterComposer(ComposerState($state.db,
                $state.db.periodLogs, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$PeriodCyclesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PeriodCyclesTable> {
  $$PeriodCyclesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get startDate => $state.composableBuilder(
      column: $state.table.startDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableOrderingComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$PeriodLogsTableCreateCompanionBuilder = PeriodLogsCompanion Function({
  required String id,
  required String cycleId,
  required DateTime date,
  Value<String?> flowLevel,
  Value<String?> moods,
  Value<String?> physicalSymptoms,
  Value<int> rowid,
});
typedef $$PeriodLogsTableUpdateCompanionBuilder = PeriodLogsCompanion Function({
  Value<String> id,
  Value<String> cycleId,
  Value<DateTime> date,
  Value<String?> flowLevel,
  Value<String?> moods,
  Value<String?> physicalSymptoms,
  Value<int> rowid,
});

class $$PeriodLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PeriodLogsTable,
    PeriodLogEntry,
    $$PeriodLogsTableFilterComposer,
    $$PeriodLogsTableOrderingComposer,
    $$PeriodLogsTableCreateCompanionBuilder,
    $$PeriodLogsTableUpdateCompanionBuilder> {
  $$PeriodLogsTableTableManager(_$AppDatabase db, $PeriodLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PeriodLogsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PeriodLogsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> cycleId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String?> flowLevel = const Value.absent(),
            Value<String?> moods = const Value.absent(),
            Value<String?> physicalSymptoms = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PeriodLogsCompanion(
            id: id,
            cycleId: cycleId,
            date: date,
            flowLevel: flowLevel,
            moods: moods,
            physicalSymptoms: physicalSymptoms,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String cycleId,
            required DateTime date,
            Value<String?> flowLevel = const Value.absent(),
            Value<String?> moods = const Value.absent(),
            Value<String?> physicalSymptoms = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PeriodLogsCompanion.insert(
            id: id,
            cycleId: cycleId,
            date: date,
            flowLevel: flowLevel,
            moods: moods,
            physicalSymptoms: physicalSymptoms,
            rowid: rowid,
          ),
        ));
}

class $$PeriodLogsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PeriodLogsTable> {
  $$PeriodLogsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get flowLevel => $state.composableBuilder(
      column: $state.table.flowLevel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get moods => $state.composableBuilder(
      column: $state.table.moods,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get physicalSymptoms => $state.composableBuilder(
      column: $state.table.physicalSymptoms,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$PeriodCyclesTableFilterComposer get cycleId {
    final $$PeriodCyclesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cycleId,
        referencedTable: $state.db.periodCycles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$PeriodCyclesTableFilterComposer(ComposerState($state.db,
                $state.db.periodCycles, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$PeriodLogsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PeriodLogsTable> {
  $$PeriodLogsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get flowLevel => $state.composableBuilder(
      column: $state.table.flowLevel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get moods => $state.composableBuilder(
      column: $state.table.moods,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get physicalSymptoms => $state.composableBuilder(
      column: $state.table.physicalSymptoms,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$PeriodCyclesTableOrderingComposer get cycleId {
    final $$PeriodCyclesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cycleId,
        referencedTable: $state.db.periodCycles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$PeriodCyclesTableOrderingComposer(ComposerState($state.db,
                $state.db.periodCycles, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$VitalLogsTableCreateCompanionBuilder = VitalLogsCompanion Function({
  required String id,
  required String profileId,
  required String type,
  required DateTime date,
  required double value1,
  Value<double?> value2,
  required String unit,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$VitalLogsTableUpdateCompanionBuilder = VitalLogsCompanion Function({
  Value<String> id,
  Value<String> profileId,
  Value<String> type,
  Value<DateTime> date,
  Value<double> value1,
  Value<double?> value2,
  Value<String> unit,
  Value<String?> note,
  Value<int> rowid,
});

class $$VitalLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VitalLogsTable,
    VitalLogEntry,
    $$VitalLogsTableFilterComposer,
    $$VitalLogsTableOrderingComposer,
    $$VitalLogsTableCreateCompanionBuilder,
    $$VitalLogsTableUpdateCompanionBuilder> {
  $$VitalLogsTableTableManager(_$AppDatabase db, $VitalLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$VitalLogsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$VitalLogsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<double> value1 = const Value.absent(),
            Value<double?> value2 = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VitalLogsCompanion(
            id: id,
            profileId: profileId,
            type: type,
            date: date,
            value1: value1,
            value2: value2,
            unit: unit,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required String type,
            required DateTime date,
            required double value1,
            Value<double?> value2 = const Value.absent(),
            required String unit,
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VitalLogsCompanion.insert(
            id: id,
            profileId: profileId,
            type: type,
            date: date,
            value1: value1,
            value2: value2,
            unit: unit,
            note: note,
            rowid: rowid,
          ),
        ));
}

class $$VitalLogsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $VitalLogsTable> {
  $$VitalLogsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get value1 => $state.composableBuilder(
      column: $state.table.value1,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get value2 => $state.composableBuilder(
      column: $state.table.value2,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableFilterComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$VitalLogsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $VitalLogsTable> {
  $$VitalLogsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get value1 => $state.composableBuilder(
      column: $state.table.value1,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get value2 => $state.composableBuilder(
      column: $state.table.value2,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableOrderingComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  Value<String?> value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String?> value,
  Value<int> rowid,
});

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    SettingEntry,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SettingsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SettingsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
        ));
}

class $$SettingsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer(super.$state);
  ColumnFilters<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SettingsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$EmergencyContactsTableCreateCompanionBuilder
    = EmergencyContactsCompanion Function({
  required String id,
  required String profileId,
  required String name,
  required String relationship,
  required String phoneNumber,
  Value<int> rowid,
});
typedef $$EmergencyContactsTableUpdateCompanionBuilder
    = EmergencyContactsCompanion Function({
  Value<String> id,
  Value<String> profileId,
  Value<String> name,
  Value<String> relationship,
  Value<String> phoneNumber,
  Value<int> rowid,
});

class $$EmergencyContactsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmergencyContactsTable,
    EmergencyContactEntry,
    $$EmergencyContactsTableFilterComposer,
    $$EmergencyContactsTableOrderingComposer,
    $$EmergencyContactsTableCreateCompanionBuilder,
    $$EmergencyContactsTableUpdateCompanionBuilder> {
  $$EmergencyContactsTableTableManager(
      _$AppDatabase db, $EmergencyContactsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$EmergencyContactsTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$EmergencyContactsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> relationship = const Value.absent(),
            Value<String> phoneNumber = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmergencyContactsCompanion(
            id: id,
            profileId: profileId,
            name: name,
            relationship: relationship,
            phoneNumber: phoneNumber,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required String name,
            required String relationship,
            required String phoneNumber,
            Value<int> rowid = const Value.absent(),
          }) =>
              EmergencyContactsCompanion.insert(
            id: id,
            profileId: profileId,
            name: name,
            relationship: relationship,
            phoneNumber: phoneNumber,
            rowid: rowid,
          ),
        ));
}

class $$EmergencyContactsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $EmergencyContactsTable> {
  $$EmergencyContactsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get relationship => $state.composableBuilder(
      column: $state.table.relationship,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get phoneNumber => $state.composableBuilder(
      column: $state.table.phoneNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableFilterComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$EmergencyContactsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $EmergencyContactsTable> {
  $$EmergencyContactsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get relationship => $state.composableBuilder(
      column: $state.table.relationship,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get phoneNumber => $state.composableBuilder(
      column: $state.table.phoneNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableOrderingComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$LockScreenSettingsTableCreateCompanionBuilder
    = LockScreenSettingsCompanion Function({
  required String profileId,
  Value<bool?> showName,
  Value<bool?> showAge,
  Value<bool?> showBloodType,
  Value<bool?> showOrganDonor,
  Value<bool?> showChronicConditions,
  Value<bool?> showAllergies,
  Value<bool?> showMedications,
  Value<bool?> showContacts,
  Value<bool?> showInsurance,
  Value<bool?> isEnabled,
  Value<int> rowid,
});
typedef $$LockScreenSettingsTableUpdateCompanionBuilder
    = LockScreenSettingsCompanion Function({
  Value<String> profileId,
  Value<bool?> showName,
  Value<bool?> showAge,
  Value<bool?> showBloodType,
  Value<bool?> showOrganDonor,
  Value<bool?> showChronicConditions,
  Value<bool?> showAllergies,
  Value<bool?> showMedications,
  Value<bool?> showContacts,
  Value<bool?> showInsurance,
  Value<bool?> isEnabled,
  Value<int> rowid,
});

class $$LockScreenSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LockScreenSettingsTable,
    LockScreenSettingEntry,
    $$LockScreenSettingsTableFilterComposer,
    $$LockScreenSettingsTableOrderingComposer,
    $$LockScreenSettingsTableCreateCompanionBuilder,
    $$LockScreenSettingsTableUpdateCompanionBuilder> {
  $$LockScreenSettingsTableTableManager(
      _$AppDatabase db, $LockScreenSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LockScreenSettingsTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$LockScreenSettingsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> profileId = const Value.absent(),
            Value<bool?> showName = const Value.absent(),
            Value<bool?> showAge = const Value.absent(),
            Value<bool?> showBloodType = const Value.absent(),
            Value<bool?> showOrganDonor = const Value.absent(),
            Value<bool?> showChronicConditions = const Value.absent(),
            Value<bool?> showAllergies = const Value.absent(),
            Value<bool?> showMedications = const Value.absent(),
            Value<bool?> showContacts = const Value.absent(),
            Value<bool?> showInsurance = const Value.absent(),
            Value<bool?> isEnabled = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LockScreenSettingsCompanion(
            profileId: profileId,
            showName: showName,
            showAge: showAge,
            showBloodType: showBloodType,
            showOrganDonor: showOrganDonor,
            showChronicConditions: showChronicConditions,
            showAllergies: showAllergies,
            showMedications: showMedications,
            showContacts: showContacts,
            showInsurance: showInsurance,
            isEnabled: isEnabled,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String profileId,
            Value<bool?> showName = const Value.absent(),
            Value<bool?> showAge = const Value.absent(),
            Value<bool?> showBloodType = const Value.absent(),
            Value<bool?> showOrganDonor = const Value.absent(),
            Value<bool?> showChronicConditions = const Value.absent(),
            Value<bool?> showAllergies = const Value.absent(),
            Value<bool?> showMedications = const Value.absent(),
            Value<bool?> showContacts = const Value.absent(),
            Value<bool?> showInsurance = const Value.absent(),
            Value<bool?> isEnabled = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LockScreenSettingsCompanion.insert(
            profileId: profileId,
            showName: showName,
            showAge: showAge,
            showBloodType: showBloodType,
            showOrganDonor: showOrganDonor,
            showChronicConditions: showChronicConditions,
            showAllergies: showAllergies,
            showMedications: showMedications,
            showContacts: showContacts,
            showInsurance: showInsurance,
            isEnabled: isEnabled,
            rowid: rowid,
          ),
        ));
}

class $$LockScreenSettingsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LockScreenSettingsTable> {
  $$LockScreenSettingsTableFilterComposer(super.$state);
  ColumnFilters<bool> get showName => $state.composableBuilder(
      column: $state.table.showName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get showAge => $state.composableBuilder(
      column: $state.table.showAge,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get showBloodType => $state.composableBuilder(
      column: $state.table.showBloodType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get showOrganDonor => $state.composableBuilder(
      column: $state.table.showOrganDonor,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get showChronicConditions => $state.composableBuilder(
      column: $state.table.showChronicConditions,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get showAllergies => $state.composableBuilder(
      column: $state.table.showAllergies,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get showMedications => $state.composableBuilder(
      column: $state.table.showMedications,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get showContacts => $state.composableBuilder(
      column: $state.table.showContacts,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get showInsurance => $state.composableBuilder(
      column: $state.table.showInsurance,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isEnabled => $state.composableBuilder(
      column: $state.table.isEnabled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableFilterComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$LockScreenSettingsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LockScreenSettingsTable> {
  $$LockScreenSettingsTableOrderingComposer(super.$state);
  ColumnOrderings<bool> get showName => $state.composableBuilder(
      column: $state.table.showName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get showAge => $state.composableBuilder(
      column: $state.table.showAge,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get showBloodType => $state.composableBuilder(
      column: $state.table.showBloodType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get showOrganDonor => $state.composableBuilder(
      column: $state.table.showOrganDonor,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get showChronicConditions => $state.composableBuilder(
      column: $state.table.showChronicConditions,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get showAllergies => $state.composableBuilder(
      column: $state.table.showAllergies,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get showMedications => $state.composableBuilder(
      column: $state.table.showMedications,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get showContacts => $state.composableBuilder(
      column: $state.table.showContacts,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get showInsurance => $state.composableBuilder(
      column: $state.table.showInsurance,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isEnabled => $state.composableBuilder(
      column: $state.table.isEnabled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableOrderingComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$InsuranceTableCreateCompanionBuilder = InsuranceCompanion Function({
  required String id,
  required String profileId,
  required String provider,
  Value<String?> planName,
  required String policyNumber,
  Value<String?> groupNumber,
  Value<String?> subscriberName,
  Value<String?> memberId,
  Value<String?> emergencyPhone,
  Value<String?> frontCardImage,
  Value<String?> backCardImage,
  Value<String?> notes,
  Value<int> rowid,
});
typedef $$InsuranceTableUpdateCompanionBuilder = InsuranceCompanion Function({
  Value<String> id,
  Value<String> profileId,
  Value<String> provider,
  Value<String?> planName,
  Value<String> policyNumber,
  Value<String?> groupNumber,
  Value<String?> subscriberName,
  Value<String?> memberId,
  Value<String?> emergencyPhone,
  Value<String?> frontCardImage,
  Value<String?> backCardImage,
  Value<String?> notes,
  Value<int> rowid,
});

class $$InsuranceTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InsuranceTable,
    InsuranceEntry,
    $$InsuranceTableFilterComposer,
    $$InsuranceTableOrderingComposer,
    $$InsuranceTableCreateCompanionBuilder,
    $$InsuranceTableUpdateCompanionBuilder> {
  $$InsuranceTableTableManager(_$AppDatabase db, $InsuranceTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$InsuranceTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$InsuranceTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<String> provider = const Value.absent(),
            Value<String?> planName = const Value.absent(),
            Value<String> policyNumber = const Value.absent(),
            Value<String?> groupNumber = const Value.absent(),
            Value<String?> subscriberName = const Value.absent(),
            Value<String?> memberId = const Value.absent(),
            Value<String?> emergencyPhone = const Value.absent(),
            Value<String?> frontCardImage = const Value.absent(),
            Value<String?> backCardImage = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InsuranceCompanion(
            id: id,
            profileId: profileId,
            provider: provider,
            planName: planName,
            policyNumber: policyNumber,
            groupNumber: groupNumber,
            subscriberName: subscriberName,
            memberId: memberId,
            emergencyPhone: emergencyPhone,
            frontCardImage: frontCardImage,
            backCardImage: backCardImage,
            notes: notes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required String provider,
            Value<String?> planName = const Value.absent(),
            required String policyNumber,
            Value<String?> groupNumber = const Value.absent(),
            Value<String?> subscriberName = const Value.absent(),
            Value<String?> memberId = const Value.absent(),
            Value<String?> emergencyPhone = const Value.absent(),
            Value<String?> frontCardImage = const Value.absent(),
            Value<String?> backCardImage = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InsuranceCompanion.insert(
            id: id,
            profileId: profileId,
            provider: provider,
            planName: planName,
            policyNumber: policyNumber,
            groupNumber: groupNumber,
            subscriberName: subscriberName,
            memberId: memberId,
            emergencyPhone: emergencyPhone,
            frontCardImage: frontCardImage,
            backCardImage: backCardImage,
            notes: notes,
            rowid: rowid,
          ),
        ));
}

class $$InsuranceTableFilterComposer
    extends FilterComposer<_$AppDatabase, $InsuranceTable> {
  $$InsuranceTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get provider => $state.composableBuilder(
      column: $state.table.provider,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get planName => $state.composableBuilder(
      column: $state.table.planName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get policyNumber => $state.composableBuilder(
      column: $state.table.policyNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get groupNumber => $state.composableBuilder(
      column: $state.table.groupNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get subscriberName => $state.composableBuilder(
      column: $state.table.subscriberName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get memberId => $state.composableBuilder(
      column: $state.table.memberId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get emergencyPhone => $state.composableBuilder(
      column: $state.table.emergencyPhone,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get frontCardImage => $state.composableBuilder(
      column: $state.table.frontCardImage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get backCardImage => $state.composableBuilder(
      column: $state.table.backCardImage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableFilterComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$InsuranceTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $InsuranceTable> {
  $$InsuranceTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get provider => $state.composableBuilder(
      column: $state.table.provider,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get planName => $state.composableBuilder(
      column: $state.table.planName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get policyNumber => $state.composableBuilder(
      column: $state.table.policyNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get groupNumber => $state.composableBuilder(
      column: $state.table.groupNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get subscriberName => $state.composableBuilder(
      column: $state.table.subscriberName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get memberId => $state.composableBuilder(
      column: $state.table.memberId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get emergencyPhone => $state.composableBuilder(
      column: $state.table.emergencyPhone,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get frontCardImage => $state.composableBuilder(
      column: $state.table.frontCardImage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get backCardImage => $state.composableBuilder(
      column: $state.table.backCardImage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $state.db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProfilesTableOrderingComposer(ComposerState(
                $state.db, $state.db.profiles, joinBuilder, parentComposers)));
    return composer;
  }
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$HistoryTableTableManager get history =>
      $$HistoryTableTableManager(_db, _db.history);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$AllergyTableTableManager get allergy =>
      $$AllergyTableTableManager(_db, _db.allergy);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db, _db.medications);
  $$MedicationLogsTableTableManager get medicationLogs =>
      $$MedicationLogsTableTableManager(_db, _db.medicationLogs);
  $$CheckupsTableTableManager get checkups =>
      $$CheckupsTableTableManager(_db, _db.checkups);
  $$CheckupLogsTableTableManager get checkupLogs =>
      $$CheckupLogsTableTableManager(_db, _db.checkupLogs);
  $$PeriodCyclesTableTableManager get periodCycles =>
      $$PeriodCyclesTableTableManager(_db, _db.periodCycles);
  $$PeriodLogsTableTableManager get periodLogs =>
      $$PeriodLogsTableTableManager(_db, _db.periodLogs);
  $$VitalLogsTableTableManager get vitalLogs =>
      $$VitalLogsTableTableManager(_db, _db.vitalLogs);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$EmergencyContactsTableTableManager get emergencyContacts =>
      $$EmergencyContactsTableTableManager(_db, _db.emergencyContacts);
  $$LockScreenSettingsTableTableManager get lockScreenSettings =>
      $$LockScreenSettingsTableTableManager(_db, _db.lockScreenSettings);
  $$InsuranceTableTableManager get insurance =>
      $$InsuranceTableTableManager(_db, _db.insurance);
}
