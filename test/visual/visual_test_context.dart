import 'dart:convert';
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
import 'package:open_cloud_health/models/insurance_policy.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/profile_share_config.dart';
import 'package:open_cloud_health/models/profile_share_models.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/providers/weight_preferences_provider.dart';
import 'package:open_cloud_health/repositories/allergies_repository.dart';
import 'package:open_cloud_health/repositories/checkups_repository.dart';
import 'package:open_cloud_health/repositories/emergency_repository.dart';
import 'package:open_cloud_health/repositories/history_repository.dart';
import 'package:open_cloud_health/repositories/insurance_repository.dart';
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

class MockVisualBackupService extends Mock implements BackupService {}
class MockVisualNotificationService extends Mock implements NotificationService {}
class MockVisualFileService extends Mock implements FileService {}

/// Full in-memory implementation of [SecureStorage] so all screens, providers,
/// theme toggles, E2E settings, and profile sharing configurations work reactively
/// without platform channel dependencies or missing stub errors.
class InMemorySecureStorage extends SecureStorage {
  String? _lastProfileId;
  bool _e2eEnabled = false;
  String? _e2ePasswordHash;
  String? _e2eSalt;
  String? _e2eRecoveryKey = 'A1B2-C3D4-E5F6-7890-ABCD-EF12-3456-7890';
  String? _e2eCachedPass;
  BackupFrequency _backupFrequency = BackupFrequency.daily;
  bool _backupWifiOnly = true;
  DateTime? _lastAutoBackupTime = DateTime.now().subtract(const Duration(hours: 6));
  String _localMasterKey = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
  String _dbKey = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';
  bool _strictBiometricsOnly = false;
  ShareSyncFrequency _shareSyncFrequency = ShareSyncFrequency.daily;
  bool _shareSyncWifiOnly = true;
  final Map<String, ActiveShareConfig> _activeShares = {};
  int _autoLockGraceSeconds = 30;
  AppThemeMode _themeMode = AppThemeMode.light;
  String _themePreset = AppThemePresets.defaultPresetId;

  InMemorySecureStorage({String? initialLastProfileId})
      : _lastProfileId = initialLastProfileId;

  @override
  Future clear() async {
    _lastProfileId = null;
    _activeShares.clear();
  }

  @override
  Future<void> saveLastProfileId(String id) async => _lastProfileId = id;

  @override
  Future<String?> getLastProfileId() async => _lastProfileId;

  @override
  Future<bool> isE2eBackupEnabled() async => _e2eEnabled;

  @override
  Future<void> setE2eBackupEnabled(bool enabled) async => _e2eEnabled = enabled;

  @override
  Future<String?> getE2ePasswordHash() async => _e2ePasswordHash;

  @override
  Future<void> setE2ePasswordHash(String? hash) async => _e2ePasswordHash = hash;

  @override
  Future<String?> getE2eSalt() async => _e2eSalt;

  @override
  Future<void> setE2eSalt(String? salt) async => _e2eSalt = salt;

  @override
  Future<String?> getE2eRecoveryKey() async => _e2eRecoveryKey;

  @override
  Future<void> setE2eRecoveryKey(String? recoveryKey) async =>
      _e2eRecoveryKey = recoveryKey;

  @override
  Future<String?> getE2eCachedPassword() async => _e2eCachedPass;

  @override
  Future<void> setE2eCachedPassword(String? password) async =>
      _e2eCachedPass = password;

  @override
  Future<void> clearE2eSettings() async {
    _e2eEnabled = false;
    _e2ePasswordHash = null;
    _e2eSalt = null;
    _e2eRecoveryKey = null;
    _e2eCachedPass = null;
  }

  @override
  Future<BackupFrequency> getBackupFrequency() async => _backupFrequency;

  @override
  Future<void> setBackupFrequency(BackupFrequency frequency) async =>
      _backupFrequency = frequency;

  @override
  Future<bool> getBackupWifiOnly() async => _backupWifiOnly;

  @override
  Future<void> setBackupWifiOnly(bool wifiOnly) async =>
      _backupWifiOnly = wifiOnly;

  @override
  Future<DateTime?> getLastAutoBackupTime() async => _lastAutoBackupTime;

  @override
  Future<void> setLastAutoBackupTime(DateTime dateTime) async =>
      _lastAutoBackupTime = dateTime;

  @override
  Future<String> getOrCreateLocalMasterKey() async => _localMasterKey;

  @override
  Future<bool> isStrictBiometricsOnly() async => _strictBiometricsOnly;

  @override
  Future<void> setStrictBiometricsOnly(bool enabled) async =>
      _strictBiometricsOnly = enabled;

  @override
  Future<String?> getLocalMasterKey() async => _localMasterKey;

  @override
  Future<void> setLocalMasterKey(String key) async => _localMasterKey = key;

  @override
  Future<void> clearLocalMasterKey() async {}

  @override
  Future<String> getOrCreateDatabaseKey() async => _dbKey;

  @override
  Future<String?> getDatabaseKey() async => _dbKey;

  @override
  Future<void> setDatabaseKey(String key) async => _dbKey = key;

  @override
  Future<void> clearDatabaseKey() async {}

  @override
  Future<ShareSyncFrequency> getShareSyncFrequency() async => _shareSyncFrequency;

  @override
  Future<void> setShareSyncFrequency(ShareSyncFrequency frequency) async =>
      _shareSyncFrequency = frequency;

  @override
  Future<bool> getShareSyncWifiOnly() async => _shareSyncWifiOnly;

  @override
  Future<void> setShareSyncWifiOnly(bool wifiOnly) async =>
      _shareSyncWifiOnly = wifiOnly;

  @override
  Future<void> saveActiveShareConfig(ActiveShareConfig config) async {
    _activeShares[config.profileId] = config;
  }

  @override
  Future<ActiveShareConfig?> getActiveShareConfig(String profileId) async =>
      _activeShares[profileId];

  @override
  Future<List<ActiveShareConfig>> getAllActiveShareConfigs() async =>
      _activeShares.values.toList();

  @override
  Future<void> deleteActiveShareConfig(String profileId) async {
    _activeShares.remove(profileId);
  }

  @override
  Future<int> getAutoLockGraceSeconds() async => _autoLockGraceSeconds;

  @override
  Future<void> setAutoLockGraceSeconds(int seconds) async =>
      _autoLockGraceSeconds = seconds;

  @override
  Future<AppThemeMode> getThemeMode() async => _themeMode;

  @override
  Future<void> setThemeMode(AppThemeMode mode) async => _themeMode = mode;

  @override
  Future<String> getThemePreset() async => _themePreset;

  @override
  Future<void> setThemePreset(String presetId) async => _themePreset = presetId;
}

class VisualTestContext {
  final AppDatabase db;
  final MockVisualBackupService backupService;
  final InMemorySecureStorage secureStorage;
  final MockVisualNotificationService notificationService;
  final MockVisualFileService fileService;
  final Profile primaryProfile;
  final Profile femaleProfile;
  final Profile sharedProfile;
  final Profile archivedProfile;
  final List<Medication> medications;
  final List<HistoryEvent> historyEvents;

  VisualTestContext({
    required this.db,
    required this.backupService,
    required this.secureStorage,
    required this.notificationService,
    required this.fileService,
    required this.primaryProfile,
    required this.femaleProfile,
    required this.sharedProfile,
    required this.archivedProfile,
    required this.medications,
    required this.historyEvents,
  });

  List<Override> get providerOverrides => [
        appDatabaseProvider.overrideWithValue(db),
        backupServiceProvider.overrideWithValue(backupService),
        secureStorageProvider.overrideWithValue(secureStorage),
        notificationServiceProvider.overrideWithValue(notificationService),
        fileServiceProvider.overrideWithValue(fileService),
      ];
}

Future<VisualTestContext> createVisualTestContext() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  registerFallbackValue(BackupFrequency.daily);
  registerFallbackValue(AppThemeMode.system);

  final tempDocsDir = Directory.systemTemp.createTempSync('och_visual_docs_');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('com.opencloudhealth.app/security'),
    (call) async => true,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tempDocsDir.path,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/local_auth'),
    (call) async => true,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter.baseflow.com/permissions/methods'),
    (call) async {
      if (call.method == 'checkPermissionStatus' ||
          call.method == 'checkServiceStatus') {
        return 1; // granted
      }
      if (call.method == 'requestPermissions') {
        return <int, int>{};
      }
      return true;
    },
  );

  final db = AppDatabase(NativeDatabase.memory());
  final backupService = MockVisualBackupService();
  final secureStorage = InMemorySecureStorage(initialLastProfileId: 'profile-alex');
  final notificationService = MockVisualNotificationService();
  final fileService = MockVisualFileService();

  when(() => backupService.getConnectedUser()).thenAnswer((_) async => null);
  when(() => backupService.getGoogleStorageInfo(interactive: any(named: 'interactive')))
      .thenAnswer((_) async => null);

  when(() => notificationService.isEmergencyChannelEnabled()).thenAnswer((_) async => true);
  when(() => notificationService.isBatteryOptimizationDisabled()).thenAnswer((_) async => true);
  when(() => notificationService.requestDisableBatteryOptimization())
      .thenAnswer((_) async => true);
  when(() => notificationService.syncEmergencyNotification(any())).thenAnswer((_) async {});
  when(() => notificationService.cancelMedicationNotifications(any())).thenAnswer((_) async {});

  when(() => fileService.getProfileImagePath(any())).thenAnswer((_) async => '');
  when(() => fileService.localPath).thenAnswer((_) async => tempDocsDir.path);

  final now = DateTime.now();

  final primaryProfile = Profile(
    id: 'profile-alex',
    name: 'Alexander',
    middleNames: 'Fleming',
    surname: 'Scott',
    dateOfBirth: DateTime(1984, 5, 18),
    gender: Gender.male,
    bloodType: 'O-',
    isOrganDonor: true,
    chronicConditions: const ['Hypertension', 'Type 2 Diabetes', 'Asthma'],
  );

  final femaleProfile = Profile(
    id: 'profile-elena',
    name: 'Elena',
    middleNames: 'Marie',
    surname: 'Scott',
    dateOfBirth: DateTime(1988, 9, 12),
    gender: Gender.female,
    bloodType: 'A+',
    isOrganDonor: true,
    trackOvulation: true,
    chronicConditions: const ['Migraine'],
  );

  final sharedProfile = Profile(
    id: 'profile-shared-marcus',
    name: 'Marcus',
    middleNames: 'Arthur',
    surname: 'Vance',
    dateOfBirth: DateTime(1955, 2, 10),
    gender: Gender.male,
    bloodType: 'B+',
    isOrganDonor: false,
    chronicConditions: const ['Atrial Fibrillation', 'Osteoarthritis'],
    isShared: true,
    isReadOnly: true,
    sharedBy: 'Elena Scott',
    lastSyncedAt: now.subtract(const Duration(hours: 2)),
  );

  final archivedProfile = Profile(
    id: 'profile-archived-robert',
    name: 'Robert',
    middleNames: 'James',
    surname: 'Scott',
    dateOfBirth: DateTime(1952, 11, 3),
    gender: Gender.male,
    bloodType: 'O+',
    isOrganDonor: true,
    isArchived: true,
    archivedAt: now.subtract(const Duration(days: 45)),
  );

  final profilesRepo = ProfilesRepository(db);
  final emergencyRepo = EmergencyRepository(db);
  final medsRepo = MedicationsRepository(db);
  final allergiesRepo = AllergiesRepository(db);
  final checkupsRepo = CheckupsRepository(db);
  final historyRepo = HistoryRepository(db);
  final vitalsRepo = VitalsRepository(db);
  final periodRepo = PeriodRepository(db);
  final insuranceRepo = InsuranceRepository(db);

  await profilesRepo.addProfile(primaryProfile);
  await profilesRepo.addProfile(femaleProfile);
  await profilesRepo.addProfile(sharedProfile);
  await profilesRepo.addProfile(archivedProfile);

  await emergencyRepo.setPrimaryProfileId(primaryProfile.id);

  await emergencyRepo.addEmergencyContact(EmergencyContact(
    id: 'ice-1',
    profileId: primaryProfile.id,
    name: 'Elena Scott',
    relationship: 'Spouse',
    phoneNumber: '+1 (555) 234-5678',
  ));
  await emergencyRepo.addEmergencyContact(EmergencyContact(
    id: 'ice-2',
    profileId: primaryProfile.id,
    name: 'Dr. Gregory House',
    relationship: 'Primary Cardiologist',
    phoneNumber: '+1 (555) 876-5432',
  ));

  await emergencyRepo.saveLockScreenSetting(LockScreenSetting(
    profileId: primaryProfile.id,
    isEnabled: true,
    showName: true,
    showAge: true,
    showBloodType: true,
    showOrganDonor: true,
    showChronicConditions: true,
    showAllergies: true,
    showMedications: true,
    showContacts: true,
    showInsurance: true,
  ));

  await insuranceRepo.saveInsurance(InsurancePolicy(
    profileId: primaryProfile.id,
    provider: 'Discovery Health Medical Scheme',
    planName: 'Classic Comprehensive PPO Network',
    policyNumber: 'DH-99887766-001',
    groupNumber: 'GRP-1042-MED',
    subscriberName: 'Alexander Fleming Scott',
    memberId: '01-PRIMARY',
    emergencyPhone: '+1 (800) 555-0199',
    notes: 'Covers emergency triage, specialist consultations, and chronic medication.',
  ));

  await allergiesRepo.addAllergy(Allergy(
    id: 'alg-1',
    profileId: primaryProfile.id,
    name: 'Penicillin',
    note: 'Severe anaphylaxis reaction - carry EpiPen',
  ));
  await allergiesRepo.addAllergy(Allergy(
    id: 'alg-2',
    profileId: primaryProfile.id,
    name: 'Sulfonamides',
    note: 'Moderate skin rash and hives',
  ));

  // Seed Medications & Logs
  final med1 = Medication(
    id: 'med-lisinopril',
    profileId: primaryProfile.id,
    name: 'Lisinopril',
    dosage: '1 tablet (10mg)',
    type: 'Tablet',
    daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
    timesOfDay: const [TimeOfDay(hour: 8, minute: 0)],
    notificationEnabled: true,
    trackInventory: true,
    stockQuantity: 30.0,
    lowStockThreshold: 7.0,
    isActive: true,
  );
  final med2 = Medication(
    id: 'med-metformin',
    profileId: primaryProfile.id,
    name: 'Metformin HCl',
    dosage: '1 tablet (500mg)',
    type: 'Tablet',
    daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
    timesOfDay: const [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 20, minute: 0)],
    notificationEnabled: true,
    trackInventory: true,
    stockQuantity: 17.0, // After 13 logged doses -> 4 remaining (triggers low stock warning!)
    lowStockThreshold: 10.0,
    isActive: true,
  );
  final med3 = Medication(
    id: 'med-albuterol',
    profileId: primaryProfile.id,
    name: 'Albuterol Sulfate Inhaler',
    dosage: '2 puffs (90 mcg)',
    type: 'Inhaler',
    isAsNeeded: true,
    trackInventory: true,
    stockQuantity: 140.0,
    lowStockThreshold: 20.0,
    isActive: true,
  );

  await medsRepo.addMedication(med1);
  await medsRepo.addMedication(med2);
  await medsRepo.addMedication(med3);

  for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
    final amDate = DateTime(now.year, now.month, now.day, 8, 0)
        .subtract(Duration(days: dayOffset));
    final pmDate = DateTime(now.year, now.month, now.day, 20, 0)
        .subtract(Duration(days: dayOffset));
    await medsRepo.addLog(MedicationLog(
      id: 'mlog-lis-$dayOffset',
      medicationId: med1.id,
      timestamp: amDate,
      isTaken: true,
      dosage: '1 tablet (10mg)',
    ));
    await medsRepo.addLog(MedicationLog(
      id: 'mlog-met-am-$dayOffset',
      medicationId: med2.id,
      timestamp: amDate,
      isTaken: true,
      dosage: '1 tablet (500mg)',
    ));
    if (dayOffset > 0) {
      await medsRepo.addLog(MedicationLog(
        id: 'mlog-met-pm-$dayOffset',
        medicationId: med2.id,
        timestamp: pmDate,
        isTaken: true,
        dosage: '1 tablet (500mg)',
      ));
    }
  }

  // Seed Checkups
  final chkCardio = Checkup(
    id: 'chk-cardio',
    profileId: primaryProfile.id,
    name: 'Cardiology Comprehensive Examination',
    frequencyInMonths: 6,
    isActive: true,
  );
  final chkHba1c = Checkup(
    id: 'chk-hba1c',
    profileId: primaryProfile.id,
    name: 'HbA1c & Metabolic Diabetes Panel',
    frequencyInMonths: 3,
    isActive: true,
  );
  final chkDental = Checkup(
    id: 'chk-dental',
    profileId: primaryProfile.id,
    name: 'Dental Prophylaxis & Periodontal Exam',
    frequencyInMonths: 6,
    isActive: true,
  );
  final chkInactive = Checkup(
    id: 'chk-inactive',
    profileId: primaryProfile.id,
    name: 'Travel Vaccination Booster Review',
    frequencyInMonths: 12,
    isActive: false,
  );

  await checkupsRepo.addCheckup(chkCardio);
  await checkupsRepo.addCheckup(chkHba1c);
  await checkupsRepo.addCheckup(chkDental);
  await checkupsRepo.addCheckup(chkInactive);

  await checkupsRepo.addCheckupLog(CheckupLog(
    id: 'chklog-1',
    checkupId: chkCardio.id,
    dateCompleted: now.subtract(const Duration(days: 35)),
    location: 'Princeton-Plainsboro Heart Institute',
    doctorName: 'Dr. Gregory House, MD',
    notes: 'Sinus rhythm normal. Continue Lisinopril 10mg daily.',
  ));
  await checkupsRepo.addCheckupLog(CheckupLog(
    id: 'chklog-2',
    checkupId: chkHba1c.id,
    dateCompleted: now.subtract(const Duration(days: 110)), // Overdue!
    location: 'Quest Clinical Diagnostics',
    doctorName: 'Dr. Lisa Cuddy, MD',
    notes: 'HbA1c at 6.4%. Follow up in 3 months.',
  ));

  // Seed History Events
  final evt1 = HistoryEvent(
    id: 'he-1',
    profileId: primaryProfile.id,
    title: 'Annual Cardiology & Echocardiogram Evaluation',
    description: 'Left ventricular ejection fraction 62%. Blood pressure well-controlled on current regimen.',
    date: now.subtract(const Duration(days: 12)),
    eventType: EventType.specialistConsultation,
    provider: 'Dr. Gregory House, MD',
    facility: 'Princeton-Plainsboro Teaching Hospital',
  );
  final evt2 = HistoryEvent(
    id: 'he-2',
    profileId: primaryProfile.id,
    title: 'Comprehensive Lipid & HbA1c Lab Panel',
    description: 'Total Cholesterol: 178 mg/dL, LDL: 98 mg/dL, HDL: 54 mg/dL, Fasting Glucose: 98 mg/dL.',
    date: now.subtract(const Duration(days: 28)),
    eventType: EventType.labTest,
    provider: 'Dr. Allison Cameron, MD',
    facility: 'Metro Clinical Pathology Labs',
  );
  final evt3 = HistoryEvent(
    id: 'he-3',
    profileId: primaryProfile.id,
    title: 'Seasonal Influenza & COVID-19 Booster',
    description: 'Administered quadrivalent flu vaccine in left deltoid without adverse reaction.',
    date: now.subtract(const Duration(days: 64)),
    eventType: EventType.vaccination,
    provider: 'Nurse Clara Oswald, RN',
    facility: 'Community Wellness Clinic',
  );

  await historyRepo.addEvent(evt1);
  await historyRepo.addEvent(evt2);
  await historyRepo.addEvent(evt3);

  // Seed Vitals (Blood Pressure, Weight + BMI Prefs, Blood Sugar)
  final bpSeries = <(double, double, int, String)>[
    (132, 86, 18, 'Before morning medication'),
    (128, 82, 14, 'Morning resting reading'),
    (126, 80, 10, 'Post-walk check'),
    (124, 79, 7, 'Morning baseline'),
    (121, 78, 4, 'Evening check'),
    (119, 76, 2, 'Optimal resting BP'),
    (120, 78, 0, 'Today morning reading'),
  ];
  for (int i = 0; i < bpSeries.length; i++) {
    final (sys, dia, daysAgo, note) = bpSeries[i];
    await vitalsRepo.addLog(VitalLog(
      id: 'vit-bp-$i',
      profileId: primaryProfile.id,
      type: VitalType.bloodPressure,
      value1: sys,
      value2: dia,
      unit: 'mmHg',
      date: now.subtract(Duration(days: daysAgo)),
      note: note,
    ));
  }

  final weightSeries = <(double, int, String)>[
    (80.4, 28, 'Initial baseline weight'),
    (79.8, 23, 'Week 1 check-in'),
    (79.2, 18, 'Consistent cardio'),
    (78.7, 13, 'Morning weigh-in'),
    (78.3, 8, 'Post-workout'),
    (77.8, 4, 'Mid-week check'),
    (77.4, 0, 'Today morning weigh-in'),
  ];
  for (int i = 0; i < weightSeries.length; i++) {
    final (kg, daysAgo, note) = weightSeries[i];
    await vitalsRepo.addLog(VitalLog(
      id: 'vit-wt-$i',
      profileId: primaryProfile.id,
      type: VitalType.weight,
      value1: kg,
      unit: 'kg',
      date: now.subtract(Duration(days: daysAgo)),
      note: note,
    ));
  }

  // Save WeightPreferences (heightCm & targetWeightKg) so BMI & Goal cards render
  const weightPrefs = WeightPreferences(
    heightCm: 178.0,
    targetWeightKg: 74.0,
    unit: 'kg',
  );
  await db.into(db.settings).insertOnConflictUpdate(
        SettingEntry(
          key: 'weight_preferences_${primaryProfile.id}',
          value: jsonEncode(weightPrefs.toJson()),
        ),
      );

  final sugarSeries = <(double, int, String)>[
    (112, 14, 'Fasting morning'),
    (106, 11, 'Fasting morning'),
    (118, 8, '2h post-meal'),
    (101, 5, 'Fasting morning'),
    (99, 2, 'Fasting morning'),
    (96, 0, 'Today fasting glucose'),
  ];
  for (int i = 0; i < sugarSeries.length; i++) {
    final (mgdl, daysAgo, note) = sugarSeries[i];
    await vitalsRepo.addLog(VitalLog(
      id: 'vit-bs-$i',
      profileId: primaryProfile.id,
      type: VitalType.bloodSugar,
      value1: mgdl,
      unit: 'mg/dL',
      date: now.subtract(Duration(days: daysAgo)),
      note: note,
    ));
  }

  // Seed Period Cycles & Logs for both femaleProfile and primaryProfile
  for (final pid in [femaleProfile.id, primaryProfile.id]) {
    final cycle1Start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
    final cycle2Start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 2));

    await periodRepo.addCycle(PeriodCycle(
      id: 'cyc-past-$pid',
      profileId: pid,
      startDate: cycle1Start,
      endDate: cycle1Start.add(const Duration(days: 4)),
    ));
    await periodRepo.addCycle(PeriodCycle(
      id: 'cyc-curr-$pid',
      profileId: pid,
      startDate: cycle2Start,
      endDate: cycle2Start.add(const Duration(days: 3)),
    ));

    for (int d = 0; d < 3; d++) {
      await periodRepo.upsertLog(PeriodLog(
        cycleId: 'cyc-curr-$pid',
        date: cycle2Start.add(Duration(days: d)),
        flowLevel: d == 0 ? FlowLevel.medium : (d == 1 ? FlowLevel.heavy : FlowLevel.light),
        moods: const [Mood.calm, Mood.happy],
        physicalSymptoms: const [PhysicalSymptom.cramps, PhysicalSymptom.headache],
      ));
    }
  }

  // Seed Active Share Config so ShareProfileScreen shows QR code & active share state
  await secureStorage.saveActiveShareConfig(ActiveShareConfig(
    profileId: primaryProfile.id,
    driveFileId: 'drive-file-99887766',
    encryptionKey: '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    options: const ShareModuleOptions(),
    createdAt: now.subtract(const Duration(days: 5)),
    lastSyncedAt: now.subtract(const Duration(hours: 1)),
    sharedBy: 'Alexander Scott',
    profileName: 'Alexander Scott',
  ));

  return VisualTestContext(
    db: db,
    backupService: backupService,
    secureStorage: secureStorage,
    notificationService: notificationService,
    fileService: fileService,
    primaryProfile: primaryProfile,
    femaleProfile: femaleProfile,
    sharedProfile: sharedProfile,
    archivedProfile: archivedProfile,
    medications: [med1, med2, med3],
    historyEvents: [evt1, evt2, evt3],
  );
}
