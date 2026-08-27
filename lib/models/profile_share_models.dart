import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/checkup.dart';
import 'package:open_cloud_health/models/checkup_log.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/insurance_policy.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/vital_log.dart';

/// Selection options for what modules the sharer includes or omits.
class ShareModuleOptions {
  const ShareModuleOptions({
    this.includeDemographics = true,
    this.includeChronicConditions = true,
    this.includeAllergies = true,
    this.includeMedications = true,
    this.includeCheckups = true,
    this.includeVitals = true,
    this.includeHistory = true,
    this.includeEmergency = true,
    this.includeFertility = true,
    this.includeInsurance = true,
  });

  final bool includeDemographics;
  final bool includeChronicConditions;
  final bool includeAllergies;
  final bool includeMedications;
  final bool includeCheckups;
  final bool includeVitals;
  final bool includeHistory;
  final bool includeEmergency;
  final bool includeFertility;
  final bool includeInsurance;

  ShareModuleOptions copyWith({
    bool? includeDemographics,
    bool? includeChronicConditions,
    bool? includeAllergies,
    bool? includeMedications,
    bool? includeCheckups,
    bool? includeVitals,
    bool? includeHistory,
    bool? includeEmergency,
    bool? includeFertility,
    bool? includeInsurance,
  }) {
    return ShareModuleOptions(
      includeDemographics: includeDemographics ?? this.includeDemographics,
      includeChronicConditions: includeChronicConditions ?? this.includeChronicConditions,
      includeAllergies: includeAllergies ?? this.includeAllergies,
      includeMedications: includeMedications ?? this.includeMedications,
      includeCheckups: includeCheckups ?? this.includeCheckups,
      includeVitals: includeVitals ?? this.includeVitals,
      includeHistory: includeHistory ?? this.includeHistory,
      includeEmergency: includeEmergency ?? this.includeEmergency,
      includeFertility: includeFertility ?? this.includeFertility,
      includeInsurance: includeInsurance ?? this.includeInsurance,
    );
  }

  Map<String, dynamic> toJson() => {
        'includeDemographics': includeDemographics,
        'includeChronicConditions': includeChronicConditions,
        'includeAllergies': includeAllergies,
        'includeMedications': includeMedications,
        'includeCheckups': includeCheckups,
        'includeVitals': includeVitals,
        'includeHistory': includeHistory,
        'includeEmergency': includeEmergency,
        'includeFertility': includeFertility,
        'includeInsurance': includeInsurance,
      };

  factory ShareModuleOptions.fromJson(Map<String, dynamic> json) {
    return ShareModuleOptions(
      includeDemographics: json['includeDemographics'] as bool? ?? true,
      includeChronicConditions: json['includeChronicConditions'] as bool? ?? true,
      includeAllergies: json['includeAllergies'] as bool? ?? true,
      includeMedications: json['includeMedications'] as bool? ?? true,
      includeCheckups: json['includeCheckups'] as bool? ?? true,
      includeVitals: json['includeVitals'] as bool? ?? true,
      includeHistory: json['includeHistory'] as bool? ?? true,
      includeEmergency: json['includeEmergency'] as bool? ?? true,
      includeFertility: json['includeFertility'] as bool? ?? true,
      includeInsurance: json['includeInsurance'] as bool? ?? true,
    );
  }
}

/// A medication with its associated log entries.
class MedicationShareBundle {
  final Medication medication;
  final List<MedicationLog> logs;

  MedicationShareBundle({required this.medication, required this.logs});

  Map<String, dynamic> toJson() => {
        'medication': {
          'id': medication.id,
          'profileId': medication.profileId,
          'name': medication.name,
          'dosage': medication.dosage,
          'type': medication.type,
          'notificationEnabled': medication.notificationEnabled,
          'alarmEnabled': medication.alarmEnabled,
          'timeOfDayHour': medication.timeOfDay.hour,
          'timeOfDayMinute': medication.timeOfDay.minute,
          'isActive': medication.isActive,
          'daysOfWeek': medication.daysOfWeek,
          'timesOfDay': medication.timesOfDay.map((t) => {'hour': t.hour, 'minute': t.minute}).toList(),
          'isAsNeeded': medication.isAsNeeded,
          'trackInventory': medication.trackInventory,
          'stockQuantity': medication.stockQuantity,
          'lowStockThreshold': medication.lowStockThreshold,
        },
        'logs': logs.map((l) => {
              'id': l.id,
              'medicationId': l.medicationId,
              'timestamp': l.timestamp.toIso8601String(),
              'isTaken': l.isTaken,
              'dosage': l.dosage,
            }).toList(),
      };

  factory MedicationShareBundle.fromJson(Map<String, dynamic> json) {
    final medJson = json['medication'] as Map<String, dynamic>;
    final logsJson = json['logs'] as List<dynamic>? ?? [];

    final timesList = (medJson['timesOfDay'] as List<dynamic>?)
            ?.map((t) => TimeOfDay(hour: t['hour'] as int, minute: t['minute'] as int))
            .toList() ??
        [];

    final med = Medication(
      id: medJson['id'] as String?,
      profileId: medJson['profileId'] as String,
      name: medJson['name'] as String,
      dosage: medJson['dosage'] as String,
      type: medJson['type'] as String? ?? 'Other',
      notificationEnabled: medJson['notificationEnabled'] as bool? ?? false,
      alarmEnabled: medJson['alarmEnabled'] as bool? ?? false,
      timeOfDay: TimeOfDay(
        hour: medJson['timeOfDayHour'] as int? ?? 8,
        minute: medJson['timeOfDayMinute'] as int? ?? 0,
      ),
      isActive: medJson['isActive'] as bool? ?? true,
      daysOfWeek: (medJson['daysOfWeek'] as List<dynamic>?)?.cast<int>() ?? const [1, 2, 3, 4, 5, 6, 7],
      timesOfDay: timesList.isNotEmpty ? timesList : null,
      isAsNeeded: medJson['isAsNeeded'] as bool? ?? false,
      trackInventory: medJson['trackInventory'] as bool? ?? false,
      stockQuantity: (medJson['stockQuantity'] as num?)?.toDouble() ?? 0.0,
      lowStockThreshold: (medJson['lowStockThreshold'] as num?)?.toDouble() ?? 0.0,
    );

    final logs = logsJson.map((l) {
      return MedicationLog(
        id: l['id'] as String?,
        medicationId: l['medicationId'] as String,
        timestamp: DateTime.parse(l['timestamp'] as String),
        isTaken: l['isTaken'] as bool? ?? true,
        dosage: l['dosage'] as String?,
      );
    }).toList();

    return MedicationShareBundle(medication: med, logs: logs);
  }
}

/// A checkup with its associated log entries.
class CheckupShareBundle {
  final Checkup checkup;
  final List<CheckupLog> logs;

  CheckupShareBundle({required this.checkup, required this.logs});

  Map<String, dynamic> toJson() => {
        'checkup': {
          'id': checkup.id,
          'profileId': checkup.profileId,
          'name': checkup.name,
          'frequencyInMonths': checkup.frequencyInMonths,
          'iconName': checkup.iconName,
          'isCustomInterval': checkup.isCustomInterval,
          'isActive': checkup.isActive,
        },
        'logs': logs.map((l) => {
              'id': l.id,
              'checkupId': l.checkupId,
              'dateCompleted': l.dateCompleted.toIso8601String(),
              'location': l.location,
              'doctorName': l.doctorName,
              'notes': l.notes,
            }).toList(),
      };

  factory CheckupShareBundle.fromJson(Map<String, dynamic> json) {
    final cJson = json['checkup'] as Map<String, dynamic>;
    final logsJson = json['logs'] as List<dynamic>? ?? [];

    final checkup = Checkup(
      id: cJson['id'] as String?,
      profileId: cJson['profileId'] as String,
      name: cJson['name'] as String,
      frequencyInMonths: cJson['frequencyInMonths'] as int,
      iconName: cJson['iconName'] as String?,
      isCustomInterval: cJson['isCustomInterval'] as bool? ?? false,
      isActive: cJson['isActive'] as bool? ?? true,
    );

    final logs = logsJson.map((l) {
      return CheckupLog(
        id: l['id'] as String?,
        checkupId: l['checkupId'] as String,
        dateCompleted: DateTime.parse(l['dateCompleted'] as String),
        location: l['location'] as String?,
        doctorName: l['doctorName'] as String?,
        notes: l['notes'] as String?,
      );
    }).toList();

    return CheckupShareBundle(checkup: checkup, logs: logs);
  }
}

/// A period cycle with its associated daily logs.
class PeriodCycleShareBundle {
  final PeriodCycle cycle;
  final List<PeriodLog> logs;

  PeriodCycleShareBundle({required this.cycle, required this.logs});

  Map<String, dynamic> toJson() => {
        'cycle': {
          'id': cycle.id,
          'profileId': cycle.profileId,
          'startDate': cycle.startDate.toIso8601String(),
          'endDate': cycle.endDate?.toIso8601String(),
        },
        'logs': logs.map((l) => {
              'id': l.id,
              'cycleId': l.cycleId,
              'date': l.date.toIso8601String(),
              'flowLevel': l.flowLevel?.name,
              'moods': l.moods.map((m) => m.name).toList(),
              'physicalSymptoms': l.physicalSymptoms.map((s) => s.name).toList(),
            }).toList(),
      };

  factory PeriodCycleShareBundle.fromJson(Map<String, dynamic> json) {
    final cJson = json['cycle'] as Map<String, dynamic>;
    final logsJson = json['logs'] as List<dynamic>? ?? [];

    final cycle = PeriodCycle(
      id: cJson['id'] as String?,
      profileId: cJson['profileId'] as String,
      startDate: DateTime.parse(cJson['startDate'] as String),
      endDate: cJson['endDate'] != null ? DateTime.parse(cJson['endDate'] as String) : null,
    );

    final logs = logsJson.map((l) {
      final flowStr = l['flowLevel'] as String?;
      final flowLevel = flowStr != null && flowStr.isNotEmpty
          ? FlowLevel.values.firstWhere(
              (f) => f.name == flowStr,
              orElse: () => FlowLevel.medium,
            )
          : null;

      final moodsList = l['moods'] as List<dynamic>? ?? [];
      final moods = moodsList
          .map((m) => Mood.values.firstWhere((x) => x.name == m.toString(), orElse: () => Mood.happy))
          .toList();

      final physList = l['physicalSymptoms'] as List<dynamic>? ?? [];
      final physicalSymptoms = physList
          .map((s) => PhysicalSymptom.values.firstWhere((x) => x.name == s.toString(), orElse: () => PhysicalSymptom.cramps))
          .toList();

      return PeriodLog(
        id: l['id'] as String?,
        cycleId: l['cycleId'] as String,
        date: DateTime.parse(l['date'] as String),
        flowLevel: flowLevel,
        moods: moods,
        physicalSymptoms: physicalSymptoms,
      );
    }).toList();

    return PeriodCycleShareBundle(cycle: cycle, logs: logs);
  }
}

/// Complete bundled export of a single profile for read-only sharing.
class SharedProfileBundle {
  static const int currentVersion = 1;

  final int version;
  final Profile profile;
  final String sharedBy;
  final DateTime sharedAt;
  final ShareModuleOptions moduleOptions;
  final String? profileImageBase64;
  final List<Allergy> allergies;
  final List<MedicationShareBundle> medications;
  final List<CheckupShareBundle> checkups;
  final List<PeriodCycleShareBundle> periodCycles;
  final List<VitalLog> vitals;
  final List<HistoryEvent> historyEvents;
  final List<EmergencyContact> emergencyContacts;
  final LockScreenSetting? lockScreenSetting;
  final InsurancePolicy? insurance;

  SharedProfileBundle({
    this.version = currentVersion,
    required this.profile,
    required this.sharedBy,
    required this.sharedAt,
    required this.moduleOptions,
    this.profileImageBase64,
    this.allergies = const [],
    this.medications = const [],
    this.checkups = const [],
    this.periodCycles = const [],
    this.vitals = const [],
    this.historyEvents = const [],
    this.emergencyContacts = const [],
    this.lockScreenSetting,
    this.insurance,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'profile': {
          'id': profile.id,
          'name': profile.name,
          'middleNames': profile.middleNames,
          'surname': profile.surname,
          'dateOfBirth': profile.dateOfBirth.toIso8601String(),
          'gender': profile.gender.name,
          'bloodType': profile.bloodType,
          'isOrganDonor': profile.isOrganDonor,
          'trackOvulation': profile.trackOvulation,
          'chronicConditions': profile.chronicConditions,
        },
        'sharedBy': sharedBy,
        'sharedAt': sharedAt.toIso8601String(),
        'moduleOptions': moduleOptions.toJson(),
        'profileImageBase64': profileImageBase64,
        'allergies': allergies.map((a) => {
              'id': a.id,
              'profileId': a.profileId,
              'name': a.name,
              'note': a.note,
            }).toList(),
        'medications': medications.map((m) => m.toJson()).toList(),
        'checkups': checkups.map((c) => c.toJson()).toList(),
        'periodCycles': periodCycles.map((p) => p.toJson()).toList(),
        'vitals': vitals.map((v) => {
              'id': v.id,
              'profileId': v.profileId,
              'type': v.type.name,
              'date': v.date.toIso8601String(),
              'value1': v.value1,
              'value2': v.value2,
              'unit': v.unit,
              'note': v.note,
            }).toList(),
        'historyEvents': historyEvents.map((h) => {
              'id': h.id,
              'profileId': h.profileId,
              'title': h.title,
              'description': h.description,
              'date': h.date.toIso8601String(),
              'eventType': h.eventType.name,
              'hasTime': h.hasTime,
              'provider': h.provider,
              'facility': h.facility,
            }).toList(),
        'emergencyContacts': emergencyContacts.map((e) => {
              'id': e.id,
              'profileId': e.profileId,
              'name': e.name,
              'relationship': e.relationship,
              'phoneNumber': e.phoneNumber,
            }).toList(),
        'lockScreenSetting': lockScreenSetting != null
            ? {
                'profileId': lockScreenSetting!.profileId,
                'showName': lockScreenSetting!.showName,
                'showAge': lockScreenSetting!.showAge,
                'showBloodType': lockScreenSetting!.showBloodType,
                'showOrganDonor': lockScreenSetting!.showOrganDonor,
                'showChronicConditions': lockScreenSetting!.showChronicConditions,
                'showAllergies': lockScreenSetting!.showAllergies,
                'showMedications': lockScreenSetting!.showMedications,
                'showContacts': lockScreenSetting!.showContacts,
                'showInsurance': lockScreenSetting!.showInsurance,
                'isEnabled': lockScreenSetting!.isEnabled,
              }
            : null,
        'insurance': insurance != null
            ? {
                'id': insurance!.id,
                'profileId': insurance!.profileId,
                'provider': insurance!.provider,
                'planName': insurance!.planName,
                'policyNumber': insurance!.policyNumber,
                'groupNumber': insurance!.groupNumber,
                'subscriberName': insurance!.subscriberName,
                'memberId': insurance!.memberId,
                'emergencyPhone': insurance!.emergencyPhone,
                'notes': insurance!.notes,
              }
            : null,
      };

  factory SharedProfileBundle.fromJson(Map<String, dynamic> json) {
    final profJson = json['profile'] as Map<String, dynamic>;
    final options = json['moduleOptions'] != null
        ? ShareModuleOptions.fromJson(json['moduleOptions'] as Map<String, dynamic>)
        : const ShareModuleOptions();

    final profile = Profile(
      id: profJson['id'] as String?,
      name: profJson['name'] as String,
      middleNames: profJson['middleNames'] as String? ?? '',
      surname: profJson['surname'] as String,
      dateOfBirth: DateTime.parse(profJson['dateOfBirth'] as String),
      gender: Gender.values.byName(profJson['gender'] as String),
      bloodType: profJson['bloodType'] as String,
      isOrganDonor: profJson['isOrganDonor'] as bool? ?? false,
      trackOvulation: profJson['trackOvulation'] as bool? ?? true,
      chronicConditions: (profJson['chronicConditions'] as List<dynamic>?)?.cast<String>() ?? [],
      isShared: true,
      isReadOnly: true,
      sharedBy: json['sharedBy'] as String?,
      lastSyncedAt: DateTime.now(),
    );

    final allergies = (json['allergies'] as List<dynamic>? ?? []).map((a) {
      return Allergy(
        id: a['id'] as String?,
        profileId: a['profileId'] as String,
        name: a['name'] as String,
        note: a['note'] as String? ?? '',
      );
    }).toList();

    final medications = (json['medications'] as List<dynamic>? ?? []).map((m) {
      return MedicationShareBundle.fromJson(m as Map<String, dynamic>);
    }).toList();

    final checkups = (json['checkups'] as List<dynamic>? ?? []).map((c) {
      return CheckupShareBundle.fromJson(c as Map<String, dynamic>);
    }).toList();

    final periodCycles = (json['periodCycles'] as List<dynamic>? ?? []).map((p) {
      return PeriodCycleShareBundle.fromJson(p as Map<String, dynamic>);
    }).toList();

    final vitals = (json['vitals'] as List<dynamic>? ?? []).map((v) {
      return VitalLog(
        id: v['id'] as String?,
        profileId: v['profileId'] as String,
        type: VitalType.values.byName(v['type'] as String),
        date: DateTime.parse(v['date'] as String),
        value1: (v['value1'] as num).toDouble(),
        value2: (v['value2'] as num?)?.toDouble(),
        unit: v['unit'] as String,
        note: v['note'] as String?,
      );
    }).toList();

    final historyEvents = (json['historyEvents'] as List<dynamic>? ?? []).map((h) {
      return HistoryEvent(
        id: h['id'] as String?,
        profileId: h['profileId'] as String,
        title: h['title'] as String,
        description: h['description'] as String,
        date: DateTime.parse(h['date'] as String),
        eventType: EventType.values.byName(h['eventType'] as String? ?? 'other'),
        hasTime: h['hasTime'] as bool? ?? true,
        provider: h['provider'] as String?,
        facility: h['facility'] as String?,
      );
    }).toList();

    final emergencyContacts = (json['emergencyContacts'] as List<dynamic>? ?? []).map((e) {
      return EmergencyContact(
        id: e['id'] as String?,
        profileId: e['profileId'] as String,
        name: e['name'] as String,
        relationship: e['relationship'] as String,
        phoneNumber: e['phoneNumber'] as String,
      );
    }).toList();

    final lockJson = json['lockScreenSetting'] as Map<String, dynamic>?;
    final lockScreenSetting = lockJson != null
        ? LockScreenSetting(
            profileId: lockJson['profileId'] as String,
            showName: lockJson['showName'] as bool? ?? true,
            showAge: lockJson['showAge'] as bool? ?? true,
            showBloodType: lockJson['showBloodType'] as bool? ?? true,
            showOrganDonor: lockJson['showOrganDonor'] as bool? ?? true,
            showChronicConditions: lockJson['showChronicConditions'] as bool? ?? true,
            showAllergies: lockJson['showAllergies'] as bool? ?? true,
            showMedications: lockJson['showMedications'] as bool? ?? true,
            showContacts: lockJson['showContacts'] as bool? ?? true,
            showInsurance: lockJson['showInsurance'] as bool? ?? true,
            isEnabled: lockJson['isEnabled'] as bool? ?? false,
          )
        : null;

    final insJson = json['insurance'] as Map<String, dynamic>?;
    final insurance = insJson != null
        ? InsurancePolicy(
            id: insJson['id'] as String?,
            profileId: insJson['profileId'] as String,
            provider: insJson['provider'] as String,
            planName: insJson['planName'] as String?,
            policyNumber: insJson['policyNumber'] as String,
            groupNumber: insJson['groupNumber'] as String?,
            subscriberName: insJson['subscriberName'] as String?,
            memberId: insJson['memberId'] as String?,
            emergencyPhone: insJson['emergencyPhone'] as String?,
            notes: insJson['notes'] as String?,
          )
        : null;

    return SharedProfileBundle(
      version: json['version'] as int? ?? currentVersion,
      profile: profile,
      sharedBy: json['sharedBy'] as String? ?? 'Unknown',
      sharedAt: json['sharedAt'] != null ? DateTime.parse(json['sharedAt'] as String) : DateTime.now(),
      moduleOptions: options,
      profileImageBase64: json['profileImageBase64'] as String?,
      allergies: allergies,
      medications: medications,
      checkups: checkups,
      periodCycles: periodCycles,
      vitals: vitals,
      historyEvents: historyEvents,
      emergencyContacts: emergencyContacts,
      lockScreenSetting: lockScreenSetting,
      insurance: insurance,
    );
  }

  String encodeToJsonString() => jsonEncode(toJson());

  static SharedProfileBundle decodeFromJsonString(String jsonStr) {
    return SharedProfileBundle.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }
}

/// Represents the data encoded in the QR code or universal share link.
class ShareLinkPayload {
  final String fileId;
  final String key;
  final String? profileName;
  final String? sharedBy;

  ShareLinkPayload({
    required this.fileId,
    required this.key,
    this.profileName,
    this.sharedBy,
  });

  String get encryptionKey => key;

  /// Builds a universal link string: `https://opencloudhealth.app/share?fileId=...&name=...#key=...`
  String toUniversalUriString() {
    final queryParams = <String, String>{
      'fileId': fileId,
      if (profileName != null) 'name': profileName!,
      if (sharedBy != null) 'by': sharedBy!,
    };
    final uri = Uri(
      scheme: 'https',
      host: 'opencloudhealth.app',
      path: '/share',
      queryParameters: queryParams,
      fragment: 'key=$key',
    );
    return uri.toString();
  }

  /// Parses a QR string or URL into a `ShareLinkPayload`.
  static ShareLinkPayload? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    try {
      if (trimmed.startsWith('https://') || trimmed.startsWith('http://') || trimmed.startsWith('opencloudhealth://')) {
        final uri = Uri.parse(trimmed);
        final fileId = uri.queryParameters['fileId'] ?? '';
        final profileName = uri.queryParameters['name'];
        final sharedBy = uri.queryParameters['by'];
        
        String key = '';
        if (uri.fragment.isNotEmpty) {
          if (uri.fragment.startsWith('key=')) {
            key = uri.fragment.substring(4);
          } else {
            key = uri.fragment;
          }
        } else if (uri.queryParameters.containsKey('key')) {
          key = uri.queryParameters['key']!;
        }

        if (fileId.isNotEmpty && key.isNotEmpty) {
          return ShareLinkPayload(
            fileId: fileId,
            key: key,
            profileName: profileName,
            sharedBy: sharedBy,
          );
        }
      }

      // Check if raw JSON
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        final map = jsonDecode(trimmed) as Map<String, dynamic>;
        final fileId = map['fileId'] as String?;
        final key = map['key'] as String?;
        if (fileId != null && key != null) {
          return ShareLinkPayload(
            fileId: fileId,
            key: key,
            profileName: map['name'] as String?,
            sharedBy: map['by'] as String?,
          );
        }
      }
    } catch (_) {}

    return null;
  }
}
