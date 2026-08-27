import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/insurance_policy.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/emergency_provider.dart';
import 'package:open_cloud_health/widgets/emergency_card_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('EmergencyCardView renders full emergency profile card with insurance, allergies, meds, and contacts', (tester) async {
    final sampleProfile = Profile(
      id: 'p1',
      name: 'John',
      middleNames: 'William',
      surname: 'Doe',
      dateOfBirth: DateTime(1985, 5, 20),
      gender: Gender.male,
      bloodType: 'O+',
      isOrganDonor: true,
      chronicConditions: const ['Asthma', 'Hypertension'],
    );

    final sampleSettings = LockScreenSetting(
      profileId: 'p1',
      showName: true,
      showAge: true,
      showBloodType: true,
      showOrganDonor: true,
      showChronicConditions: true,
      showAllergies: true,
      showMedications: true,
      showContacts: true,
      showInsurance: true,
      isEnabled: true,
    );

    final sampleInsurance = InsurancePolicy(
      profileId: 'p1',
      provider: 'Discovery Health',
      planName: 'Executive PPO',
      policyNumber: 'DH-99887766',
      groupNumber: 'GRP-1002',
      subscriberName: 'John Doe',
      memberId: '01',
      emergencyPhone: '+1-800-555-0199',
      notes: 'Covers emergency triage',
    );

    final mockResults = [
      {
        'settings': sampleSettings,
        'profile': sampleProfile,
        'allergies': [
          Allergy(id: 'a1', profileId: 'p1', name: 'Penicillin', note: 'Severe shock'),
        ],
        'medications': [
          Medication(
            id: 'm1',
            profileId: 'p1',
            name: 'Albuterol Inhaler',
            dosage: '90mcg 2 puffs',
            type: 'Inhaler',
            isActive: true,
          ),
        ],
        'contacts': [
          EmergencyContact(id: 'c1', profileId: 'p1', name: 'Jane Doe', relationship: 'Spouse', phoneNumber: '+1-555-123-4567'),
        ],
        'insurance': sampleInsurance,
        'imagePath': '',
        'isPrimary': true,
      }
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emergencyProfilesDetailsProvider.overrideWith((ref) => Future.value(mockResults)),
        ],
        child: const MaterialApp(
          home: EmergencyCardView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('EMERGENCY MEDICAL ID'), findsWidgets);
    expect(find.text('John William Doe'), findsOneWidget);
    expect(find.text('BLOOD TYPE: '), findsOneWidget);
    expect(find.text('O+'), findsOneWidget);
    expect(find.text('ORGAN DONOR: '), findsOneWidget);
    expect(find.text('YES'), findsOneWidget);
    expect(find.text('Asthma'), findsOneWidget);
    expect(find.text('Penicillin'), findsOneWidget);
    expect(find.text('Severe shock'), findsOneWidget);
    expect(find.text('Albuterol Inhaler'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Discovery Health'), findsOneWidget);
    expect(find.text('Plan: Executive PPO'), findsOneWidget);
    expect(find.textContaining('DH-99887766'), findsOneWidget);
    expect(find.textContaining('+1-800-555-0199'), findsOneWidget);
  });

  testWidgets('EmergencyCardView renders empty state when no profiles are enabled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emergencyProfilesDetailsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: EmergencyCardView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('No Emergency Medical IDs are enabled'), findsOneWidget);
  });
}
