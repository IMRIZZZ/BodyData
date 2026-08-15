import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/weight_record.dart';

/// Line chart showing up to 7 days of weight history.
class WeightChartWidget extends StatelessWidget {
  final List<WeightRecord> records;
  final bool isMetric;

  const WeightChartWidget({
    super.key,
    required this.records,
    this.isMetric = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (records.isEmpty) {
      return _emptyState(context);
    }

    // Build the x-axis baseline: today and the 6 days before
    final today = DateTime.now();
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 6));

    // Group records by day-offset (0 = 6 days ago, 6 = today),
    // keeping the LAST entry for each day.
    final Map<int, WeightRecord> byDay = {};
    for (final r in records) {
      final d = r.dateTime;
      final dayDate =
          DateTime(d.year, d.month, d.day);
      final offset = dayDate.difference(weekStart).inDays;
      if (offset >= 0 && offset <= 6) {
        byDay[offset] = r; // last wins
      }
    }

    if (byDay.isEmpty) return _emptyState(context);

    // Build spots
    final spots = byDay.entries.map((e) {
      final w = isMetric ? e.value.weightKg : e.value.weightKg / 0.453592;
      return FlSpot(e.key.toDouble(), w);
    }).toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    final weights = spots.map((s) => s.y).toList();
    final minY = (weights.reduce((a, b) => a < b ? a : b) - 5)
        .clamp(0.0, double.infinity);
    final maxY = weights.reduce((a, b) => a > b ? a : b) + 5;

    final unit = isMetric ? 'kg' : 'lbs';
    final primary = cs.primary;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: cs.outlineVariant.withOpacity(0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
        ),
        titlesData: FlTitlesData(
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: 5,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final day = weekStart
                    .add(Duration(days: value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('E').format(day),
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: cs.inverseSurface,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(1)} $unit',
                      TextStyle(
                        color: cs.onInverseSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 2,
            curveSmoothness: 0.3,
            color: primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) =>
                  FlDotCirclePainter(
                radius: 5,
                color: primary,
                strokeWidth: 2,
                strokeColor: cs.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  primary.withOpacity(0.25),
                  primary.withOpacity(0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 40,
              color: cs.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 8),
          Text('No weight data yet.',
              style: TextStyle(color: cs.onSurfaceVariant)),
          Text('Update your weight in Settings to see history.',
              style: TextStyle(
                  color: cs.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 12)),
        ],
      ),
    );
  }
}
