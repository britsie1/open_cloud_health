import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/backup_frequency.dart';
import 'package:open_cloud_health/models/checkup.dart';
import 'package:open_cloud_health/models/checkup_log.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/repositories/allergies_repository.dart';
import 'package:open_cloud_health/repositories/checkups_repository.dart';
import 'package:open_cloud_health/repositories/emergency_repository.dart';
import 'package:open_cloud_health/repositories/history_repository.dart';
import 'package:open_cloud_health/repositories/medications_repository.dart';
import 'package:open_cloud_health/repositories/period_repository.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/repositories/vitals_repository.dart';
import 'package:open_cloud_health/services/backup_service.dart';
import 'package:open_cloud_health/services/file_service.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/storage/secure_storage.dart';
import 'package:open_cloud_health/theme/app_theme_mode.dart';
import 'package:open_cloud_health/theme/app_theme_preset.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockBackupService extends Mock implements BackupService {}
class MockSecureStorage extends Mock implements SecureStorage {}
class MockNotificationService extends Mock implements NotificationService {}
class MockFileService extends Mock implements FileService {}

class TestDeviceConfig {
  final String name;
  final Size size;

  const TestDeviceConfig(this.name, this.size);
}

const List<TestDeviceConfig> kMatrixDevices = [
  TestDeviceConfig('Small Compact (320x568)', Size(320, 568)),
  TestDeviceConfig('Standard Android (360x640)', Size(360, 640)),
  TestDeviceConfig('Modern Phone (390x844)', Size(390, 844)),
  TestDeviceConfig('Large Screen (412x915)', Size(412, 915)),
];

const List<double> kMatrixTextScales = [1.0, 1.3, 1.5];

class OverflowTestContext {
  final AppDatabase db;
  final MockBackupService backupService;
  final MockSecureStorage secureStorage;
  final MockNotificationService notificationService;
  final MockFileService fileService;
  final Profile sampleProfile;

  OverflowTestContext({
    required this.db,
    required this.backupService,
    required this.secureStorage,
    required this.notificationService,
    required this.fileService,
    required this.sampleProfile,
  });

  List<Override> get providerOverrides => [
    appDatabaseProvider.overrideWithValue(db),
    backupServiceProvider.overrideWithValue(backupService),
    secureStorageProvider.overrideWithValue(secureStorage),
    notificationServiceProvider.overrideWithValue(notificationService),
    fileServiceProvider.overrideWithValue(fileService),
  ];
}

Future<OverflowTestContext> setupOverflowTestContext() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  registerFallbackValue(BackupFrequency.daily);
  registerFallbackValue(AppThemeMode.system);

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('com.opencloudhealth.app/security'),
    (call) async => true,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => '.',
  );

  final db = AppDatabase(NativeDatabase.memory());
  final backupService = MockBackupService();
  final secureStorage = MockSecureStorage();
  final notificationService = MockNotificationService();
  final fileService = MockFileService();

  when(() => secureStorage.getLastProfileId()).thenAnswer((_) async => 'patient-matrix-1');
  when(() => secureStorage.saveLastProfileId(any())).thenAnswer((_) async {});
  when(() => secureStorage.isE2eBackupEnabled()).thenAnswer((_) async => false);
  when(() => secureStorage.setE2eBackupEnabled(any())).thenAnswer((_) async {});
  when(() => secureStorage.getE2eRecoveryKey()).thenAnswer((_) async => 'key-1234');
  when(() => secureStorage.setE2eRecoveryKey(any())).thenAnswer((_) async {});
  when(() => secureStorage.getBackupFrequency()).thenAnswer((_) async => BackupFrequency.daily);
  when(() => secureStorage.setBackupFrequency(any())).thenAnswer((_) async {});
  when(() => secureStorage.getBackupWifiOnly()).thenAnswer((_) async => true);
  when(() => secureStorage.setBackupWifiOnly(any())).thenAnswer((_) async {});
  when(() => secureStorage.isStrictBiometricsOnly()).thenAnswer((_) async => false);
  when(() => secureStorage.setStrictBiometricsOnly(any())).thenAnswer((_) async {});
  when(() => secureStorage.getThemeMode()).thenAnswer((_) async => AppThemeMode.system);
  when(() => secureStorage.setThemeMode(any())).thenAnswer((_) async {});
  when(() => secureStorage.getThemePreset()).thenAnswer((_) async => AppThemePresets.defaultPresetId);
  when(() => secureStorage.setThemePreset(any())).thenAnswer((_) async {});

  when(() => backupService.getConnectedUser()).thenAnswer((_) async => null);
  when(() => backupService.getGoogleStorageInfo(interactive: any(named: 'interactive'))).thenAnswer((_) async => null);

  when(() => notificationService.isEmergencyChannelEnabled()).thenAnswer((_) async => true);
  when(() => notificationService.isBatteryOptimizationDisabled()).thenAnswer((_) async => true);
  when(() => notificationService.requestDisableBatteryOptimization()).thenAnswer((_) async => true);
  when(() => notificationService.syncEmergencyNotification(any())).thenAnswer((_) async {});
  when(() => notificationService.cancelMedicationNotifications(any())).thenAnswer((_) async {});

  when(() => fileService.getProfileImagePath(any())).thenAnswer((_) async => '');
  when(() => fileService.localPath).thenAnswer((_) async => Directory.systemTemp.path);

  final sampleProfile = Profile(
    id: 'patient-matrix-1',
    name: 'Alexander',
    middleNames: 'Fleming',
    surname: 'Scott',
    dateOfBirth: DateTime(1980, 5, 20),
    gender: Gender.male,
    bloodType: 'O-',
    isOrganDonor: true,
    chronicConditions: const ['Hypertension', 'Type 2 Diabetes', 'Asthma'],
  );

  final profilesRepo = ProfilesRepository(db);
  final emergencyRepo = EmergencyRepository(db);
  final medsRepo = MedicationsRepository(db);
  final allergiesRepo = AllergiesRepository(db);
  final checkupsRepo = CheckupsRepository(db);
  final historyRepo = HistoryRepository(db);
  final vitalsRepo = VitalsRepository(db);
  final periodRepo = PeriodRepository(db);

  await profilesRepo.addProfile(sampleProfile);
  await emergencyRepo.setPrimaryProfileId(sampleProfile.id);

  await emergencyRepo.addEmergencyContact(EmergencyContact(
    id: 'ice-m1',
    profileId: sampleProfile.id,
    name: 'Sarah Scott',
    relationship: 'Spouse',
    phoneNumber: '+1-555-0199',
  ));
  await emergencyRepo.saveLockScreenSetting(LockScreenSetting(
    profileId: sampleProfile.id,
    isEnabled: true,
    showName: true,
    showAge: true,
    showBloodType: true,
    showOrganDonor: true,
    showChronicConditions: true,
    showAllergies: true,
    showMedications: true,
    showContacts: true,
  ));

  await allergiesRepo.addAllergy(Allergy(
    id: 'alg-m1',
    profileId: sampleProfile.id,
    name: 'Penicillin',
    note: 'Severe anaphylaxis reaction',
  ));

  final med1 = Medication(
    id: 'med-m1',
    profileId: sampleProfile.id,
    name: 'Lisinopril Blood Pressure Regular Tablets',
    dosage: '10mg once daily in morning with water',
    type: 'Tablet',
    daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
    timesOfDay: const [TimeOfDay(hour: 8, minute: 0)],
    trackInventory: true,
    stockQuantity: 28.0,
    lowStockThreshold: 5.0,
    isActive: true,
  );
  await medsRepo.addMedication(med1);
  for (int i = 0; i < 5; i++) {
    await medsRepo.addLog(MedicationLog(
      id: 'mlog-m$i',
      medicationId: med1.id,
      timestamp: DateTime.now().subtract(Duration(days: i)),
      isTaken: true,
      dosage: '10mg',
    ));
  }

  final checkup1 = Checkup(
    id: 'chk-m1',
    profileId: sampleProfile.id,
    name: 'Cardiology Comprehensive Examination',
    frequencyInMonths: 6,
  );
  await checkupsRepo.addCheckup(checkup1);
  await checkupsRepo.addCheckupLog(CheckupLog(
    id: 'chklog-m1',
    checkupId: checkup1.id,
    dateCompleted: DateTime.now().subtract(const Duration(days: 30)),
    location: 'St. Jude Medical Center',
    doctorName: 'Dr. Gregory House, MD',
    notes: 'Resting BP within acceptable range.',
  ));

  await historyRepo.addEvent(HistoryEvent(
    id: 'he-m1',
    profileId: sampleProfile.id,
    title: 'Emergency Room Admission for Respiratory Discomfort',
    description: 'Received nebulizer treatment and discharged with maintenance plan.',
    date: DateTime.now().subtract(const Duration(days: 15)),
    provider: 'Dr. Allison Cameron',
    facility: 'Princeton-Plainsboro Teaching Hospital',
  ));

  await vitalsRepo.addLog(VitalLog(
    id: 'vit-m1',
    profileId: sampleProfile.id,
    type: VitalType.bloodPressure,
    value1: 120,
    value2: 80,
    unit: 'mmHg',
    date: DateTime.now(),
    note: 'Morning measurement before medication',
  ));

  await periodRepo.addCycle(PeriodCycle(
    id: 'cyc-m1',
    profileId: sampleProfile.id,
    startDate: DateTime.now().subtract(const Duration(days: 28)),
    endDate: DateTime.now().subtract(const Duration(days: 24)),
  ));
  await periodRepo.upsertLog(PeriodLog(
    cycleId: 'cyc-m1',
    date: DateTime.now().subtract(const Duration(days: 28)),
    flowLevel: FlowLevel.medium,
    moods: [Mood.calm],
    physicalSymptoms: [PhysicalSymptom.headache],
  ));

  return OverflowTestContext(
    db: db,
    backupService: backupService,
    secureStorage: secureStorage,
    notificationService: notificationService,
    fileService: fileService,
    sampleProfile: sampleProfile,
  );
}

Future<void> testScreenAcrossMatrix(
  WidgetTester tester, {
  required String screenName,
  required Widget Function(OverflowTestContext ctx) screenBuilder,
  required OverflowTestContext ctx,
  List<TestDeviceConfig> devices = kMatrixDevices,
  List<double> textScales = kMatrixTextScales,
  Future<void> Function(WidgetTester tester)? interaction,
}) async {
  for (final device in devices) {
    for (final scale in textScales) {
      tester.view.physicalSize = device.size * tester.view.devicePixelRatio;

      FlutterErrorDetails? caughtDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
        originalOnError?.call(details);
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: ctx.providerOverrides,
          child: MediaQuery(
            data: MediaQueryData(
              size: device.size,
              textScaler: TextScaler.linear(scale),
            ),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: screenBuilder(ctx),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      if (interaction != null) {
        await interaction(tester);
        await tester.pump(const Duration(milliseconds: 100));
      }

      FlutterError.onError = originalOnError;

      final error = tester.takeException();
      if (error != null) {
        debugPrint('--- OVERFLOW ERROR ON $screenName ON ${device.name} scale $scale ---');
        if (caughtDetails != null) {
          debugPrint('Summary: ${caughtDetails!.summary}');
          debugPrint('Context: ${caughtDetails!.context}');
          final info = caughtDetails!.informationCollector?.call() ?? [];
          for (final diag in info) {
            debugPrint('Diagnostic: ${diag.toString()}');
          }
        } else {
          debugPrint(error.toString());
        }
      }
      expect(error, isNull,
          reason: 'Layout overflow or exception detected on $screenName on ${device.name} with font scale ${scale}x: $error');
    }
  }

  // Clean unmount and flush pending timers
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 200));
  tester.view.resetPhysicalSize();
}
