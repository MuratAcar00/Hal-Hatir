import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/rhythm.dart';

/// First activity time of each of the last 7 days (today included).
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = s.now;
    final days = [
      for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i),
    ];
    final spots = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      final ev = s
          .eventsOn(days[i])
          .where((e) => e.time.hour >= Rhythm.dayStartHour)
          .toList();
      if (ev.isNotEmpty) {
        spots.add(FlSpot(i.toDouble(), minuteOfDay(ev.first.time) / 60));
      }
    }
    final color = Theme.of(context).colorScheme.primary;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 5,
        maxY: 11,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (ts) => [
              for (final t in ts)
                LineTooltipItem(
                  minToHm((t.y * 60).round()),
                  const TextStyle(color: Colors.white),
                ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                '${two(v.toInt())}:00',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i > 6) return const SizedBox.shrink();
                return Text(
                  i == 6 ? 'Bugün' : weekdayShort[days[i].weekday - 1],
                  style: const TextStyle(fontSize: 11),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(),
          ),
        ],
      ),
    );
  }
}
