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
import 'package:open_cloud_health/database/database_helper.dart';
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

  final dbHelper = DatabaseHelper();
  final db = await dbHelper.getDatabase();

  if (response.actionId == 'mark_taken') {
    final List<Map<String, dynamic>> meds = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [medicationId],
    );
    final String? medDosage = meds.isNotEmpty ? meds.first['dosage'] as String? : null;

    final log = MedicationLog(
      id: const Uuid().v4(),
      medicationId: medicationId,
      timestamp: DateTime.now(),
      dosage: medDosage,
    );

    await db.insert('medication_logs', {
      'id': log.id,
      'medicationId': log.medicationId,
      'timestamp': log.timestamp.toIso8601String(),
      'isTaken': log.isTaken.toString(),
      'dosage': log.dosage,
    });

    // Background stock decrement direct SQLite query using parsed dosage quantity
    if (meds.isNotEmpty) {
      final med = meds.first;
      final trackInventory = med['trackInventory'] == 'true';
      if (trackInventory) {
        final currentStock = (med['stockQuantity'] as num?)?.toDouble() ?? 0.0;
        final dosageVal = parseDosageQuantity(med['dosage'] as String? ?? '');
        final newStock = (currentStock - dosageVal).clamp(0.0, double.infinity);
        await db.update(
          'medications',
          {'stockQuantity': newStock},
          where: 'id = ?',
          whereArgs: [medicationId],
        );
      }
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

    final List<Map<String, dynamic>> meds = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [medicationId],
    );
    final String medName = meds.isNotEmpty ? meds.first['name'] as String : 'Medication';

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

  static const _emergencyNotificationChannel = MethodChannel('com.example.open_cloud_health/emergency_notification');

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final onMedicationMarkedTaken = StreamController<String>.broadcast();

  Future<void> markMedicationTaken(String medicationId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.getDatabase();
    
    final List<Map<String, dynamic>> meds = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [medicationId],
    );
    final String? medDosage = meds.isNotEmpty ? meds.first['dosage'] as String? : null;

    final log = MedicationLog(
      id: const Uuid().v4(),
      medicationId: medicationId,
      timestamp: DateTime.now(),
      dosage: medDosage,
    );

    await db.insert('medication_logs', {
      'id': log.id,
      'medicationId': log.medicationId,
      'timestamp': log.timestamp.toIso8601String(),
      'isTaken': log.isTaken.toString(),
      'dosage': log.dosage,
    });

    // Decrement stock in foreground directly using parsed dosage quantity
    if (meds.isNotEmpty) {
      final med = meds.first;
      final trackInventory = med['trackInventory'] == 'true';
      if (trackInventory) {
        final currentStock = (med['stockQuantity'] as num?)?.toDouble() ?? 0.0;
        final dosageVal = parseDosageQuantity(med['dosage'] as String? ?? '');
        final newStock = (currentStock - dosageVal).clamp(0.0, double.infinity);
        await db.update(
          'medications',
          {'stockQuantity': newStock},
          where: 'id = ?',
          whereArgs: [medicationId],
        );
      }
    }

    onMedicationMarkedTaken.add(medicationId);
  }

  Future<void> snoozeMedication(String medicationId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.getDatabase();
    
    final List<Map<String, dynamic>> meds = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [medicationId],
    );
    final String medName = meds.isNotEmpty ? meds.first['name'] as String : 'Medication';

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
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.getDatabase();

      // Get all active lock screen settings
      final activeSettings = await db.query('lock_screen_settings', where: 'isEnabled = ?', whereArgs: ['true']);
      if (activeSettings.isEmpty) {
        await cancelEmergencyNotification();
        return;
      }

      if (activeSettings.length == 1) {
        // Sync single profile (exact same logic as original)
        final setRow = activeSettings.first;
        final pId = setRow['profileId'] as String;
        final showName = setRow['showName'] == 'true';
        final showAge = setRow['showAge'] == 'true';
        final showBloodType = setRow['showBloodType'] == 'true';
        final showOrganDonor = setRow['showOrganDonor'] == 'true';
        final showChronicConditions = setRow['showChronicConditions'] == 'true';
        final showAllergies = setRow['showAllergies'] == 'true';
        final showMedications = setRow['showMedications'] == 'true';
        final showContacts = setRow['showContacts'] == 'true';

        final profileData = await db.query('profiles', where: 'id = ?', whereArgs: [pId]);
        if (profileData.isEmpty) {
          await cancelEmergencyNotification();
          return;
        }
        final p = profileData.first;
        final name = '${p['name']} ${p['surname']}';
        final dobStr = p['dateOfBirth'] as String;
        final dob = DateTime.parse(dobStr);
        final today = DateTime.now();
        int age = today.year - dob.year;
        if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
          age--;
        }
        final bloodType = p['bloodType'] as String;
        final isOrganDonor = p['isOrganDonor'] == 'true';
        final chronicConditionsStr = p['chronicConditions'] as String? ?? '';
        final chronicConditions = chronicConditionsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

        final allergiesData = await db.query('allergy', where: 'profileId = ?', whereArgs: [pId]);
        final allergies = allergiesData.map((row) => row['name'] as String).toList();

        final medsData = await db.query('medications', where: 'profileId = ? AND isActive = ?', whereArgs: [pId, 'true']);
        final medications = medsData.map((row) => row['name'] as String).toList();

        final contactsData = await db.query('emergency_contacts', where: 'profileId = ?', whereArgs: [pId]);

        final title = '🚨 Emergency Medical ID: ${showName ? name : "Medical Information"}';
        final buffer = StringBuffer();

        final details = <String>[];
        if (showAge) {
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

        if (showChronicConditions && chronicConditions.isNotEmpty) {
          buffer.writeln('Conditions: ${chronicConditions.join(", ")}');
        }
        if (showAllergies && allergies.isNotEmpty) {
          buffer.writeln('Allergies: ${allergies.join(", ")}');
        }
        if (showMedications && medications.isNotEmpty) {
          buffer.writeln('Meds: ${medications.join(", ")}');
        }
        if (showContacts && contactsData.isNotEmpty) {
          buffer.writeln('Emergency Contacts:');
          for (final c in contactsData) {
            buffer.writeln('• ${c['name']} (${c['relationship']}): ${c['phoneNumber']}');
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

        for (final setRow in activeSettings) {
          final pId = setRow['profileId'] as String;
          final showName = setRow['showName'] == 'true';
          final showAge = setRow['showAge'] == 'true';
          final showBloodType = setRow['showBloodType'] == 'true';
          final showOrganDonor = setRow['showOrganDonor'] == 'true';
          final showChronicConditions = setRow['showChronicConditions'] == 'true';
          final showAllergies = setRow['showAllergies'] == 'true';
          final showMedications = setRow['showMedications'] == 'true';

          final profileData = await db.query('profiles', where: 'id = ?', whereArgs: [pId]);
          if (profileData.isEmpty) continue;
          final p = profileData.first;
          final name = '${p['name']} ${p['surname']}';
          
          if (showName) {
            namesList.add(p['name'] as String);
          }

          final dobStr = p['dateOfBirth'] as String;
          final dob = DateTime.parse(dobStr);
          final today = DateTime.now();
          int age = today.year - dob.year;
          if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
            age--;
          }
          final bloodType = p['bloodType'] as String;
          final isOrganDonor = p['isOrganDonor'] == 'true';
          final chronicConditionsStr = p['chronicConditions'] as String? ?? '';
          final chronicConditions = chronicConditionsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

          final allergiesData = await db.query('allergy', where: 'profileId = ?', whereArgs: [pId]);
          final allergies = allergiesData.map((row) => row['name'] as String).toList();

          final medsData = await db.query('medications', where: 'profileId = ? AND isActive = ?', whereArgs: [pId, 'true']);
          final medications = medsData.map((row) => row['name'] as String).toList();

          buffer.writeln('${showName ? name : "Profile"}:');
          final details = <String>[];
          if (showAge) details.add('Age: $age');
          if (showBloodType) details.add('Blood: $bloodType');
          if (showOrganDonor) details.add('Donor: ${isOrganDonor ? "Yes" : "No"}');
          if (details.isNotEmpty) {
            buffer.writeln('  ${details.join(" | ")}');
          }

          if (showChronicConditions && chronicConditions.isNotEmpty) {
            buffer.writeln('  Conditions: ${chronicConditions.join(", ")}');
          }
          if (showAllergies && allergies.isNotEmpty) {
            buffer.writeln('  Allergies: ${allergies.join(", ")}');
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
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
