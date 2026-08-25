import 'package:flutter/material.dart';
import 'package:open_cloud_health/models/profile.dart';

enum BmiCategory {
  underweight,
  normal,
  overweight,
  obeseClass1,
  obeseClass2,
  obeseClass3,
}

enum BodyFatCategory {
  essential,
  fitness,
  healthyAverage,
  elevated,
}

class BmiResult {
  const BmiResult({
    required this.bmi,
    required this.category,
    required this.categoryName,
    required this.categoryColor,
  });

  final double bmi;
  final BmiCategory category;
  final String categoryName;
  final Color categoryColor;
}

class BodyFatResult {
  const BodyFatResult({
    required this.percentage,
    required this.category,
    required this.categoryName,
    required this.categoryColor,
    required this.isPediatric,
  });

  final double percentage;
  final BodyFatCategory category;
  final String categoryName;
  final Color categoryColor;
  final bool isPediatric;
}

class HealthyWeightRange {
  const HealthyWeightRange({
    required this.minWeightKg,
    required this.maxWeightKg,
  });

  final double minWeightKg;
  final double maxWeightKg;
}

class BmiCalculator {
  /// Check if a given age falls into pediatric clinical guidelines (< 18 years)
  static bool isPediatric(int? age) => age != null && age < 18;

  /// Calculate BMI from weight in kg and height in cm: BMI = weight / (height_m ^ 2)
  static double calculateBmiValue(double weightKg, double heightCm) {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    final bmi = weightKg / (heightM * heightM);
    return double.parse(bmi.toStringAsFixed(1));
  }

  /// Classify BMI into WHO categories (adults)
  static BmiCategory getCategory(double bmi) {
    if (bmi < 18.5) {
      return BmiCategory.underweight;
    } else if (bmi < 25.0) {
      return BmiCategory.normal;
    } else if (bmi < 30.0) {
      return BmiCategory.overweight;
    } else if (bmi < 35.0) {
      return BmiCategory.obeseClass1;
    } else if (bmi < 40.0) {
      return BmiCategory.obeseClass2;
    } else {
      return BmiCategory.obeseClass3;
    }
  }

  /// Full BMI result object with category, name, and color
  static BmiResult? calculate(double? weightKg, double? heightCm) {
    if (weightKg == null || heightCm == null || weightKg <= 0 || heightCm <= 0) {
      return null;
    }
    final bmi = calculateBmiValue(weightKg, heightCm);
    final category = getCategory(bmi);
    return BmiResult(
      bmi: bmi,
      category: category,
      categoryName: getCategoryName(category),
      categoryColor: getCategoryColor(category),
    );
  }

  static String getCategoryName(BmiCategory category) {
    switch (category) {
      case BmiCategory.underweight:
        return 'Underweight';
      case BmiCategory.normal:
        return 'Normal / Healthy';
      case BmiCategory.overweight:
        return 'Overweight';
      case BmiCategory.obeseClass1:
        return 'Obesity (Class I)';
      case BmiCategory.obeseClass2:
        return 'Obesity (Class II)';
      case BmiCategory.obeseClass3:
        return 'Severe Obesity (Class III)';
    }
  }

  static Color getCategoryColor(BmiCategory category) {
    switch (category) {
      case BmiCategory.underweight:
        return Colors.blue.shade600;
      case BmiCategory.normal:
        return Colors.green.shade600;
      case BmiCategory.overweight:
        return Colors.orange.shade700;
      case BmiCategory.obeseClass1:
        return Colors.deepOrange.shade600;
      case BmiCategory.obeseClass2:
        return Colors.deepOrange.shade800;
      case BmiCategory.obeseClass3:
        return Colors.red.shade800;
    }
  }

  /// Calculate Estimated Body Fat Percentage using the Deurenberg formula:
  /// Adult: BF% = (1.20 * BMI) + (0.23 * Age) - (10.8 * Sex) - 5.4  (Sex: Male=1, Female=0)
  /// Child (<18): BF% = (1.51 * BMI) - (0.70 * Age) - (3.6 * Sex) + 1.4
  static BodyFatResult? calculateBodyFat({
    required double? bmi,
    required int? age,
    required Gender? gender,
  }) {
    if (bmi == null || bmi <= 0 || age == null || age <= 0 || gender == null) {
      return null;
    }

    final isChild = isPediatric(age);
    final sexValue = gender == Gender.male ? 1.0 : 0.0;

    double bf;
    if (isChild) {
      bf = (1.51 * bmi) - (0.70 * age) - (3.6 * sexValue) + 1.4;
    } else {
      bf = (1.20 * bmi) + (0.23 * age) - (10.8 * sexValue) - 5.4;
    }

    final clampedBf = double.parse(bf.clamp(3.0, 65.0).toStringAsFixed(1));
    final category = _classifyBodyFat(clampedBf, gender, isChild);

    return BodyFatResult(
      percentage: clampedBf,
      category: category,
      categoryName: _getBodyFatCategoryName(category),
      categoryColor: _getBodyFatCategoryColor(category),
      isPediatric: isChild,
    );
  }

  static BodyFatCategory _classifyBodyFat(double bf, Gender gender, bool isChild) {
    if (isChild) {
      if (gender == Gender.male) {
        if (bf < 10.0) return BodyFatCategory.essential;
        if (bf <= 20.0) return BodyFatCategory.fitness;
        if (bf <= 25.0) return BodyFatCategory.healthyAverage;
        return BodyFatCategory.elevated;
      } else {
        if (bf < 14.0) return BodyFatCategory.essential;
        if (bf <= 24.0) return BodyFatCategory.fitness;
        if (bf <= 30.0) return BodyFatCategory.healthyAverage;
        return BodyFatCategory.elevated;
      }
    } else {
      // Adult classification
      if (gender == Gender.male) {
        if (bf < 6.0) return BodyFatCategory.essential;
        if (bf < 18.0) return BodyFatCategory.fitness;
        if (bf < 25.0) return BodyFatCategory.healthyAverage;
        return BodyFatCategory.elevated;
      } else {
        if (bf < 14.0) return BodyFatCategory.essential;
        if (bf < 25.0) return BodyFatCategory.fitness;
        if (bf < 32.0) return BodyFatCategory.healthyAverage;
        return BodyFatCategory.elevated;
      }
    }
  }

  static String _getBodyFatCategoryName(BodyFatCategory category) {
    switch (category) {
      case BodyFatCategory.essential:
        return 'Low / Essential Fat';
      case BodyFatCategory.fitness:
        return 'Athletic / Fitness';
      case BodyFatCategory.healthyAverage:
        return 'Healthy Average';
      case BodyFatCategory.elevated:
        return 'Elevated Fat';
    }
  }

  static Color _getBodyFatCategoryColor(BodyFatCategory category) {
    switch (category) {
      case BodyFatCategory.essential:
        return Colors.blue.shade700;
      case BodyFatCategory.fitness:
        return Colors.green.shade700;
      case BodyFatCategory.healthyAverage:
        return Colors.teal.shade700;
      case BodyFatCategory.elevated:
        return Colors.orange.shade800;
    }
  }

  /// Calculates the healthy weight range (BMI 18.5 - 24.9) for a given height in cm
  static HealthyWeightRange? getHealthyWeightRange(double? heightCm) {
    if (heightCm == null || heightCm <= 0) return null;
    final heightM = heightCm / 100.0;
    final minKg = 18.5 * (heightM * heightM);
    final maxKg = 24.9 * (heightM * heightM);
    return HealthyWeightRange(
      minWeightKg: double.parse(minKg.toStringAsFixed(1)),
      maxWeightKg: double.parse(maxKg.toStringAsFixed(1)),
    );
  }

  // Unit Conversions
  static double kgToLbs(double kg) => double.parse((kg * 2.20462).toStringAsFixed(1));
  static double lbsToKg(double lbs) => double.parse((lbs / 2.20462).toStringAsFixed(1));

  static ({int feet, int inches}) cmToFeetInches(double cm) {
    final totalInches = (cm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return (feet: feet, inches: inches);
  }

  static double feetInchesToCm(int feet, int inches) {
    final totalInches = (feet * 12) + inches;
    return double.parse((totalInches * 2.54).toStringAsFixed(1));
  }
}
