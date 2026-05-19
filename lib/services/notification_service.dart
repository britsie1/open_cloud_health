import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:open_cloud_health/database/database_helper.dart';
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
    final log = MedicationLog(
      id: const Uuid().v4(),
      medicationId: medicationId,
      timestamp: DateTime.now(),
    );

    await db.insert('medication_logs', {
      'id': log.id,
      'medicationId': log.medicationId,
      'timestamp': log.timestamp.toIso8601String(),
      'isTaken': log.isTaken.toString(),
    });

    // Background stock decrement direct SQLite query
    final List<Map<String, dynamic>> meds = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [medicationId],
    );
    if (meds.isNotEmpty) {
      final med = meds.first;
      final trackInventory = med['trackInventory'] == 'true';
      if (trackInventory) {
        final currentStock = (med['stockQuantity'] as num?)?.toDouble() ?? 0.0;
        final newStock = (currentStock - 1.0).clamp(0.0, double.infinity);
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

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final onMedicationMarkedTaken = StreamController<String>.broadcast();

  Future<void> markMedicationTaken(String medicationId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.getDatabase();
    
    final log = MedicationLog(
      id: const Uuid().v4(),
      medicationId: medicationId,
      timestamp: DateTime.now(),
    );

    await db.insert('medication_logs', {
      'id': log.id,
      'medicationId': log.medicationId,
      'timestamp': log.timestamp.toIso8601String(),
      'isTaken': log.isTaken.toString(),
    });

    // Decrement stock in foreground directly
    final List<Map<String, dynamic>> meds = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [medicationId],
    );
    if (meds.isNotEmpty) {
      final med = meds.first;
      final trackInventory = med['trackInventory'] == 'true';
      if (trackInventory) {
        final currentStock = (med['stockQuantity'] as num?)?.toDouble() ?? 0.0;
        final newStock = (currentStock - 1.0).clamp(0.0, double.infinity);
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
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
