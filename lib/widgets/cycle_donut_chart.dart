import 'dart:math';
import 'package:flutter/material.dart';
import 'package:open_cloud_health/providers/period_provider.dart';

class CycleDonutChart extends StatelessWidget {
  const CycleDonutChart({super.key, required this.periodState});

  final PeriodState periodState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If no active cycle, show an empty state
    if (periodState.currentCycle == null) {
      return Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 15),
        ),
        child: const Center(
          child: Text(
            'No Active Cycle',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      );
    }

    return SizedBox(
      width: 250,
      height: 250,
      child: CustomPaint(
        painter: _CycleDonutPainter(
          currentDay: periodState.currentDayOfCycle,
          totalDays: periodState.averageCycleLength,
          ovulationDay: periodState.predictedOvulationDay,
          primaryColor: theme.colorScheme.primary,
          secondaryColor: theme.colorScheme.secondary,
          surfaceColor: theme.colorScheme.surfaceVariant,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Day',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              Text(
                '${periodState.currentDayOfCycle}',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                'of ${periodState.averageCycleLength}',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CycleDonutPainter extends CustomPainter {
  final int currentDay;
  final int totalDays;
  final int ovulationDay;
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;

  _CycleDonutPainter({
    required this.currentDay,
    required this.totalDays,
    required this.ovulationDay,
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;
    const strokeWidth = 20.0;

    final backgroundPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw background track
    canvas.drawCircle(center, radius, backgroundPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Calculate angles (start from top, which is -pi/2)
    const startAngle = -pi / 2;
    const totalSweep = 2 * pi;

    // Draw Menstruation Phase (typically days 1-5)
    final periodSweep = (5 / totalDays) * totalSweep;
    final periodPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, periodSweep, false, periodPaint);

    // Draw Ovulation Window (e.g., predicted day -2 to predicted day +2)
    final ovulationStartDay = (ovulationDay - 2).clamp(1, totalDays);
    final ovulationStartAngle = startAngle + ((ovulationStartDay - 1) / totalDays) * totalSweep;
    final ovulationSweep = (5 / totalDays) * totalSweep;
    
    final ovulationPaint = Paint()
      ..color = secondaryColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, ovulationStartAngle, ovulationSweep, false, ovulationPaint);

    // Draw Current Day Indicator
    final currentDayAngle = startAngle + ((currentDay - 1) / totalDays) * totalSweep;
    final indicatorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final indicatorBorderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final indicatorX = center.dx + radius * cos(currentDayAngle);
    final indicatorY = center.dy + radius * sin(currentDayAngle);
    
    canvas.drawCircle(Offset(indicatorX, indicatorY), strokeWidth / 2 + 4, indicatorPaint);
    canvas.drawCircle(Offset(indicatorX, indicatorY), strokeWidth / 2 + 4, indicatorBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _CycleDonutPainter oldDelegate) {
    return oldDelegate.currentDay != currentDay ||
           oldDelegate.totalDays != totalDays ||
           oldDelegate.ovulationDay != ovulationDay;
  }
}
