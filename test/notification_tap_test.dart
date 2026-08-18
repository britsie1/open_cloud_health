import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/repositories/medications_repository.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:flutter/material.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('loadLogsForDate loads inserted logs', () async {
    WidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase();
    
    final profileId = 'test_profile_${DateTime.now().millisecondsSinceEpoch}';
    final profilesRepo = ProfilesRepository(db);
    await profilesRepo.addProfile(Profile(
      id: profileId,
      name: 'Test2',
      middleNames: '',
      surname: '',
      dateOfBirth: DateTime(1990),
      bloodType: 'O+',
      gender: Gender.male,
      isOrganDonor: false,
    ));
    
    final medId = 'test_med_id_${DateTime.now().millisecondsSinceEpoch}';
    final medsRepo = MedicationsRepository(db);
    await medsRepo.addMedication(Medication(
      id: medId,
      profileId: profileId,
      name: 'Med 2',
      dosage: '10mg',
      type: 'Tablet',
      notificationEnabled: true,
      alarmEnabled: false,
      timeOfDay: const TimeOfDay(hour: 10, minute: 0),
      isActive: true,
    ));

    final response = NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotificationAction,
      actionId: 'mark_taken',
      payload: medId,
    );

    // Call the tap directly
    await NotificationService().markMedicationTaken(response.payload!);

    final logs = await medsRepo.loadLogsForDate(DateTime.now(), profileId);

    expect(logs.length, 1);
    expect(logs.first.medicationId, medId);
    expect(logs.first.isTaken, true);
  });
}
