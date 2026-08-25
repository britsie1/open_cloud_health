import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/period_provider.dart';
import 'package:open_cloud_health/repositories/period_repository.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/screens/period_tracker.dart';

class MockPeriodRepository extends Mock implements PeriodRepository {}
class MockProfilesRepository extends Mock implements ProfilesRepository {}
class FakePeriodCycle extends Fake implements PeriodCycle {}
class FakePeriodLog extends Fake implements PeriodLog {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPeriodRepository mockPeriodRepository;
  late MockProfilesRepository mockProfilesRepository;

  final testProfile = Profile(
    id: 'prof-1',
    name: 'Jane',
    middleNames: '',
    surname: 'Doe',
    dateOfBirth: DateTime(1995, 5, 20),
    gender: Gender.female,
    bloodType: 'O+',
    isOrganDonor: false,
    trackOvulation: true,
  );

  setUpAll(() {
    registerFallbackValue(FakePeriodCycle());
    registerFallbackValue(FakePeriodLog());
  });

  setUp(() {
    mockPeriodRepository = MockPeriodRepository();
    mockProfilesRepository = MockProfilesRepository();

    when(() => mockProfilesRepository.getProfile('prof-1'))
        .thenAnswer((_) async => testProfile);
    when(() => mockPeriodRepository.watchCycles(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPeriodRepository.watchLogsForCycle(any()))
        .thenAnswer((_) => const Stream.empty());
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        periodRepositoryProvider.overrideWithValue(mockPeriodRepository),
        profilesRepositoryProvider.overrideWithValue(mockProfilesRepository),
      ],
      child: const MaterialApp(
        home: PeriodTrackerScreen(profileId: 'prof-1'),
      ),
    );
  }

  testWidgets('PeriodTrackerScreen renders tabs, legend, and prompt when empty', (tester) async {
    when(() => mockPeriodRepository.getCycles('prof-1'))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Period Tracker'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Log'), findsOneWidget);
    expect(find.text('Logged'), findsOneWidget);
    expect(find.text('Fertile'), findsOneWidget);
    expect(find.text('Predicted'), findsOneWidget);
    expect(find.text('Symptoms'), findsOneWidget);
    expect(find.text('Select a day and log your flow to start your first cycle.'), findsOneWidget);
    expect(find.text('I got my period'), findsOneWidget);
  });

  testWidgets('PeriodTrackerScreen renders logged days and fertility across multiple cycles', (tester) async {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 10);
    final lastMonthDate = DateTime(now.year, now.month - 1, 10);

    final currentCycle = PeriodCycle(
      id: 'c-curr',
      profileId: 'prof-1',
      startDate: thisMonthStart,
      endDate: null,
    );
    final historicalCycle = PeriodCycle(
      id: 'c-hist',
      profileId: 'prof-1',
      startDate: lastMonthDate,
      endDate: thisMonthStart.subtract(const Duration(days: 1)),
    );

    final currLogs = [
      PeriodLog(id: 'l-curr1', cycleId: 'c-curr', date: thisMonthStart, flowLevel: FlowLevel.heavy),
      PeriodLog(id: 'l-curr2', cycleId: 'c-curr', date: thisMonthStart.add(const Duration(days: 1)), flowLevel: FlowLevel.medium),
      PeriodLog(id: 'l-curr3', cycleId: 'c-curr', date: thisMonthStart.add(const Duration(days: 2)), flowLevel: FlowLevel.light),
      PeriodLog(id: 'l-curr4', cycleId: 'c-curr', date: thisMonthStart.add(const Duration(days: 12)), physicalSymptoms: [PhysicalSymptom.headache], moods: [Mood.anxious]),
    ];

    final histLogs = [
      PeriodLog(id: 'l-hist1', cycleId: 'c-hist', date: lastMonthDate, flowLevel: FlowLevel.heavy, physicalSymptoms: [PhysicalSymptom.cramps]),
      PeriodLog(id: 'l-hist2', cycleId: 'c-hist', date: lastMonthDate.add(const Duration(days: 1)), flowLevel: FlowLevel.medium),
      PeriodLog(id: 'l-hist3', cycleId: 'c-hist', date: lastMonthDate.add(const Duration(days: 2)), flowLevel: FlowLevel.light),
    ];

    when(() => mockPeriodRepository.getCycles('prof-1'))
        .thenAnswer((_) async => [currentCycle, historicalCycle]);
    when(() => mockPeriodRepository.getLogsForCycle('c-curr'))
        .thenAnswer((_) async => currLogs);
    when(() => mockPeriodRepository.getLogsForCycle('c-hist'))
        .thenAnswer((_) async => histLogs);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify Flow and Symptom buttons render
    expect(find.text('Flow'), findsOneWidget);
    expect(find.text('Physical'), findsOneWidget);
    expect(find.text('Mood'), findsOneWidget);

    // Switch to Log tab
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();

    // In Log tab, should see period cards and symptoms logged cards
    expect(find.text('Period'), findsWidgets);
    expect(find.text('Symptoms Logged'), findsOneWidget);
  });

  testWidgets('PeriodTrackerScreen passes accessibility checks with AccessibilityTools', (tester) async {
    when(() => mockPeriodRepository.getCycles('prof-1'))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          periodRepositoryProvider.overrideWithValue(mockPeriodRepository),
          profilesRepositoryProvider.overrideWithValue(mockProfilesRepository),
        ],
        child: MaterialApp(
          builder: (context, child) => AccessibilityTools(child: child!),
          home: const PeriodTrackerScreen(profileId: 'prof-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  });
}
