import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/medical.dart';
import '../../core/models.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/hover_card.dart';
import 'dashboard_widgets.dart';

/// Share of that day's expected activities that happened. Today counts only
/// expectations whose deadline has passed.
int _routineOn(AppState s, DateTime day) {
  final today = sameDay(day, s.now);
  final expected = s.rhythm
      .forDay(day)
      .where((e) => !today || !s.now.isBefore(e.deadlineOn(day)))
      .toList();
  if (expected.isEmpty) return 100;
  final ev = s.events
      .where((e) => sameDay(e.time, day) && !e.time.isAfter(s.now))
      .toList();
  final done = expected.where((e) => ev.any((x) => x.type == e.type)).length;
  return (done * 100 / expected.length).round();
}

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final sc = context.sc;
    final now = s.now;
    final today = dayOf(now);
    final days = [
      for (var i = 6; i >= 0; i--) DateTime(today.year, today.month, today.day - i),
    ];
    final routine = [for (final d in days) _routineOn(s, d)];
    final avg = (routine.reduce((a, b) => a + b) / routine.length).round();
    final weekEvents = s.events
        .where((e) => !e.time.isBefore(days.first) && !e.time.isAfter(now))
        .length;
    final hist = s.engine.history
        .where((h) => !h.start.isBefore(days.first))
        .toList();
    final family = hist.where((h) => h.maxLevel.index >= 2).length;
    final falseAlarms = hist.where((h) => h.falseAlarm).length;

    bool inWeek(MedicalReading r) =>
        !r.time.isBefore(days.first) && !r.time.isAfter(now);
    int daysWith(MedicalKind k) => days
        .where(
          (d) => s.medical.any(
            (r) => r.kind == k && inWeek(r) && sameDay(r.time, d),
          ),
        )
        .length;
    final bpDays = daysWith(MedicalKind.bloodPressure);
    final glDays = daysWith(MedicalKind.glucose);
    final gameDays = daysWith(MedicalKind.memoryGame);
    final games = s.medical
        .where((r) => r.kind == MedicalKind.memoryGame && inWeek(r))
        .toList();
    final avgScore = games.isEmpty
        ? null
        : (games.map((r) => r.score ?? 85).reduce((a, b) => a + b) /
                  games.length)
              .round();

    String d2(DateTime d) => '${two(d.day)}.${two(d.month)}';
    final highlights = [
      'Rutin uyumu haftalık ortalama %$avg.',
      hist.isEmpty
          ? 'Bu hafta kontrol sorusu veya aile uyarısı oluşmadı.'
          : '${hist.length} kontrol sorusu soruldu, $family tanesi aileye ulaştı.',
      'Tansiyon $bpDays, kan şekeri $glDays gün ölçüldü.'
          '${bpDays < 5 || glDays < 5 ? ' Ölçüm düzenini gözden geçirmek isteyebilirsiniz.' : ''}',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        Text(
          'Son 7 gün: ${d2(days.first)} - ${d2(days.last)}',
          style: TextStyle(fontSize: 15, color: sc.muted),
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 220,
          children: [
            MetricCard(
              icon: Icons.insights,
              label: 'Ortalama rutin uyumu',
              value: '%$avg',
              subtitle: 'Beklenen etkinliklerin gerçekleşme oranı',
              color: avg >= 80 ? sc.normal : sc.attention,
              valueColor: avg >= 80 ? sc.normal : sc.attention,
              progress: avg / 100,
            ),
            MetricCard(
              icon: Icons.sensors,
              label: 'Sensör olayı',
              value: '$weekEvents',
              subtitle: 'Son 7 günde',
              color: sc.primary,
            ),
            MetricCard(
              icon: Icons.notifications_none,
              label: 'Kontrol sorusu',
              value: '${hist.length}',
              subtitle: '$family aile uyarısı · $falseAlarms yanlış alarm',
              color: sc.guest,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 220,
          children: [
            MetricCard(
              icon: Icons.monitor_heart,
              label: 'Tansiyon ölçümü',
              value: '$bpDays/7',
              subtitle: 'gün ölçüm yapıldı',
              color: sc.primary,
            ),
            MetricCard(
              icon: Icons.water_drop,
              label: 'Kan şekeri ölçümü',
              value: '$glDays/7',
              subtitle: 'gün ölçüm yapıldı',
              color: sc.guest,
            ),
            MetricCard(
              icon: Icons.psychology,
              label: 'Hafıza oyunu ortalaması',
              value: avgScore == null ? '—' : '%$avgScore',
              subtitle: '$gameDays/7 gün oynandı',
              color: sc.primary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        DashCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Günlük rutin uyumu (%)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    maxY: 100,
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: sc.muted.withValues(alpha: 0.18),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 25,
                          reservedSize: 34,
                          getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}',
                            style: TextStyle(fontSize: 11, color: sc.muted),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i > 6) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                i == 6
                                    ? 'Bugün'
                                    : weekdayShort[days[i].weekday - 1],
                                style: TextStyle(fontSize: 11, color: sc.muted),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < 7; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: routine[i].toDouble(),
                              width: 22,
                              borderRadius: BorderRadius.circular(6),
                              color: (routine[i] >= 80
                                      ? sc.primary
                                      : sc.attention)
                                  .withValues(alpha: i == 6 ? 0.6 : 1),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DashCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Öne çıkanlar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              for (final h in highlights)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 10),
                        child: Icon(Icons.circle, size: 6, color: sc.primary),
                      ),
                      Expanded(
                        child: Text(h, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Simüle edilmiş veriden hesaplanır. Tıbbi tanı değildir.',
                style: TextStyle(fontSize: 11, color: sc.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
