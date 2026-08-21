import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/widgets/allergy_list_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AllergyListSection & ManageAllergiesBottomSheet Tests', () {
    test('commonAllergens list contains standard medical and food allergens', () {
      expect(commonAllergens.length, greaterThanOrEqualTo(15));
      expect(commonAllergens.any((a) => a.name == 'Penicillin'), isTrue);
      expect(commonAllergens.any((a) => a.name == 'Sulfa Drugs'), isTrue);
      expect(commonAllergens.any((a) => a.name == 'NSAIDs / Aspirin'), isTrue);
      expect(commonAllergens.any((a) => a.name == 'Peanuts'), isTrue);
      expect(commonAllergens.any((a) => a.name == 'Tree Nuts'), isTrue);
      expect(commonAllergens.any((a) => a.name == 'Latex'), isTrue);
      expect(commonAllergens.any((a) => a.name == 'Pollen (Hay Fever)'), isTrue);
    });

    test('getAllergenInfo returns matched info or fallback for custom allergy', () {
      final penicillinInfo = getAllergenInfo('Penicillin');
      expect(penicillinInfo.name, 'Penicillin');
      expect(penicillinInfo.color, Colors.red);

      final customInfo = getAllergenInfo('Other: Strawberries');
      expect(customInfo.name, 'Strawberries');

      final unknownInfo = getAllergenInfo('Kiwi Fruit');
      expect(unknownInfo.name, 'Kiwi Fruit');
    });

    testWidgets('renders empty state when no allergies are present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllergyListSection(
              profileId: 'test-p1',
              allergies: const [],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Allergies'), findsOneWidget);
      expect(find.text('No allergies added. Tap to select.'), findsOneWidget);
    });

    testWidgets('renders chips with icons, labels, and notes when allergies are provided', (tester) async {
      final allergies = [
        Allergy(id: 'a1', profileId: 'test-p1', name: 'Penicillin', note: 'Hives'),
        Allergy(id: 'a2', profileId: 'test-p1', name: 'Peanuts', note: 'Anaphylaxis'),
        Allergy(id: 'a3', profileId: 'test-p1', name: 'Strawberries', note: ''),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllergyListSection(
              profileId: 'test-p1',
              allergies: allergies,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Allergies'), findsOneWidget);
      expect(find.text('Penicillin (Hives)'), findsOneWidget);
      expect(find.text('Peanuts (Anaphylaxis)'), findsOneWidget);
      expect(find.text('Strawberries'), findsOneWidget);
    });

    testWidgets('tapping add button opens ManageAllergiesBottomSheet and allows selection and note entry', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      List<Allergy> updatedAllergies = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllergyListSection(
              profileId: 'test-p1',
              allergies: const [],
              onChanged: (newList) {
                updatedAllergies = newList;
              },
            ),
          ),
        ),
      );

      // Tap + button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Allergies & Sensitivities'), findsOneWidget);
      expect(find.text('Penicillin'), findsOneWidget);
      expect(find.text('Peanuts'), findsOneWidget);

      // Select Penicillin
      await tester.tap(find.text('Penicillin'));
      await tester.pumpAndSettle();

      // Enter reaction note for Penicillin
      final noteField = find.byType(TextFormField);
      expect(noteField, findsWidgets);
      await tester.enterText(noteField.first, 'Severe hives and rash');
      await tester.pumpAndSettle();

      // Drag down to reach Other Allergy
      await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -800));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Other Allergy'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Enter custom allergy name and note
      final customNameField = find.widgetWithText(TextField, 'Specify Allergy Name');
      expect(customNameField, findsOneWidget);
      await tester.enterText(customNameField, 'Kiwi Fruit');
      await tester.pumpAndSettle();

      final customNoteField = find.widgetWithText(TextField, 'Reaction / Notes (optional)').last;
      expect(customNoteField, findsOneWidget);
      await tester.enterText(customNoteField, 'Lip swelling');
      await tester.pumpAndSettle();

      // Tap Save Allergies
      await tester.tap(find.text('Save Allergies'));
      await tester.pumpAndSettle();

      expect(updatedAllergies.length, 2);
      expect(updatedAllergies.any((a) => a.name == 'Penicillin' && a.note == 'Severe hives and rash'), isTrue);
      expect(updatedAllergies.any((a) => a.name == 'Kiwi Fruit' && a.note == 'Lip swelling'), isTrue);
    });

    testWidgets('read-only mode disables adding allergies', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllergyListSection(
              profileId: 'test-p1',
              allergies: const [],
              onChanged: (_) {},
              isReadOnly: true,
            ),
          ),
        ),
      );

      final iconBtn = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconBtn.onPressed, isNull);
    });
  });
}