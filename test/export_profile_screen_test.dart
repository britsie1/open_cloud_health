import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/screens/export_profile.dart';
import 'package:open_cloud_health/services/file_service.dart';

class MockProfilesRepository extends Mock implements ProfilesRepository {}
class MockFileService extends Mock implements FileService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockProfilesRepository mockProfilesRepository;
  late MockFileService mockFileService;

  final testProfile = Profile(
    id: 'prof-test-123',
    name: 'Eleanor',
    middleNames: 'Grace',
    surname: 'Vance',
    dateOfBirth: DateTime(1992, 4, 15),
    gender: Gender.female,
    bloodType: 'O+',
    isOrganDonor: true,
  );

  setUp(() {
    mockProfilesRepository = MockProfilesRepository();
    mockFileService = MockFileService();

    when(() => mockProfilesRepository.watchProfiles())
        .thenAnswer((_) => const Stream.empty());
    when(() => mockProfilesRepository.fetchProfiles(includeArchived: any(named: 'includeArchived')))
        .thenAnswer((_) async => [testProfile]);
    when(() => mockFileService.getProfileImagePath(any()))
        .thenAnswer((_) async => '');
    when(() => mockFileService.localPath)
        .thenAnswer((_) async => '');
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        profilesRepositoryProvider.overrideWithValue(mockProfilesRepository),
        fileServiceProvider.overrideWithValue(mockFileService),
      ],
      child: MaterialApp(
        home: ExportProfileScreen(profile: testProfile),
      ),
    );
  }

  testWidgets('ExportProfileScreen displays profile summary and export options', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Export Profile'), findsOneWidget);
    expect(find.text('Eleanor Vance'), findsOneWidget);
    expect(find.textContaining('Blood Type: O+'), findsOneWidget);
    expect(find.text('Choose Export Format'), findsOneWidget);
    expect(find.text('Medical Practitioner PDF'), findsOneWidget);
    expect(find.text('Export as JSON Backup Data'), findsOneWidget);
    expect(find.text('Data Privacy Guaranteed'), findsOneWidget);
  });

  testWidgets('Tapping Medical Practitioner PDF opens customize options sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap PDF export card
    await tester.tap(find.text('Medical Practitioner PDF'));
    await tester.pumpAndSettle();

    expect(find.text('Customize Medical Summary'), findsOneWidget);
    expect(find.text('Timeframe Filter'), findsOneWidget);
    expect(find.text('All Records'), findsOneWidget);
    expect(find.text('Patient Demographics & Photo'), findsOneWidget);
    expect(find.text('Allergies & Adverse Reactions'), findsOneWidget);
    expect(find.text('Active Chronic Conditions'), findsOneWidget);
    expect(find.text('Medications & Schedules'), findsOneWidget);
    expect(find.text('Vital Signs & Biometrics'), findsOneWidget);
    expect(find.text('Medical History & Encounters'), findsOneWidget);
    expect(find.text('Preventive Health & Checkups'), findsOneWidget);
    expect(find.text('Menstrual & Reproductive Health'), findsOneWidget);
    expect(find.text('Doctor Notes & Signature Section'), findsOneWidget);
    expect(find.text('Preview & Print'), findsOneWidget);
    expect(find.text('Share PDF'), findsOneWidget);

    // Close the sheet
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Customize Medical Summary'), findsNothing);
  });

  testWidgets('Tapping JSON export opens explanatory dialog', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap JSON export card
    await tester.tap(find.text('Export as JSON Backup Data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('JSON Profile Export'), findsOneWidget);
    expect(find.text('Understood'), findsOneWidget);

    await tester.tap(find.text('Understood'));
    await tester.pumpAndSettle();

    expect(find.text('JSON Profile Export'), findsNothing);
  });
}
