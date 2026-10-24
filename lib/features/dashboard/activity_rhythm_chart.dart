import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/ui/app_colors.dart';

/// Smoothed activity intensity over the day: today vs the learned 14-day norm.
class ActivityRhythmChart extends StatelessWidget {
  const ActivityRhythmChart({super.key});

  static const _sigma = 0.75; // hours

  static double _hour(DateTime t) => t.hour + t.minute / 60;

  static double _intensity(Iterable<SensorEvent> events, double x) {
    var sum = 0.0;
    for (final e in events) {
      final d = (x - _hour(e.time)) / _sigma;
      sum += math.exp(-0.5 * d * d);
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = s.now;
    final today = dayOf(now);
    final since = today.subtract(const Duration(days: 14));
    final past = s.events
        .where((e) => e.time.isBefore(today) && !e.time.isBefore(since))
        .toList();
    final pastDays = math.max(1, past.map((e) => dayKey(e.time)).toSet().length);
    final todays = s.eventsOn(now);
    final nowH = _hour(now);

    final typical = <FlSpot>[];
    final current = <FlSpot>[];
    var peak = 1.0;
    for (var i = 0; i <= 48; i++) {
      final x = i / 2;
      final a = _intensity(past, x) / pastDays;
      typical.add(FlSpot(x, a));
      peak = math.max(peak, a);
      if (x <= nowH) {
        final b = _intensity(todays, x);
        current.add(FlSpot(x, b));
        peak = math.max(peak, b);
      }
    }
    if (current.isEmpty || current.last.x < nowH) {
      final b = _intensity(todays, nowH);
      current.add(FlSpot(nowH, b));
      peak = math.max(peak, b);
    }
    final maxY = peak * 1.25;

    final sc = context.sc;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 24,
        minY: 0,
        maxY: maxY,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: sc.muted.withValues(alpha: 0.18),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${two(v.toInt())}:00',
                  style: TextStyle(fontSize: 11, color: sc.muted),
                ),
              ),
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          verticalLines: [
            VerticalLine(
              x: nowH,
              color: sc.primary.withValues(alpha: 0.5),
              strokeWidth: 1.5,
              dashArray: [5, 4],
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final t in spots)
                LineTooltipItem(
                  '${t.barIndex == 0 ? 'Olağan' : 'Bugün'} · '
                  '${minToHm((t.x * 60).round())}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: typical,
            isCurved: true,
            preventCurveOverShooting: true,
            color: sc.muted,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: sc.muted.withValues(alpha: 0.12),
            ),
          ),
          LineChartBarData(
            spots: current,
            isCurved: true,
            preventCurveOverShooting: true,
            color: sc.primary,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  sc.primary.withValues(alpha: 0.35),
                  sc.primary.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RhythmLegend extends StatelessWidget {
  const RhythmLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(t, style: TextStyle(fontSize: 12, color: context.sc.muted)),
      ],
    );
    return Wrap(
      spacing: 16,
      children: [
        item(context.sc.primary, 'Bugün'),
        item(context.sc.muted, 'Son 14 gün ortalaması'),
      ],
    );
  }
}
