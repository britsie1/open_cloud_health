import 'package:flutter/material.dart';
import 'package:open_cloud_health/widgets/weight/set_goal_dialog.dart';

class WeightGoalCard extends StatelessWidget {
  const WeightGoalCard({
    super.key,
    required this.profileId,
    required this.targetWeightKg,
    required this.currentWeightKg,
    required this.startWeightKg,
  });

  final String profileId;
  final double? targetWeightKg;
  final double? currentWeightKg;
  final double? startWeightKg;

  void _openGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SetGoalDialog(
        profileId: profileId,
        initialTargetKg: targetWeightKg,
        currentWeightKg: currentWeightKg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGoal = targetWeightKg != null && targetWeightKg! > 0;

    final target = targetWeightKg ?? 0.0;
    final current = currentWeightKg ?? target;
    final start = startWeightKg ?? current;

    final totalDiff = (target - start).abs();
    final remaining = (target - current).abs();
    final isLosing = target < start;
    final isGaining = target > start;
    final isGoalReached = hasGoal &&
        ((isLosing && current <= target) ||
            (isGaining && current >= target) ||
            (current == target));

    double progress = 0.0;
    if (isGoalReached) {
      progress = 1.0;
    } else if (totalDiff > 0) {
      final achieved = isLosing ? (start - current) : (current - start);
      progress = (achieved / totalDiff).clamp(0.0, 1.0);
    }

    String statusText;
    if (isGoalReached) {
      statusText = 'Goal reached!';
    } else if (isLosing) {
      statusText = '${remaining.toStringAsFixed(1)} kg left to lose';
    } else {
      statusText = '${remaining.toStringAsFixed(1)} kg left to gain';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.flag_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Goal Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (hasGoal)
              Semantics(
                label: 'Edit goal weight, currently ${target.toStringAsFixed(1)} kg',
                button: true,
                child: TextButton.icon(
                  onPressed: () => _openGoalDialog(context),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text('${target.toStringAsFixed(1)} kg'),
                ),
              )
            else
              Semantics(
                label: 'Set target goal weight',
                button: true,
                child: TextButton(
                  onPressed: () => _openGoalDialog(context),
                  child: const Text('Set Goal'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (!hasGoal) ...[
          Text(
            'Set a target weight goal to track progress.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% completed',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isGoalReached ? Colors.teal.shade700 : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isGoalReached ? Colors.teal.shade600 : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Start / Current / Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start: ${start.toStringAsFixed(1)} kg',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                'Current: ${current.toStringAsFixed(1)} kg',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                'Target: ${target.toStringAsFixed(1)} kg',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
