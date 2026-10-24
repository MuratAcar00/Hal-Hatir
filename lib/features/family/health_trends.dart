import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/section_card.dart';

/// "Sağlık Trendleri (Beta)": static, simulated insight for the demo.
class HealthTrendsCard extends StatelessWidget {
  const HealthTrendsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: Icons.favorite_outline,
      iconColor: context.sc.attention,
      title: 'Sağlık Trendleri (Beta)',
      color: context.sc.health,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚠️ Dikkat Çeken Değişim: Son 2 haftada gece (02:00-05:00) banyo '
            'hareket sensörü tetiklenmesi haftada 1\'den 4\'e çıktı. '
            '(İdrar yolu enfeksiyonu veya uyku bozukluğu riski olabilir. '
            'Doktorunuza danışmanız önerilir.)',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: BarChart(
              BarChartData(
                maxY: 5,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        v == 0 ? '2 hafta önce: 1' : 'Bu hafta: 4',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
                barGroups: [
                  for (final (x, y) in [(0, 1.0), (1, 4.0)])
                    BarChartGroupData(
                      x: x,
                      barRods: [
                        BarChartRodData(
                          toY: y,
                          width: 28,
                          color: x == 0
                              ? context.sc.attention.withValues(alpha: 0.5)
                              : context.sc.attention,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Simüle edilmiş örnek veridir. Tıbbi tanı değildir.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
