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
  if (response.actionId == 'mark_taken' && response.payload != null) {
    final medicationId = response.payload!;
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

    final SendPort? sendPort = IsolateNameServer.lookupPortByName('notification_action_port');
    if (sendPort != null) {
      sendPort.send(medicationId);
    }
  }
}

void notificationTapForeground(NotificationResponse response) async {
  if (response.actionId == 'mark_taken' && response.payload != null) {
    await NotificationService().markMedicationTaken(response.payload!);
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

    onMedicationMarkedTaken.add(medicationId);
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
    // Note: iOS does not support setting the native clock alarm via intents.
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
