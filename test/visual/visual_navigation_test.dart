import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/theme/app_theme_mode.dart';
import 'package:open_cloud_health/theme/app_theme_preset.dart';
import 'package:open_cloud_health/utils/constants.dart';

import 'visual_navigator.dart';
import 'visual_test_context.dart';

/// Configurable CLI flags via `--dart-define`:
/// - `--dart-define=SCREEN=all` (or comma-separated: `home,medications,vitals,history,checkups,period,profile,settings,emergency,onboarding,themes`)
/// - `--dart-define=THEME=ocean_blue` (`ocean_blue`, `emerald_green`, `royal_purple`, `coral_sunset`, `rose_health`, `slate_monochrome`)
/// - `--dart-define=DARK=false` (`true` or `false`)
/// - `--dart-define=ANNOTATE=false` (`true` to generate `*_annotated.png` with numbered interactive element boxes)
const String _kScreenFilter = String.fromEnvironment('SCREEN', defaultValue: 'all');
const String _kThemePresetId = String.fromEnvironment('THEME', defaultValue: 'ocean_blue');
const bool _kDarkMode = bool.fromEnvironment('DARK', defaultValue: false);
const bool _kAnnotate = bool.fromEnvironment('ANNOTATE', defaultValue: false);

bool _shouldRunSection(String sectionKey) {
  final normalized = _kScreenFilter.trim().toLowerCase();
  if (normalized.isEmpty || normalized == 'all') return true;
  final targets = normalized.split(',').map((s) => s.trim()).toSet();
  return targets.contains(sectionKey.toLowerCase());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Visual Navigation & Screen Capture Suite', (tester) async {
    final ctx = await createVisualTestContext();
    final nav = VisualNavigator(tester: tester, ctx: ctx);

    const initialMode = _kDarkMode ? AppThemeMode.dark : AppThemeMode.light;
    final initialPreset = AppThemePresets.fromId(_kThemePresetId);

    await nav.initializeApp(
      initialLocation: '${AppRoutes.home}/${ctx.primaryProfile.id}',
      initialExtra: ctx.primaryProfile,
      themeMode: initialMode,
      preset: initialPreset,
    );

    final pid = ctx.primaryProfile.id;

    // =========================================================================
    // 1. HOME & SHELL NAVIGATION
    // =========================================================================
    if (_shouldRunSection('home')) {
      await nav.go('${AppRoutes.home}/$pid', extra: ctx.primaryProfile);
      await nav.capture(
        '01_home_dashboard_top',
        flow: '1. Home & Dashboard',
        description: 'Home screen top: active profile header, quick vitals summary, and medication schedule',
        annotate: _kAnnotate,
      );

      await nav.scrollDown(dy: 420);
      await nav.capture(
        '02_home_dashboard_scrolled',
        flow: '1. Home & Dashboard',
        description: 'Home screen scrolled: preventive checkups, cycle tracker card, and quick actions',
        annotate: _kAnnotate,
      );

      // Shared Read-Only Profile Home View
      await nav.go(
        '${AppRoutes.home}/${ctx.sharedProfile.id}',
        extra: ctx.sharedProfile,
      );
      await nav.capture(
        '03_home_shared_readonly',
        flow: '1. Home & Dashboard',
        description: 'Home screen for a shared read-only profile showing cloud sync status banner',
        annotate: _kAnnotate,
      );
    }

    // =========================================================================
    // 2. MEDICATION TRACKER & EDITOR
    // =========================================================================
    if (_shouldRunSection('medications')) {
      await nav.go('${AppRoutes.home}/$pid', extra: ctx.primaryProfile);
      await nav.tapBottomNav(1);
      await nav.capture(
        '04_medication_today_tab',
        flow: '2. Medications',
        description: 'Medication Tracker — Today tab with adherence streak card, scheduled doses, and PRN section',
        annotate: _kAnnotate,
      );

      await nav.tapTab('Medications');
      await nav.capture(
        '05_medication_all_tab',
        flow: '2. Medications',
        description: 'Medication Tracker — Medications tab with inventory stock badges and low-stock alert',
        annotate: _kAnnotate,
      );

      await nav.tapTab('Log');
      await nav.capture(
        '06_medication_log_tab',
        flow: '2. Medications',
        description: 'Medication Tracker — Log tab displaying chronological dose history',
        annotate: _kAnnotate,
      );

      await nav.go(
        '${AppRoutes.medicationEditor}/$pid',
        extra: ctx.medications.first,
      );
      await nav.capture(
        '07_medication_editor',
        flow: '2. Medications',
        description: 'Medication Editor screen for configuring dosage, schedule, reminders, and inventory',
        annotate: _kAnnotate,
      );
    }

    // =========================================================================
    // 3. VITALS & MEASUREMENTS (BP, WEIGHT + BMI, BLOOD SUGAR)
    // =========================================================================
    if (_shouldRunSection('vitals')) {
      await nav.go('${AppRoutes.vitalTracker}/$pid/${VitalType.bloodPressure.name}');
      await nav.capture(
        '08_vitals_blood_pressure',
        flow: '3. Vitals & Charts',
        description: 'Blood Pressure — Overview tab with AHA classification gauge, 7/30-day averages, and AM/PM split',
        annotate: _kAnnotate,
      );

      await nav.tapTab('Trends');
      await nav.capture(
        '08b_vitals_blood_pressure_trends',
        flow: '3. Vitals & Charts',
        description: 'Blood Pressure — Trends tab with dual systolic/diastolic trajectory chart and target lines',
        annotate: _kAnnotate,
      );

      await nav.go('${AppRoutes.vitalTracker}/$pid/${VitalType.weight.name}');
      await nav.capture(
        '09_vitals_weight_overview',
        flow: '3. Vitals & Charts',
        description: 'Weight Tracker — Overview tab with BMI classification gauge and Weight Goal progress card',
        annotate: _kAnnotate,
      );

      await nav.tapTab('Trends');
      await nav.capture(
        '10_vitals_weight_trends',
        flow: '3. Vitals & Charts',
        description: 'Weight Tracker — Trends tab with interactive weight trajectory chart',
        annotate: _kAnnotate,
      );

      await nav.tapTab('History');
      await nav.capture(
        '11_vitals_weight_history',
        flow: '3. Vitals & Charts',
        description: 'Weight Tracker — History tab listing logged weight entries and deltas',
        annotate: _kAnnotate,
      );

      await nav.go('${AppRoutes.vitalTracker}/$pid/${VitalType.bloodSugar.name}');
      await nav.capture(
        '12_vitals_blood_sugar',
        flow: '3. Vitals & Charts',
        description: 'Blood Sugar — Overview tab with Time in Range bar, Estimated A1C, and Fasting vs Post-Meal averages',
        annotate: _kAnnotate,
      );

      await nav.tapTab('Trends');
      await nav.capture(
        '12b_vitals_blood_sugar_trends',
        flow: '3. Vitals & Charts',
        description: 'Blood Sugar — Trends tab with glucose trajectory chart and target threshold line',
        annotate: _kAnnotate,
      );
    }

    // =========================================================================
    // 4. MEDICAL HISTORY TIMELINE
    // =========================================================================
    if (_shouldRunSection('history')) {
      await nav.go('${AppRoutes.home}/$pid', extra: ctx.primaryProfile);
      await nav.tapBottomNav(2);
      await nav.capture(
        '13_history_timeline',
        flow: '4. Medical History',
        description: 'Medical History timeline with search bar, category filter chips, and clinical event cards',
        annotate: _kAnnotate,
      );

      await nav.go(
        '${AppRoutes.historyDetail}/$pid',
        extra: ctx.historyEvents.first,
      );
      await nav.capture(
        '14_history_event_detail',
        flow: '4. Medical History',
        description: 'History Event Detail editor with event type, clinical notes, provider, facility, and attachments',
        annotate: _kAnnotate,
      );

      await nav.go(
        AppRoutes.historyReadonlyDetail,
        extra: ctx.historyEvents.first,
      );
      await nav.capture(
        '15_history_event_readonly',
        flow: '4. Medical History',
        description: 'Read-only clinical event detail view',
        annotate: _kAnnotate,
      );
    }

    // =========================================================================
    // 5. PREVENTIVE CHECKUPS
    // =========================================================================
    if (_shouldRunSection('checkups')) {
      await nav.go('${AppRoutes.checkups}/$pid');
      await nav.capture(
        '16_checkups_screen',
        flow: '5. Checkups',
        description: 'Medical Checkups screen showing active, due/overdue, and deactivated checkup schedules',
        annotate: _kAnnotate,
      );
    }

    // =========================================================================
    // 6. PERIOD & CYCLE TRACKER
    // =========================================================================
    if (_shouldRunSection('period')) {
      await nav.go('${AppRoutes.periodTracker}/${ctx.femaleProfile.id}');
      await nav.capture(
        '17_period_tracker_calendar',
        flow: '6. Period Tracker',
        description: 'Period & Cycle Tracker calendar showing logged flow days and fertile window predictions',
        annotate: _kAnnotate,
      );

      await nav.scrollDown(dy: 420);
      await nav.capture(
        '18_period_tracker_symptoms',
        flow: '6. Period Tracker',
        description: 'Period Tracker scrolled to flow intensity, mood chips, physical symptoms, and cycle history',
        annotate: _kAnnotate,
      );
    }

    // =========================================================================
    // 7. PROFILES, SHARING & EXPORT
    // =========================================================================
    if (_shouldRunSection('profile') || _shouldRunSection('profiles')) {
      await nav.go('${AppRoutes.home}/$pid', extra: ctx.primaryProfile);
      await nav.tapBottomNav(3);
      await nav.capture(
        '19_profile_detail_top',
        flow: '7. Profiles & Sharing',
        description: 'Profile Detail screen top: avatar, demographics, blood type, and organ donor toggle',
        annotate: _kAnnotate,
      );

      await nav.scrollDown(dy: 450);
      await nav.capture(
        '20_profile_detail_scrolled',
        flow: '7. Profiles & Sharing',
        description: 'Profile Detail screen scrolled: chronic conditions, allergies, and insurance policy card',
        annotate: _kAnnotate,
      );

      await nav.go(AppRoutes.profiles);
      await nav.capture(
        '21_profiles_list',
        flow: '7. Profiles & Sharing',
        description: 'Profiles list screen showing family profiles and Shared With Me section',
        annotate: _kAnnotate,
      );

      await nav.go(AppRoutes.archivedProfiles);
      await nav.capture(
        '22_archived_profiles',
        flow: '7. Profiles & Sharing',
        description: 'Archived Profiles management screen',
        annotate: _kAnnotate,
      );

      await nav.go(AppRoutes.shareProfile, extra: ctx.primaryProfile);
      await nav.capture(
        '23_share_profile_qr',
        flow: '7. Profiles & Sharing',
        description: 'Share Profile screen with E2E encrypted QR code, share link, and sync controls',
        annotate: _kAnnotate,
      );

      await nav.go(AppRoutes.exportProfile, extra: ctx.primaryProfile);
      await nav.capture(
        '24_export_profile',
        flow: '7. Profiles & Sharing',
        description: 'Export Profile screen with PDF Medical Summary and Encrypted Archive options',
        annotate: _kAnnotate,
      );

      await nav.go(AppRoutes.importProfile);
      await nav.capture(
        '25_import_profile',
        flow: '7. Profiles & Sharing',
        description: 'Import Profile screen for restoring encrypted `.och` profile archives',
        annotate: _kAnnotate,
      );
    }

    // =========================================================================
    // 8. EMERGENCY MEDICAL ID & SETTINGS
    // =========================================================================
    if (_shouldRunSection('emergency') || _shouldRunSection('settings')) {
      await nav.go('${AppRoutes.emergencySettings}/$pid');
      await nav.capture(
        '26_emergency_settings',
        flow: '8. Emergency & Settings',
        description: 'Emergency Medical ID settings with ICE contacts and lock-screen field toggles',
        annotate: _kAnnotate,
      );

      await nav.go(AppRoutes.settings);
      await nav.capture(
        '27_settings_top',
        flow: '8. Emergency & Settings',
        description: 'Settings navigation hub: monotone list of settings items that navigate to dedicated sub-screens',
        annotate: _kAnnotate,
      );

      await nav.tapText('Appearance & Theme');
      await nav.capture(
        '28_settings_appearance',
        flow: '8. Emergency & Settings',
        description: 'Appearance & Theme sub-screen: Theme Mode selector and Color Theme presets',
        annotate: _kAnnotate,
      );

      await nav.tapIcon(Icons.arrow_back);
      await nav.tapText('Google Drive Backup');
      await nav.capture(
        '28b_settings_cloud_backup',
        flow: '8. Emergency & Settings',
        description: 'Google Drive Backup sub-screen: connected account, storage usage, and auto-backup schedule',
        annotate: _kAnnotate,
      );

      await nav.tapIcon(Icons.arrow_back);
      await nav.tapText('Local Storage & Backup');
      await nav.capture(
        '28c_settings_local_storage',
        flow: '8. Emergency & Settings',
        description: 'Local Storage & Backup sub-screen: database size, attachments, export/import, and reset',
        annotate: _kAnnotate,
      );

      await nav.tapIcon(Icons.arrow_back);
      await nav.tapText('About & Privacy');
      await nav.capture(
        '28d_settings_about',
        flow: '8. Emergency & Settings',
        description: 'About & Privacy sub-screen: Medical Disclaimer and Local-First / Zero-Knowledge Privacy Policy',
        annotate: _kAnnotate,
      );
      await nav.tapIcon(Icons.arrow_back);
    }

    // =========================================================================
    // 9. ONBOARDING, AUTH & PRIVACY LOCK OVERLAY
    // =========================================================================
    if (_shouldRunSection('onboarding')) {
      await nav.go(AppRoutes.welcome);
      await nav.capture(
        '29_welcome_screen',
        flow: '9. Onboarding & Auth',
        description: 'Welcome onboarding screen with Create Profile, Restore Cloud Backup, and QR Import actions',
        annotate: _kAnnotate,
      );

      await nav.go(AppRoutes.securitySetup);
      await nav.capture(
        '30_security_setup',
        flow: '9. Onboarding & Auth',
        description: 'Security Setup screen for biometric lock and E2E encryption onboarding',
        annotate: _kAnnotate,
      );

      await nav.setAppLocked(true);
      await nav.capture(
        '31_app_lock_overlay',
        flow: '9. Onboarding & Auth',
        description: 'Privacy AppLockOverlay with Biometric Unlock, Master PIN, and Emergency Medical ID button',
        annotate: _kAnnotate,
      );
      await nav.setAppLocked(false);
    }

    // =========================================================================
    // 10. THEME PRESETS & DARK MODE VISUAL SHOWCASE
    // =========================================================================
    if (_shouldRunSection('themes')) {
      await nav.go('${AppRoutes.home}/$pid', extra: ctx.primaryProfile);

      await nav.setTheme(
        mode: AppThemeMode.dark,
        preset: AppThemePresets.oceanBlue,
      );
      await nav.capture(
        '33_theme_dark_ocean_blue_home',
        flow: '10. Themes & Dark Mode',
        description: 'Home dashboard in Dark Mode with Ocean Blue preset',
        annotate: _kAnnotate,
      );

      await nav.scrollDown(dy: 620);
      await nav.capture(
        '33b_theme_dark_ocean_blue_home_scrolled',
        flow: '10. Themes & Dark Mode',
        description: 'Home dashboard scrolled in Dark Mode showing themed PRN Medications and Medical Checkups cards',
        annotate: _kAnnotate,
      );
      await nav.scrollUp(dy: 620);

      await nav.setTheme(
        mode: AppThemeMode.light,
        preset: AppThemePresets.emeraldGreen,
      );
      await nav.capture(
        '34_theme_light_emerald_green_home',
        flow: '10. Themes & Dark Mode',
        description: 'Home dashboard in Light Mode with Emerald Green preset',
        annotate: _kAnnotate,
      );

      await nav.setTheme(
        mode: AppThemeMode.dark,
        preset: AppThemePresets.royalPurple,
      );
      await nav.capture(
        '35_theme_dark_royal_purple_home',
        flow: '10. Themes & Dark Mode',
        description: 'Home dashboard in Dark Mode with Royal Purple preset',
        annotate: _kAnnotate,
      );

      await nav.setTheme(
        mode: AppThemeMode.light,
        preset: AppThemePresets.coralSunset,
      );
      await nav.capture(
        '36_theme_light_coral_sunset_home',
        flow: '10. Themes & Dark Mode',
        description: 'Home dashboard in Light Mode with Coral Sunset preset',
        annotate: _kAnnotate,
      );

      await nav.setTheme(
        mode: AppThemeMode.dark,
        preset: AppThemePresets.oceanBlue,
      );
      await nav.tapBottomNav(1);
      await nav.capture(
        '37_theme_dark_medications',
        flow: '10. Themes & Dark Mode',
        description: 'Medication Tracker in Dark Mode',
        annotate: _kAnnotate,
      );

      await nav.go(AppRoutes.settings);
      await nav.capture(
        '38_theme_dark_settings',
        flow: '10. Themes & Dark Mode',
        description: 'Settings navigation hub in Dark Mode',
        annotate: _kAnnotate,
      );

      await nav.tapText('Appearance & Theme');
      await nav.capture(
        '39_theme_dark_settings_appearance',
        flow: '10. Themes & Dark Mode',
        description: 'Appearance & Theme sub-screen in Dark Mode',
        annotate: _kAnnotate,
      );
    }

    await nav.writeVisualAtlas();
    await nav.dispose();
  });
}
