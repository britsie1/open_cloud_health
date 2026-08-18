import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:drift/drift.dart' as drift;
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  
  final medicationId = response.payload;
  if (medicationId == null) return;

  final db = AppDatabase();
  try {
    if (response.actionId == 'mark_taken') {
      final med = await (db.select(db.medications)..where((tbl) => tbl.id.equals(medicationId))).getSingleOrNull();
      final String? medDosage = med?.dosage;

      final log = MedicationLog(
        id: const Uuid().v4(),
        medicationId: medicationId,
        timestamp: DateTime.now(),
        dosage: medDosage,
      );

      await db.into(db.medicationLogs).insert(
        MedicationLogEntry(
          id: log.id,
          medicationId: log.medicationId,
          timestamp: log.timestamp,
          isTaken: log.isTaken,
          dosage: log.dosage,
        ),
      );

      // Background stock decrement direct Drift query using parsed dosage quantity
      if (med != null && (med.trackInventory ?? false)) {
        final currentStock = med.stockQuantity ?? 0.0;
        final dosageVal = parseDosageQuantity(med.dosage);
        final newStock = (currentStock - dosageVal).clamp(0.0, double.infinity);
        await (db.update(db.medications)..where((tbl) => tbl.id.equals(medicationId)))
            .write(MedicationsCompanion(stockQuantity: drift.Value(newStock)));
      }

      final SendPort? sendPort = IsolateNameServer.lookupPortByName('notification_action_port');
      if (sendPort != null) {
        sendPort.send(medicationId);
      }
    } else if (response.actionId == 'snooze_15') {
      tz.initializeTimeZones();
      try {
        final String timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (_) {}

      final med = await (db.select(db.medications)..where((tbl) => tbl.id.equals(medicationId))).getSingleOrNull();
      final String medName = med?.name ?? 'Medication';

    final notificationService = NotificationService();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    final List<DarwinNotificationCategory> darwinCategories = [
      DarwinNotificationCategory(
        'medication_category',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'mark_taken',
            'Mark as Taken',
          ),
          DarwinNotificationAction.plain(
            'snooze_15',
            'Snooze (15m)',
          ),
        ],
      )
    ];

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            notificationCategories: darwinCategories);

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await notificationService.flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: notificationTapForeground,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(const Duration(minutes: 15));
    final snoozeId = (medicationId.hashCode & 0x0FFFFFFF) + 9999;

    const androidDetails = AndroidNotificationDetails(
      'daily_medication_channel', 'Medication Reminders',
      channelDescription: 'Daily reminders to take your medications',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_taken', 
          'Mark as Taken',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'snooze_15',
          'Snooze (15m)',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'medication_category',
    );

    await notificationService.flutterLocalNotificationsPlugin.zonedSchedule(
        snoozeId,
        'Snoozed: $medName',
        'Time to take your medication $medName.',
        scheduledDate,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: medicationId);
    }
  } finally {
    await db.close();
  }
}

void notificationTapForeground(NotificationResponse response) async {
  if (response.payload != null) {
    if (response.actionId == 'mark_taken') {
      await NotificationService().markMedicationTaken(response.payload!);
    } else if (response.actionId == 'snooze_15') {
      await NotificationService().snoozeMedication(response.payload!);
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const _emergencyNotificationChannel = MethodChannel('com.opencloudhealth.app/emergency_notification');

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final onMedicationMarkedTaken = StreamController<String>.broadcast();

  Future<void> markMedicationTaken(String medicationId) async {
    final db = AppDatabase();
    try {
      final med = await (db.select(db.medications)..where((tbl) => tbl.id.equals(medicationId))).getSingleOrNull();
      final String? medDosage = med?.dosage;

      final log = MedicationLog(
        id: const Uuid().v4(),
        medicationId: medicationId,
        timestamp: DateTime.now(),
        dosage: medDosage,
      );

      await db.into(db.medicationLogs).insert(
        MedicationLogEntry(
          id: log.id,
          medicationId: log.medicationId,
          timestamp: log.timestamp,
          isTaken: log.isTaken,
          dosage: log.dosage,
        ),
      );

      // Decrement stock in foreground directly using parsed dosage quantity
      if (med != null && (med.trackInventory ?? false)) {
        final currentStock = med.stockQuantity ?? 0.0;
        final dosageVal = parseDosageQuantity(med.dosage);
        final newStock = (currentStock - dosageVal).clamp(0.0, double.infinity);
        await (db.update(db.medications)..where((tbl) => tbl.id.equals(medicationId)))
            .write(MedicationsCompanion(stockQuantity: drift.Value(newStock)));
      }

      onMedicationMarkedTaken.add(medicationId);
    } finally {
      await db.close();
    }
  }

  Future<void> snoozeMedication(String medicationId) async {
    final db = AppDatabase();
    try {
      final med = await (db.select(db.medications)..where((tbl) => tbl.id.equals(medicationId))).getSingleOrNull();
      final String medName = med?.name ?? 'Medication';

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(const Duration(minutes: 15));
    final snoozeId = (medicationId.hashCode & 0x0FFFFFFF) + 9999;

    const androidDetails = AndroidNotificationDetails(
      'daily_medication_channel', 'Medication Reminders',
      channelDescription: 'Daily reminders to take your medications',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_taken', 
          'Mark as Taken',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'snooze_15',
          'Snooze (15m)',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'medication_category',
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
        snoozeId,
        'Snoozed: $medName',
        'Time to take your medication $medName.',
        scheduledDate,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: medicationId);
    } finally {
      await db.close();
    }
  }

  Future<void> init() async {
    final ReceivePort port = ReceivePort();
    IsolateNameServer.removePortNameMapping('notification_action_port');
    IsolateNameServer.registerPortWithName(port.sendPort, 'notification_action_port');
    port.listen((dynamic data) {
      if (data is String) {
        onMedicationMarkedTaken.add(data);
      }
    });

    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    final List<DarwinNotificationCategory> darwinCategories = [
      DarwinNotificationCategory(
        'medication_category',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'mark_taken',
            'Mark as Taken',
          ),
          DarwinNotificationAction.plain(
            'snooze_15',
            'Snooze (15m)',
          ),
        ],
      )
    ];

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            notificationCategories: darwinCategories);

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: notificationTapForeground,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  Future<void> scheduleDailyNotification(int id, String title, String body, TimeOfDay time, String medicationId) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_medication_channel', 'Medication Reminders',
      channelDescription: 'Daily reminders to take your medications',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_taken', 
          'Mark as Taken',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'snooze_15', 
          'Snooze (15m)',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'medication_category',
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: medicationId);
  }

  Future<void> scheduleWeeklyNotification(int id, String title, String body, TimeOfDay time, int dayOfWeek, String medicationId) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    const androidDetails = AndroidNotificationDetails(
      'weekly_medication_channel', 'Medication Reminders',
      channelDescription: 'Weekly reminders to take your medications',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_taken', 
          'Mark as Taken',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'snooze_15', 
          'Snooze (15m)',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'medication_category',
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: medicationId);
  }

  Future<void> setSystemAlarm(TimeOfDay time, String message, List<int> days) async {
    if (Platform.isAndroid) {
      final androidDays = days.map((d) => d == 7 ? 1 : d + 1).toList();
      final intent = AndroidIntent(
        action: 'android.intent.action.SET_ALARM',
        arguments: <String, dynamic>{
          'android.intent.extra.alarm.HOUR': time.hour,
          'android.intent.extra.alarm.MINUTES': time.minute,
          'android.intent.extra.alarm.MESSAGE': message,
          'android.intent.extra.alarm.SKIP_UI': true,
          'android.intent.extra.alarm.DAYS': androidDays, // 1=Sunday, 2=Monday, etc. depending on Java Calendar
        },
      );
      await intent.launch();
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelMedicationNotifications(String medicationId) async {
    final baseId = medicationId.hashCode & 0x0FFFFFFF;
    for (int day = 1; day <= 7; day++) {
      for (int timeIdx = 0; timeIdx < 20; timeIdx++) {
        await cancelNotification(baseId + day * 100 + timeIdx);
      }
    }
  }

  Future<void> showEmergencyNotification(String title, String body) async {
    if (Platform.isAndroid) {
      try {
        await _emergencyNotificationChannel.invokeMethod('showNotification', {
          'title': title,
          'body': body,
        });
      } catch (e) {
        debugPrint('Error showing native Android emergency notification: $e');
      }
    } else {
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      await flutterLocalNotificationsPlugin.show(
        999,
        title,
        body,
        const NotificationDetails(android: null, iOS: iosDetails),
      );
    }
  }

  Future<void> cancelEmergencyNotification() async {
    if (Platform.isAndroid) {
      try {
        await _emergencyNotificationChannel.invokeMethod('cancelNotification');
      } catch (e) {
        debugPrint('Error cancelling native Android emergency notification: $e');
      }
    } else {
      await flutterLocalNotificationsPlugin.cancel(999);
    }
  }

  Future<void> syncEmergencyNotification(String profileId) async {
    final db = AppDatabase();
    try {
      // Get all active lock screen settings
      final activeSettings = await (db.select(db.lockScreenSettings)..where((tbl) => tbl.isEnabled.equals(true))).get();
      if (activeSettings.isEmpty) {
        await cancelEmergencyNotification();
        return;
      }

      if (activeSettings.length == 1) {
        // Sync single profile (exact same logic as original)
        final setRow = activeSettings.first;
        final pId = setRow.profileId;
        final showName = setRow.showName ?? true;
        final showAge = setRow.showAge ?? true;
        final showBloodType = setRow.showBloodType ?? true;
        final showOrganDonor = setRow.showOrganDonor ?? true;
        final showChronicConditions = setRow.showChronicConditions ?? true;
        final showAllergies = setRow.showAllergies ?? true;
        final showMedications = setRow.showMedications ?? true;
        final showContacts = setRow.showContacts ?? true;

        final p = await (db.select(db.profiles)..where((tbl) => tbl.id.equals(pId))).getSingleOrNull();
        if (p == null) {
          await cancelEmergencyNotification();
          return;
        }

        final name = '${p.name} ${p.surname}';
        final dob = p.dateOfBirth;
        final dobFormatted = '${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
        final today = DateTime.now();
        int age = today.year - dob.year;
        if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
          age--;
        }
        final bloodType = p.bloodType;
        final isOrganDonor = p.isOrganDonor;
        final chronicConditionsStr = p.chronicConditions ?? '';
        final chronicConditions = chronicConditionsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

        final allergiesData = await (db.select(db.allergy)..where((tbl) => tbl.profileId.equals(pId))).get();
        final allergies = allergiesData.map((row) => row.name).toList();

        final medsData = await (db.select(db.medications)..where((tbl) => tbl.profileId.equals(pId) & tbl.isActive.equals(true))).get();
        final medications = medsData.map((row) => row.name).toList();

        final contactsData = await (db.select(db.emergencyContacts)..where((tbl) => tbl.profileId.equals(pId))).get();

        final title = '🚨 Emergency Medical ID: ${showName ? name : "Medical Information"}';
        final buffer = StringBuffer();

        final details = <String>[];
        if (showAge) {
          details.add('DOB: $dobFormatted');
          details.add('Age: $age');
        }
        if (showBloodType) {
          details.add('Blood: $bloodType');
        }
        if (showOrganDonor) {
          details.add('Donor: ${isOrganDonor ? "Yes" : "No"}');
        }
        if (details.isNotEmpty) {
          buffer.writeln(details.join(' | '));
        }

        if (showChronicConditions) {
          buffer.writeln('Conditions: ${chronicConditions.isNotEmpty ? chronicConditions.join(", ") : "None"}');
        }
        if (showAllergies) {
          buffer.writeln('Allergies: ${allergies.isNotEmpty ? allergies.join(", ") : "None"}');
        }
        if (showMedications && medications.isNotEmpty) {
          buffer.writeln('Meds: ${medications.join(", ")}');
        }
        if (showContacts && contactsData.isNotEmpty) {
          buffer.writeln('Emergency Contacts:');
          for (final c in contactsData) {
            buffer.writeln('• ${c.name} (${c.relationship}): ${c.phoneNumber}');
          }
        }

        final body = buffer.toString().trim();
        if (body.isEmpty) {
          await cancelEmergencyNotification();
        } else {
          await showEmergencyNotification(title, body);
        }
      } else {
        // Sync multiple profiles
        final List<String> namesList = [];
        final buffer = StringBuffer();

        // Get primary profile ID to list first
        final primaryId = await db.getPrimaryProfileId();
        final settingsList = List<LockScreenSettingEntry>.from(activeSettings);
        if (primaryId != null) {
          settingsList.sort((a, b) {
            if (a.profileId == primaryId) return -1;
            if (b.profileId == primaryId) return 1;
            return 0;
          });
        }

        for (final setRow in settingsList) {
          final pId = setRow.profileId;
          final showName = setRow.showName ?? true;
          final showAge = setRow.showAge ?? true;
          final showBloodType = setRow.showBloodType ?? true;
          final showOrganDonor = setRow.showOrganDonor ?? true;
          final showChronicConditions = setRow.showChronicConditions ?? true;
          final showAllergies = setRow.showAllergies ?? true;
          final showMedications = setRow.showMedications ?? true;

          final p = await (db.select(db.profiles)..where((tbl) => tbl.id.equals(pId))).getSingleOrNull();
          if (p == null) continue;
          final name = '${p.name} ${p.surname}';
          
          if (showName) {
            namesList.add(p.name);
          }

          final dob = p.dateOfBirth;
          final dobFormatted = '${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
          final today = DateTime.now();
          int age = today.year - dob.year;
          if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
            age--;
          }
          final bloodType = p.bloodType;
          final isOrganDonor = p.isOrganDonor;
          final chronicConditionsStr = p.chronicConditions ?? '';
          final chronicConditions = chronicConditionsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

          final allergiesData = await (db.select(db.allergy)..where((tbl) => tbl.profileId.equals(pId))).get();
          final allergies = allergiesData.map((row) => row.name).toList();

          final medsData = await (db.select(db.medications)..where((tbl) => tbl.profileId.equals(pId) & tbl.isActive.equals(true))).get();
          final medications = medsData.map((row) => row.name).toList();

          buffer.writeln('${showName ? name : "Profile"}:');
          final details = <String>[];
          if (showAge) {
            details.add('DOB: $dobFormatted');
            details.add('Age: $age');
          }
          if (showBloodType) details.add('Blood: $bloodType');
          if (showOrganDonor) details.add('Donor: ${isOrganDonor ? "Yes" : "No"}');
          if (details.isNotEmpty) {
            buffer.writeln('  ${details.join(" | ")}');
          }

          if (showChronicConditions) {
            buffer.writeln('  Conditions: ${chronicConditions.isNotEmpty ? chronicConditions.join(", ") : "None"}');
          }
          if (showAllergies) {
            buffer.writeln('  Allergies: ${allergies.isNotEmpty ? allergies.join(", ") : "None"}');
          }
          if (showMedications && medications.isNotEmpty) {
            buffer.writeln('  Meds: ${medications.join(", ")}');
          }
        }

        final title = namesList.isNotEmpty
            ? '🚨 Emergency Medical IDs: ${namesList.join(" & ")}'
            : '🚨 Emergency Medical IDs';
        final body = buffer.toString().trim();
        if (body.isEmpty) {
          await cancelEmergencyNotification();
        } else {
          await showEmergencyNotification(title, body);
        }
      }
    } catch (e) {
      debugPrint('Error syncing emergency notification: $e');
    } finally {
      await db.close();
    }
  }

  Future<bool> isEmergencyChannelEnabled() async {
    if (Platform.isAndroid) {
      try {
        final bool? result = await _emergencyNotificationChannel.invokeMethod<bool>('isChannelEnabled');
        return result ?? false;
      } catch (e) {
        debugPrint('Error checking native Android emergency channel status: $e');
        return false;
      }
    }
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<void> openNotificationSettings() async {
    if (Platform.isAndroid) {
      try {
        await _emergencyNotificationChannel.invokeMethod('openNotificationSettings');
      } catch (e) {
        debugPrint('Error opening native Android notification settings: $e');
        await openAppSettings();
      }
    } else {
      await openAppSettings();
    }
  }

  Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted;
  }

  Future<void> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    await Permission.ignoreBatteryOptimizations.request();
  }

  Future<void> openAutoStartSettings() async {
    if (Platform.isAndroid) {
      try {
        await _emergencyNotificationChannel.invokeMethod('openAutoStartSettings');
      } catch (e) {
        debugPrint('Error opening native Android OEM auto-start settings: $e');
        try {
          await openAppSettings();
        } catch (_) {}
      }
    } else {
      try {
        await openAppSettings();
      } catch (_) {}
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
