import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/utils/standard_checkups.dart';

void main() {
  Profile createTestProfile({
    required int age,
    required Gender gender,
    List<String> chronicConditions = const [],
  }) {
    final now = DateTime.now();
    final dob = DateTime(now.year - age, now.month, now.day);
    return Profile(
      id: 'p-test',
      name: 'Test',
      middleNames: '',
      surname: 'User',
      dateOfBirth: dob,
      gender: gender,
      bloodType: 'O+',
      isOrganDonor: true,
      chronicConditions: chronicConditions,
    );
  }

  group('StandardCheckupTemplate & standardCheckups List Tests', () {
    test('standardCheckups collection contains all defined checkup templates', () {
      expect(standardCheckups.length, greaterThanOrEqualTo(20));
      for (final template in standardCheckups) {
        expect(template.name, isNotEmpty);
        expect(template.frequencyInMonths, greaterThan(0));
        expect(template.iconName, isNotEmpty);
      }
    });

    test('Universal checkups apply to all profiles regardless of age or gender', () {
      final infant = createTestProfile(age: 2, gender: Gender.female);
      final adult = createTestProfile(age: 30, gender: Gender.male);
      final senior = createTestProfile(age: 75, gender: Gender.female);

      final annualPhysical = standardCheckups.firstWhere((c) => c.name == 'Annual Physical Exam');
      final dental = standardCheckups.firstWhere((c) => c.name == 'Dental Exam & Cleaning');

      expect(annualPhysical.appliesTo(infant), isTrue);
      expect(annualPhysical.appliesTo(adult), isTrue);
      expect(annualPhysical.appliesTo(senior), isTrue);
      expect(annualPhysical.getFrequency(adult), 12);

      expect(dental.appliesTo(infant), isTrue);
      expect(dental.appliesTo(adult), isTrue);
      expect(dental.appliesTo(senior), isTrue);
      expect(dental.getFrequency(adult), 6);
    });

    test('Blood pressure screening applies to adults and chronic heart conditions with custom frequency', () {
      final child = createTestProfile(age: 15, gender: Gender.male);
      final healthyAdult = createTestProfile(age: 25, gender: Gender.female);
      final hypertensiveChild = createTestProfile(
        age: 12,
        gender: Gender.male,
        chronicConditions: ['Hypertension'],
      );
      final cadAdult = createTestProfile(
        age: 55,
        gender: Gender.male,
        chronicConditions: ['Coronary Artery Disease'],
      );

      final bp = standardCheckups.firstWhere((c) => c.name == 'Blood Pressure Screening');

      expect(bp.appliesTo(child), isFalse);
      expect(bp.appliesTo(healthyAdult), isTrue);
      expect(bp.getFrequency(healthyAdult), 12);

      // Condition overrides
      expect(bp.appliesTo(hypertensiveChild), isTrue);
      expect(bp.getFrequency(hypertensiveChild), 3); // 3-month frequency for hypertension

      expect(bp.appliesTo(cadAdult), isTrue);
      expect(bp.getFrequency(cadAdult), 6); // 6-month frequency for CAD
    });

    test('Cholesterol screening applies to adults >=20 and high-risk conditions with custom frequency', () {
      final teen = createTestProfile(age: 18, gender: Gender.female);
      final adult = createTestProfile(age: 22, gender: Gender.male);
      final teenWithHypercholesterolemia = createTestProfile(
        age: 17,
        gender: Gender.male,
        chronicConditions: ['Hypercholesterolemia'],
      );
      final adultWithPcos = createTestProfile(
        age: 25,
        gender: Gender.female,
        chronicConditions: ['Polycystic Ovary Syndrome (PCOS)'],
      );

      final cholesterol = standardCheckups.firstWhere((c) => c.name == 'Cholesterol Screening');

      expect(cholesterol.appliesTo(teen), isFalse);
      expect(cholesterol.appliesTo(adult), isTrue);
      expect(cholesterol.getFrequency(adult), 60); // Standard 5 years

      expect(cholesterol.appliesTo(teenWithHypercholesterolemia), isTrue);
      expect(cholesterol.getFrequency(teenWithHypercholesterolemia), 12); // High risk: 1 year

      expect(cholesterol.appliesTo(adultWithPcos), isTrue);
      expect(cholesterol.getFrequency(adultWithPcos), 12);
    });

    test('Diabetes screening applies to adults >=35 or diabetic / PCOS conditions', () {
      final youngAdult = createTestProfile(age: 30, gender: Gender.female);
      final olderAdult = createTestProfile(age: 40, gender: Gender.male);
      final youngDiabetic = createTestProfile(
        age: 20,
        gender: Gender.male,
        chronicConditions: ['Diabetes'],
      );
      final youngPcos = createTestProfile(
        age: 24,
        gender: Gender.female,
        chronicConditions: ['Polycystic Ovary Syndrome (PCOS)'],
      );

      final diabetes = standardCheckups.firstWhere((c) => c.name == 'Diabetes Screening');

      expect(diabetes.appliesTo(youngAdult), isFalse);
      expect(diabetes.appliesTo(olderAdult), isTrue);
      expect(diabetes.getFrequency(olderAdult), 36);

      expect(diabetes.appliesTo(youngDiabetic), isTrue);
      expect(diabetes.getFrequency(youngDiabetic), 6);

      expect(diabetes.appliesTo(youngPcos), isTrue);
      expect(diabetes.getFrequency(youngPcos), 12);
    });

    test('Eye and hearing exams vary by age brackets', () {
      final adult = createTestProfile(age: 40, gender: Gender.female);
      final senior = createTestProfile(age: 70, gender: Gender.female);

      final compEye = standardCheckups.firstWhere((c) => c.name == 'Comprehensive Eye Exam');
      final seniorEye = standardCheckups.firstWhere((c) => c.name == 'Senior Eye Exam');
      final hearing = standardCheckups.firstWhere((c) => c.name == 'Hearing Test');

      expect(compEye.appliesTo(adult), isTrue);
      expect(compEye.appliesTo(senior), isFalse);

      expect(seniorEye.appliesTo(adult), isFalse);
      expect(seniorEye.appliesTo(senior), isTrue);

      expect(hearing.appliesTo(adult), isFalse);
      expect(hearing.appliesTo(senior), isTrue);
    });

    test('Gender-specific cancer screenings correctly check age and gender constraints', () {
      final youngFemale = createTestProfile(age: 19, gender: Gender.female);
      final eligibleFemale = createTestProfile(age: 35, gender: Gender.female);
      final olderFemale = createTestProfile(age: 68, gender: Gender.female);
      final maleSameAge = createTestProfile(age: 35, gender: Gender.male);

      final papSmear = standardCheckups.firstWhere((c) => c.name.contains('Pap Smear'));
      expect(papSmear.appliesTo(youngFemale), isFalse); // < 21
      expect(papSmear.appliesTo(eligibleFemale), isTrue); // 21-65
      expect(papSmear.appliesTo(olderFemale), isFalse); // > 65
      expect(papSmear.appliesTo(maleSameAge), isFalse); // male

      final mammogram = standardCheckups.firstWhere((c) => c.name.contains('Mammogram'));
      expect(mammogram.appliesTo(createTestProfile(age: 38, gender: Gender.female)), isFalse);
      expect(mammogram.appliesTo(createTestProfile(age: 45, gender: Gender.female)), isTrue);
      expect(mammogram.appliesTo(createTestProfile(age: 45, gender: Gender.male)), isFalse);

      final prostate = standardCheckups.firstWhere((c) => c.name.contains('Prostate'));
      expect(prostate.appliesTo(createTestProfile(age: 45, gender: Gender.male)), isFalse);
      expect(prostate.appliesTo(createTestProfile(age: 55, gender: Gender.male)), isTrue);
      expect(prostate.appliesTo(createTestProfile(age: 55, gender: Gender.female)), isFalse);
    });

    test('Bone density (DEXA) scan applies to senior females, senior males, or osteoporosis diagnosis', () {
      final female60 = createTestProfile(age: 60, gender: Gender.female);
      final female65 = createTestProfile(age: 65, gender: Gender.female);
      final male65 = createTestProfile(age: 65, gender: Gender.male);
      final male70 = createTestProfile(age: 70, gender: Gender.male);
      final youngWithOsteo = createTestProfile(
        age: 30,
        gender: Gender.male,
        chronicConditions: ['Osteoporosis'],
      );

      final dexa = standardCheckups.firstWhere((c) => c.name.contains('Bone Density'));

      expect(dexa.appliesTo(female60), isFalse);
      expect(dexa.appliesTo(female65), isTrue);
      expect(dexa.getFrequency(female65), 24);

      expect(dexa.appliesTo(male65), isFalse);
      expect(dexa.appliesTo(male70), isTrue);
      expect(dexa.getFrequency(male70), 24);

      expect(dexa.appliesTo(youngWithOsteo), isTrue);
      expect(dexa.getFrequency(youngWithOsteo), 12); // Higher frequency for active osteoporosis
    });

    test('Chronic condition-specific checkups activate only when corresponding disease is present', () {
      final diabetic = createTestProfile(
        age: 30,
        gender: Gender.male,
        chronicConditions: ['Diabetes'],
      );
      final asthmatic = createTestProfile(
        age: 30,
        gender: Gender.female,
        chronicConditions: ['Asthma'],
      );
      final ckdPatient = createTestProfile(
        age: 50,
        gender: Gender.male,
        chronicConditions: ['Chronic Kidney Disease'],
      );
      final depressedPatient = createTestProfile(
        age: 28,
        gender: Gender.female,
        chronicConditions: ['Depression'],
      );

      final footExam = standardCheckups.firstWhere((c) => c.name == 'Diabetic Foot Exam');
      final asthmaReview = standardCheckups.firstWhere((c) => c.name == 'Asthma/COPD Review');
      final ckdReview = standardCheckups.firstWhere((c) => c.name.contains('Kidney Function'));
      final mentalHealth = standardCheckups.firstWhere((c) => c.name == 'Mental Health Wellness Check');

      expect(footExam.appliesTo(diabetic), isTrue);
      expect(footExam.appliesTo(asthmatic), isFalse);

      expect(asthmaReview.appliesTo(asthmatic), isTrue);
      expect(asthmaReview.appliesTo(diabetic), isFalse);

      expect(ckdReview.appliesTo(ckdPatient), isTrue);
      expect(ckdReview.appliesTo(asthmatic), isFalse);

      expect(mentalHealth.appliesTo(depressedPatient), isTrue);
      expect(mentalHealth.appliesTo(diabetic), isFalse);
    });
  });
}
