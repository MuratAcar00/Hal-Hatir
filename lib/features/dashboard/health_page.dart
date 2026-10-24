import 'package:flutter/material.dart';

import '../../core/ui/hover_card.dart';
import '../../core/ui/section_card.dart';
import '../family/health_trends.dart';
import '../family/weekly_chart.dart';
import 'medical_summary.dart';

class HealthPage extends StatelessWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        const MedicalSummaryCard(),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            const trends = LiftedCard(child: HealthTrendsCard());
            const weekly = LiftedCard(
              child: SectionCard(
                icon: Icons.show_chart,
                title: 'Haftalık ritim: günün ilk hareketi',
                child: SizedBox(height: 260, child: WeeklyChart()),
              ),
            );
            if (c.maxWidth < 860) {
              return const Column(
                children: [trends, SizedBox(height: 16), weekly],
              );
            }
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: trends),
                SizedBox(width: 16),
                Expanded(child: weekly),
              ],
            );
          },
        ),
      ],
    );
  }
}
