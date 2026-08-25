import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/utils/bmi_calculator.dart';

enum ChartTimeframe {
  sevenDays('7D', Duration(days: 7)),
  oneMonth('1M', Duration(days: 30)),
  threeMonths('3M', Duration(days: 90)),
  sixMonths('6M', Duration(days: 180)),
  oneYear('1Y', Duration(days: 365)),
  all('All', null);

  const ChartTimeframe(this.label, this.duration);
  final String label;
  final Duration? duration;
}

class WeightChartWidget extends StatefulWidget {
  const WeightChartWidget({
    super.key,
    required this.logs,
    required this.unit,
    this.heightCm,
    this.targetWeightKg,
    this.onOpenAddLog,
  });

  final List<VitalLog> logs;
  final String unit;
  final double? heightCm;
  final double? targetWeightKg;
  final VoidCallback? onOpenAddLog;

  @override
  State<WeightChartWidget> createState() => _WeightChartWidgetState();
}

class _WeightChartWidgetState extends State<WeightChartWidget> {
  ChartTimeframe _selectedTimeframe = ChartTimeframe.oneMonth;

  ({DateTime startDate, DateTime endDate, List<VitalLog> logs}) _getTimeframeData() {
    if (widget.logs.isEmpty) {
      final now = DateTime.now();
      return (startDate: now.subtract(const Duration(days: 30)), endDate: now, logs: <VitalLog>[]);
    }

    final sorted = List<VitalLog>.from(widget.logs)..sort((a, b) => a.date.compareTo(b.date));
    final now = DateTime.now();
    final endDate = now;

    DateTime startDate;
    List<VitalLog> filtered;

    if (_selectedTimeframe.duration != null) {
      startDate = now.subtract(_selectedTimeframe.duration!);
      filtered = sorted.where((l) => !l.date.isBefore(startDate) && !l.date.isAfter(endDate)).toList();
    } else {
      // All timeframe
      startDate = sorted.first.date;
      filtered = sorted;
    }

    return (startDate: startDate, endDate: endDate, logs: filtered);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeframeData = _getTimeframeData();
    final filteredLogs = timeframeData.logs;
    final startDate = timeframeData.startDate;
    final endDate = timeframeData.endDate;

    final healthyRange = BmiCalculator.getHealthyWeightRange(widget.heightCm);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeframe Selector Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ChartTimeframe.values.map((tf) {
                  final isSelected = tf == _selectedTimeframe;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(tf.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTimeframe = tf;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          if (filteredLogs.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No weigh-ins in the last ${_selectedTimeframe.label}.',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Switch to "All" or tap below to record a new weight.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.onOpenAddLog != null) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: widget.onOpenAddLog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Log Weight Now'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else ...[
            // Quick KPI Summary Row
            _buildKpiRow(filteredLogs, theme),

            const SizedBox(height: 16),

            // Chart Container
            Container(
              height: 280,
              padding: const EdgeInsets.only(right: 24, left: 12, top: 16, bottom: 8),
              child: _buildLineChart(
                filteredLogs,
                startDate,
                endDate,
                healthyRange,
                theme,
              ),
            ),

            // Legend / Reference indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _LegendItem(color: theme.colorScheme.primary, label: 'Weight Trend'),
                  if (healthyRange != null)
                    _LegendItem(
                      color: Colors.green.shade300.withOpacity(0.5),
                      label:
                          'Healthy BMI Range (${healthyRange.minWeightKg.toStringAsFixed(0)}-${healthyRange.maxWeightKg.toStringAsFixed(0)} kg)',
                      isBox: true,
                    ),
                  if (widget.targetWeightKg != null)
                    _LegendItem(
                      color: Colors.deepOrange,
                      label: 'Goal (${widget.targetWeightKg!.toStringAsFixed(1)} kg)',
                      isDashed: true,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiRow(List<VitalLog> logs, ThemeData theme) {
    final firstWeight = logs.first.value1;
    final latestWeight = logs.last.value1;
    final diff = latestWeight - firstWeight;
    final minWeight = logs.map((l) => l.value1).reduce((a, b) => a < b ? a : b);
    final maxWeight = logs.map((l) => l.value1).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          _StatTile(
            label: 'Current',
            value: '${latestWeight.toStringAsFixed(1)} ${widget.unit}',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          _StatTile(
            label: 'Change (${_selectedTimeframe.label})',
            value: '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} ${widget.unit}',
            color: diff == 0
                ? Colors.grey.shade700
                : (diff < 0 ? Colors.green.shade700 : Colors.orange.shade800),
          ),
          const SizedBox(width: 8),
          _StatTile(
            label: 'Min / Max',
            value: '${minWeight.toStringAsFixed(0)} / ${maxWeight.toStringAsFixed(0)}',
            color: Colors.grey.shade800,
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(
    List<VitalLog> logs,
    DateTime startDate,
    DateTime endDate,
    HealthyWeightRange? healthyRange,
    ThemeData theme,
  ) {
    final totalSpanDays = endDate.difference(startDate).inHours / 24.0;
    final maxX = totalSpanDays < 1.0 ? 1.0 : totalSpanDays;
    const minX = 0.0;

    final spots = <FlSpot>[];
    double minY = logs.first.value1;
    double maxY = logs.first.value1;

    for (var log in logs) {
      final daysFromStart = log.date.difference(startDate).inHours / 24.0;
      final xVal = daysFromStart.clamp(minX, maxX);
      spots.add(FlSpot(xVal, log.value1));

      if (log.value1 < minY) minY = log.value1;
      if (log.value1 > maxY) maxY = log.value1;
    }

    // Factor in healthy range or goal to Y axis limits if present
    if (widget.targetWeightKg != null) {
      if (widget.targetWeightKg! < minY) minY = widget.targetWeightKg!;
      if (widget.targetWeightKg! > maxY) maxY = widget.targetWeightKg!;
    }
    if (healthyRange != null) {
      if (healthyRange.minWeightKg < minY && (minY - healthyRange.minWeightKg) < 15) {
        minY = healthyRange.minWeightKg;
      }
      if (healthyRange.maxWeightKg > maxY && (healthyRange.maxWeightKg - maxY) < 15) {
        maxY = healthyRange.maxWeightKg;
      }
    }

    final yPadding = ((maxY - minY) * 0.15).clamp(2.0, 10.0);
    final finalMinY = (minY - yPadding).clamp(0.0, double.infinity);
    final finalMaxY = maxY + yPadding;

    // Determine bottom label interval based on timeframe
    double xInterval;
    switch (_selectedTimeframe) {
      case ChartTimeframe.sevenDays:
        xInterval = 1.0;
        break;
      case ChartTimeframe.oneMonth:
        xInterval = 5.0;
        break;
      case ChartTimeframe.threeMonths:
        xInterval = 15.0;
        break;
      case ChartTimeframe.sixMonths:
        xInterval = 30.0;
        break;
      case ChartTimeframe.oneYear:
        xInterval = 60.0;
        break;
      case ChartTimeframe.all:
        xInterval = (maxX / 5.0).clamp(1.0, 365.0);
        break;
    }

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: finalMinY,
        maxY: finalMaxY == finalMinY ? finalMaxY + 5 : finalMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (finalMaxY - finalMinY) > 20 ? 5 : 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                return Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: xInterval,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > maxX) return const SizedBox.shrink();
                final date = startDate.add(Duration(hours: (value * 24).toInt()));
                final format = _selectedTimeframe == ChartTimeframe.sevenDays ||
                        _selectedTimeframe == ChartTimeframe.oneMonth
                    ? DateFormat('M/d')
                    : DateFormat('MMM');
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    format.format(date),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            left: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                final log = idx < logs.length ? logs[idx] : null;
                final dateStr = log != null ? DateFormat('MMM d, y').format(log.date) : '';

                String extra = '';
                if (idx > 0) {
                  final prev = logs[idx - 1].value1;
                  final delta = spot.y - prev;
                  extra = ' (${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)})';
                }

                String bmiStr = '';
                if (widget.heightCm != null && widget.heightCm! > 0) {
                  final bmi = BmiCalculator.calculateBmiValue(spot.y, widget.heightCm!);
                  bmiStr = '\nBMI: $bmi';
                }

                return LineTooltipItem(
                  '$dateStr\n${spot.y.toStringAsFixed(1)} ${widget.unit}$extra$bmiStr',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (widget.targetWeightKg != null)
              HorizontalLine(
                y: widget.targetWeightKg!,
                color: Colors.deepOrange,
                strokeWidth: 2,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 6, bottom: 2),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                  ),
                  labelResolver: (line) =>
                      'Goal: ${widget.targetWeightKg!.toStringAsFixed(1)}',
                ),
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 2,
            curveSmoothness: 0.25,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length <= 30,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3.5,
                color: Colors.white,
                strokeWidth: 2.5,
                strokeColor: theme.colorScheme.primary,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.35),
                  theme.colorScheme.primary.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.isBox = false,
    this.isDashed = false,
  });

  final Color color;
  final String label;
  final bool isBox;
  final bool isDashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBox)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else if (isDashed)
          Container(
            width: 14,
            height: 2,
            color: color,
          )
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
