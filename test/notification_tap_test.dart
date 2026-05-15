import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/repositories/medications_repository.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('loadLogsForDate loads inserted logs', () async {
    WidgetsFlutterBinding.ensureInitialized();
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.getDatabase();
    
    final profileId = 'test_profile_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('profiles', {'id': profileId, 'name': 'Test2'});
    
    final medId = 'test_med_id_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('medications', {
      'id': medId,
      'profileId': profileId,
      'name': 'Med 2',
      'dosage': '10mg',
      'type': 'Tablet',
      'notificationEnabled': 'true',
      'alarmEnabled': 'false',
      'timeOfDay': '10:00',
      'isActive': 'true',
    });

    final response = NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotificationAction,
      actionId: 'mark_taken',
      payload: medId,
    );

    // Call the tap directly
    await NotificationService().markMedicationTaken(response.payload!);

    final repo = MedicationsRepository(dbHelper);
    final logs = await repo.loadLogsForDate(DateTime.now(), profileId);

    expect(logs.length, 1);
    expect(logs.first.medicationId, medId);
    expect(logs.first.isTaken, true);
  });
}
