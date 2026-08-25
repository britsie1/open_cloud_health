import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/utils/bmi_calculator.dart';

void main() {
  group('BmiCalculator Tests', () {
    test('calculateBmiValue calculates correct BMI for standard values', () {
      // 70kg, 175cm -> 70 / (1.75 * 1.75) = 22.857... -> 22.9
      final bmi = BmiCalculator.calculateBmiValue(70, 175);
      expect(bmi, 22.9);
    });

    test('calculateBmiValue handles edge cases', () {
      expect(BmiCalculator.calculateBmiValue(0, 175), 0.0);
      expect(BmiCalculator.calculateBmiValue(70, 0), 0.0);
      expect(BmiCalculator.calculateBmiValue(-10, 175), 0.0);
    });

    test('getCategory assigns correct WHO classifications', () {
      expect(BmiCalculator.getCategory(16.0), BmiCategory.underweight);
      expect(BmiCalculator.getCategory(18.4), BmiCategory.underweight);
      expect(BmiCalculator.getCategory(18.5), BmiCategory.normal);
      expect(BmiCalculator.getCategory(22.0), BmiCategory.normal);
      expect(BmiCalculator.getCategory(24.9), BmiCategory.normal);
      expect(BmiCalculator.getCategory(25.0), BmiCategory.overweight);
      expect(BmiCalculator.getCategory(29.9), BmiCategory.overweight);
      expect(BmiCalculator.getCategory(30.0), BmiCategory.obeseClass1);
      expect(BmiCalculator.getCategory(34.9), BmiCategory.obeseClass1);
      expect(BmiCalculator.getCategory(35.0), BmiCategory.obeseClass2);
      expect(BmiCalculator.getCategory(39.9), BmiCategory.obeseClass2);
      expect(BmiCalculator.getCategory(40.0), BmiCategory.obeseClass3);
      expect(BmiCalculator.getCategory(45.0), BmiCategory.obeseClass3);
    });

    test('getHealthyWeightRange computes range correctly for 180cm', () {
      final range = BmiCalculator.getHealthyWeightRange(180);
      expect(range, isNotNull);
      expect(range!.minWeightKg, 59.9);
      expect(range.maxWeightKg, 80.7);
    });

    test('isPediatric correctly identifies minors under 18', () {
      expect(BmiCalculator.isPediatric(10), isTrue);
      expect(BmiCalculator.isPediatric(17), isTrue);
      expect(BmiCalculator.isPediatric(18), isFalse);
      expect(BmiCalculator.isPediatric(35), isFalse);
      expect(BmiCalculator.isPediatric(null), isFalse);
    });

    test('calculateBodyFat computes accurate Deurenberg formula for adult male and female', () {
      // Adult Male (age 30, BMI 23.0)
      // BF% = (1.20 * 23.0) + (0.23 * 30) - (10.8 * 1) - 5.4 = 27.6 + 6.9 - 10.8 - 5.4 = 18.3%
      final maleResult = BmiCalculator.calculateBodyFat(
        bmi: 23.0,
        age: 30,
        gender: Gender.male,
      );
      expect(maleResult, isNotNull);
      expect(maleResult!.percentage, 18.3);
      expect(maleResult.isPediatric, isFalse);
      expect(maleResult.category, BodyFatCategory.healthyAverage);

      // Adult Female (age 30, BMI 23.0)
      // BF% = (1.20 * 23.0) + (0.23 * 30) - (10.8 * 0) - 5.4 = 27.6 + 6.9 - 5.4 = 29.1%
      final femaleResult = BmiCalculator.calculateBodyFat(
        bmi: 23.0,
        age: 30,
        gender: Gender.female,
      );
      expect(femaleResult, isNotNull);
      expect(femaleResult!.percentage, 29.1);
      expect(femaleResult.isPediatric, isFalse);
      expect(femaleResult.category, BodyFatCategory.healthyAverage);
    });

    test('calculateBodyFat computes child Deurenberg formula for youth (< 18)', () {
      // Child Male (age 14, BMI 20.0)
      // BF% = (1.51 * 20.0) - (0.70 * 14) - (3.6 * 1) + 1.4 = 30.2 - 9.8 - 3.6 + 1.4 = 18.2%
      final childResult = BmiCalculator.calculateBodyFat(
        bmi: 20.0,
        age: 14,
        gender: Gender.male,
      );
      expect(childResult, isNotNull);
      expect(childResult!.percentage, 18.2);
      expect(childResult.isPediatric, isTrue);
    });

    test('Unit conversions for kg/lbs and cm/ft-in work accurately', () {
      expect(BmiCalculator.kgToLbs(70), 154.3);
      expect(BmiCalculator.lbsToKg(154.3), 70.0);

      // 175 cm -> 68.89 inches -> 5 ft 9 in
      final ftIn = BmiCalculator.cmToFeetInches(175);
      expect(ftIn.feet, 5);
      expect(ftIn.inches, 9);

      // 5 ft 9 in -> 69 inches * 2.54 = 175.26 -> 175.3 cm
      final cm = BmiCalculator.feetInchesToCm(5, 9);
      expect(cm, 175.3);
    });
  });
}
