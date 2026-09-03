import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/models/insurance_policy.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/repositories/insurance_repository.dart';
import 'package:open_cloud_health/widgets/chronic_conditions_section.dart';
import 'package:open_cloud_health/widgets/insurance_section.dart';

class MockInsuranceRepository extends Mock implements InsuranceRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockInsuranceRepository mockInsuranceRepository;

  setUp(() {
    mockInsuranceRepository = MockInsuranceRepository();
  });

  group('ChronicConditionsSection & ChronicConditionInfo Widget Tests', () {
    test('commonChronicConditions list contains major clinical categories', () {
      expect(commonChronicConditions.length, greaterThanOrEqualTo(10));
      expect(commonChronicConditions.any((c) => c.name == 'Hypertension'), isTrue);
      expect(commonChronicConditions.any((c) => c.name == 'Diabetes'), isTrue);
      expect(commonChronicConditions.any((c) => c.name == 'Asthma'), isTrue);
      expect(commonChronicConditions.any((c) => c.name == 'COPD'), isTrue);
      expect(commonChronicConditions.any((c) => c.name == 'Chronic Kidney Disease'), isTrue);
      expect(commonChronicConditions.any((c) => c.name == 'Depression'), isTrue);
      expect(commonChronicConditions.any((c) => c.name == 'Arthritis'), isTrue);
    });

    testWidgets('renders empty state when no chronic conditions recorded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChronicConditionsSection(
              profileId: 'p1',
              gender: Gender.female,
              chronicConditions: const [],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Chronic Conditions'), findsOneWidget);
      expect(find.text('No chronic conditions selected. Tap edit to select.'), findsOneWidget);
    });

    testWidgets('renders chips with icons and labels when conditions are present', (tester) async {
      final conditions = ['Hypertension', 'Asthma', 'Other: Custom Condition'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChronicConditionsSection(
              profileId: 'p1',
              gender: Gender.male,
              chronicConditions: conditions,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Chronic Conditions'), findsOneWidget);
      expect(find.text('Hypertension'), findsOneWidget);
      expect(find.text('Asthma'), findsOneWidget);
      expect(find.text('Custom Condition'), findsOneWidget);
    });
  });

  group('InsuranceSection Widget Tests', () {
    testWidgets('renders empty state when no insurance is saved', (tester) async {
      when(() => mockInsuranceRepository.getInsurance('p-test'))
          .thenAnswer((_) async => null);
      when(() => mockInsuranceRepository.watchInsurance('p-test'))
          .thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            insuranceRepositoryProvider.overrideWithValue(mockInsuranceRepository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InsuranceSection(profileId: 'p-test'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Health Insurance & Policy'), findsOneWidget);
      expect(find.text('No Insurance Policy Added'), findsOneWidget);
      expect(find.text('Add Insurance Details'), findsOneWidget);
    });

    testWidgets('renders populated insurance card with provider, policy number, and details', (tester) async {
      final policy = InsurancePolicy(
        id: 'ins-1',
        profileId: 'p-test',
        provider: 'Aetna Health',
        planName: 'Open Choice PPO',
        policyNumber: 'AET-889900',
        groupNumber: 'GRP-777',
        subscriberName: 'Jane Doe',
        memberId: 'MEM-01',
        emergencyPhone: '+1-800-555-0123',
        notes: 'Pre-authorization required for surgery',
      );

      when(() => mockInsuranceRepository.getInsurance('p-test'))
          .thenAnswer((_) async => policy);
      when(() => mockInsuranceRepository.watchInsurance('p-test'))
          .thenAnswer((_) => Stream.value(policy));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            insuranceRepositoryProvider.overrideWithValue(mockInsuranceRepository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InsuranceSection(profileId: 'p-test'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Health Insurance & Policy'), findsOneWidget);
      expect(find.text('Aetna Health'), findsOneWidget);
      expect(find.text('Open Choice PPO'), findsOneWidget);
      expect(find.text('AET-889900'), findsOneWidget);
      expect(find.text('GRP-777'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('+1-800-555-0123'), findsOneWidget);
    });

    testWidgets('read-only mode hides add and edit options', (tester) async {
      when(() => mockInsuranceRepository.getInsurance('p-test'))
          .thenAnswer((_) async => null);
      when(() => mockInsuranceRepository.watchInsurance('p-test'))
          .thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            insuranceRepositoryProvider.overrideWithValue(mockInsuranceRepository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InsuranceSection(
                profileId: 'p-test',
                isReadOnly: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Health Insurance & Policy'), findsOneWidget);
      expect(find.text('No Insurance Policy Added'), findsOneWidget);
      expect(find.text('Add Insurance Details'), findsNothing);
    });
  });
}
