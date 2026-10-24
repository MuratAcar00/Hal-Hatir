import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/hover_card.dart';
import '../family/alert_history.dart';
import '../family/contact_dialogs.dart';
import '../home_simulator/home_simulator_screen.dart' show personName;
import '../family/family_screen.dart';
import 'activity_rhythm_chart.dart';
import 'dashboard_widgets.dart';
import 'devices.dart';
import 'medical_summary.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = s.now;
    final last = s.lastEvent;
    final score = routineScore(s);
    final scoreColor = score.pct >= 80
        ? context.sc.normal
        : score.pct >= 50
        ? context.sc.attention
        : context.sc.alert;
    final since = dayOf(now).subtract(const Duration(days: 6));
    final weekChecks = s.engine.history
        .where((h) => !h.start.isBefore(since))
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        const AlertBanner(),
        const StatusCard(),
        const SizedBox(height: 4),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.call),
              label: Text("$personName'ı ara"),
              onPressed: () => showCallDialog(
                context,
                name: personName,
                phone: s.settings.familyPhone,
              ),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Mesaj gönder'),
              onPressed: () => showMessageDialog(context),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.contact_phone_outlined),
              label: const Text('İkinci kişiyi ara'),
              onPressed: () => showCallDialog(
                context,
                name: s.settings.secondContactName.isEmpty
                    ? 'İkinci kişi'
                    : s.settings.secondContactName,
                phone: s.settings.secondContactPhone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ResponsiveGrid(
          children: [
            MetricCard(
              icon: Icons.schedule,
              label: 'Son aktiviteden bu yana',
              value: last == null ? '—' : ago(now.difference(last.time)),
              subtitle: last == null
                  ? 'Kayıt yok'
                  : '${last.type.label} · ${timeOrDate(last.time, now)}',
              color: context.sc.primary,
            ),
            MetricCard(
              icon: Icons.insights,
              label: 'Günlük rutin skoru',
              value: '%${score.pct}',
              subtitle: score.due == 0
                  ? 'Vadesi gelen beklenti yok'
                  : '${score.due} beklentiden ${score.done} tanesi gerçekleşti',
              color: scoreColor,
              valueColor: scoreColor,
              progress: score.pct / 100,
            ),
            MetricCard(
              icon: s.deviceOffline ? Icons.power_off : Icons.router,
              label: 'Merkez cihaz',
              value: s.deviceOffline ? 'Çevrimdışı' : 'Çevrimiçi',
              subtitle: s.deviceOffline
                  ? 'Elektrik/internet yok, veri alınamıyor'
                  : 'Tüm sensörler bağlı',
              color: s.deviceOffline ? context.sc.offline : context.sc.normal,
              valueColor: s.deviceOffline
                  ? context.sc.offline
                  : context.sc.normal,
            ),
            MetricCard(
              icon: Icons.sensors,
              label: 'Bugünkü sensör olayı',
              value: '${s.eventsOn(now).length}',
              subtitle: 'Son 7 günde $weekChecks kontrol sorusu',
              color: context.sc.guest,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const MedicalSummaryCard(),
        const SizedBox(height: 16),
        _TwoColumn(
          left: DashCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.show_chart, color: context.sc.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Aktivite Ritmi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const RhythmLegend(),
                const SizedBox(height: 16),
                const SizedBox(height: 260, child: ActivityRhythmChart()),
              ],
            ),
          ),
          right: const DevicesCard(),
        ),
        const SizedBox(height: 16),
        const _TwoColumn(
          left: LiftedCard(child: ExpectedVsActual()),
          right: Column(
            children: [
              LiftedCard(child: WeeklySummary()),
              SizedBox(height: 16),
              LiftedCard(child: AlertHistoryList()),
            ],
          ),
        ),
      ],
    );
  }
}

/// 3:2 row on wide areas, stacked otherwise.
class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 860) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: left),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: right),
          ],
        );
      },
    );
  }
}
