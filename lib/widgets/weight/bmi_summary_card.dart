import 'package:flutter/material.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/utils/bmi_calculator.dart';
import 'package:open_cloud_health/widgets/weight/set_height_dialog.dart';

class BmiSummaryCard extends StatelessWidget {
  const BmiSummaryCard({
    super.key,
    required this.profileId,
    required this.currentWeightKg,
    required this.heightCm,
    this.age,
    this.gender,
  });

  final String profileId;
  final double? currentWeightKg;
  final double? heightCm;
  final int? age;
  final Gender? gender;

  void _openHeightDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SetHeightDialog(
        profileId: profileId,
        initialHeightCm: heightCm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHeightSet = heightCm != null && heightCm! > 0;
    final bmiResult = isHeightSet && currentWeightKg != null
        ? BmiCalculator.calculate(currentWeightKg, heightCm)
        : null;
    final healthyRange = isHeightSet
        ? BmiCalculator.getHealthyWeightRange(heightCm)
        : null;
    final isChild = BmiCalculator.isPediatric(age);

    final bodyFatResult = bmiResult != null && age != null && gender != null
        ? BmiCalculator.calculateBodyFat(
            bmi: bmiResult.bmi,
            age: age,
            gender: gender,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.accessibility_new_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Body Mass Index (BMI)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (isHeightSet)
              Semantics(
                label: 'Edit height, currently ${heightCm!.toStringAsFixed(0)} cm',
                button: true,
                child: TextButton.icon(
                  onPressed: () => _openHeightDialog(context),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text('${heightCm!.toStringAsFixed(0)} cm'),
                ),
              )
            else
              Semantics(
                label: 'Set height for BMI',
                button: true,
                child: TextButton(
                  onPressed: () => _openHeightDialog(context),
                  child: const Text('Set Height'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (!isHeightSet) ...[
          Text(
            'Set your height to calculate your BMI and healthy range.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ] else if (bmiResult != null) ...[
          // Main BMI Value + Category Badge + Youth tag
          Row(
            children: [
              Text(
                bmiResult.bmi.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              _MutedBadge(
                label: bmiResult.categoryName,
                color: _getMutedCategoryColor(bmiResult.category),
              ),
              if (isChild) ...[
                const SizedBox(width: 6),
                _MutedBadge(
                  label: 'Youth (Age $age)',
                  color: Colors.blueGrey,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Minimal Gauge Bar
          _MinimalBmiBar(currentBmi: bmiResult.bmi),
          const SizedBox(height: 10),

          // Secondary Details (Healthy Range & Body Fat %)
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              if (healthyRange != null)
                Text(
                  'Healthy range: ${healthyRange.minWeightKg.toStringAsFixed(1)}–${healthyRange.maxWeightKg.toStringAsFixed(1)} kg',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              if (bodyFatResult != null)
                Text(
                  'Est. Body Fat: ${bodyFatResult.percentage}% (${bodyFatResult.categoryName})',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
            ],
          ),
        ] else ...[
          Text(
            'No weight logged yet.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  Color _getMutedCategoryColor(BmiCategory category) {
    switch (category) {
      case BmiCategory.underweight:
        return Colors.blue.shade700;
      case BmiCategory.normal:
        return Colors.teal.shade700;
      case BmiCategory.overweight:
        return Colors.amber.shade800;
      case BmiCategory.obeseClass1:
      case BmiCategory.obeseClass2:
      case BmiCategory.obeseClass3:
        return Colors.deepOrange.shade700;
    }
  }
}

class _MutedBadge extends StatelessWidget {
  const _MutedBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MinimalBmiBar extends StatelessWidget {
  const _MinimalBmiBar({required this.currentBmi});

  final double currentBmi;

  @override
  Widget build(BuildContext context) {
    final clamped = currentBmi.clamp(15.0, 38.0);
    final fraction = (clamped - 15.0) / (38.0 - 15.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final indicatorX = (fraction * totalWidth).clamp(4.0, totalWidth - 4.0);

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 5,
                child: Row(
                  children: [
                    Expanded(flex: 35, child: Container(color: Colors.blue.shade200)),
                    const SizedBox(width: 1),
                    Expanded(flex: 65, child: Container(color: Colors.teal.shade300)),
                    const SizedBox(width: 1),
                    Expanded(flex: 50, child: Container(color: Colors.amber.shade300)),
                    const SizedBox(width: 1),
                    Expanded(flex: 80, child: Container(color: Colors.deepOrange.shade300)),
                  ],
                ),
              ),
            ),
            Positioned(
              left: indicatorX - 3,
              child: Container(
                width: 6,
                height: 9,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
