import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/ui/app_scaffold.dart';
import 'alert_history.dart';
import 'settings_screen.dart';
import 'weekly_chart.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final last = s.lastEvent;
    return AppScaffold(
      title: 'Aile uygulaması',
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Ayarlar',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        children: [
          const AlertBanner(),
          const _StatusCard(),
          if (s.alertState == AlertState.normal &&
              s.lastAckAt != null &&
              sameDay(s.lastAckAt!, s.now))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                "Yakınınız ${hm(s.lastAckAt!)}'de iyi olduğunu bildirdi",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Son hareket'),
              subtitle: Text(
                last == null
                    ? 'Kayıt yok'
                    : '${sameDay(last.time, s.now) ? 'Bugün' : dateText(last.time)} '
                          '${hm(last.time)} · ${last.type.label}',
              ),
            ),
          ),
          const _ExpectedVsActual(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Haftalık ritim: günün ilk hareketi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 200, child: WeeklyChart()),
                ],
              ),
            ),
          ),
          const WeeklySummary(),
          const AlertHistoryList(),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final (color, title, detail) = switch (s.alertState) {
      AlertState.normal => (
        Colors.green,
        'Bugün normal',
        s.settings.paused
            ? 'Ziyaretçi / tatil modu açık: uyarılar duraklatıldı.'
            : s.settings.isMonitoring(s.now)
            ? 'Rutin beklendiği gibi.'
            : 'İzleme saatleri dışında, yeni uyarı gönderilmez.',
      ),
      AlertState.softCheck => (
        Colors.orange,
        'Dikkat',
        'Beklenen bir hareket olmadı. Yakınınıza "İyi misiniz?" diye soruldu.',
      ),
      AlertState.familyAlert => (
        Colors.red,
        'Uyarı',
        'Yakınınız 15 dakikadır cevap vermedi. Lütfen arayın.',
      ),
      AlertState.secondContactAlert => (
        Colors.red.shade900,
        'Uyarı',
        'Hâlâ cevap yok. ${s.settings.secondContactName.isEmpty ? 'İkinci kişiye' : '${s.settings.secondContactName} adlı kişiye'} de haber verildi.',
      ),
    };
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            if (s.engine.explanation != null) ...[
              const SizedBox(height: 8),
              Text(
                'Neden uyardı? ${s.engine.explanation}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpectedVsActual extends StatelessWidget {
  const _ExpectedVsActual();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = s.now;
    final today = s.eventsOn(now);
    final expected = s.rhythm.forDay(now);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Bugün beklenen / gerçekleşen (${isWeekend(now) ? 'hafta sonu' : 'hafta içi'})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (expected.isEmpty)
              const ListTile(title: Text('Henüz yeterli geçmiş veri yok.')),
            for (final exp in expected)
              Builder(
                builder: (_) {
                  final first = today
                      .where((e) => e.type == exp.type)
                      .firstOrNull;
                  final late =
                      first == null && !now.isBefore(exp.deadlineOn(now));
                  // Missed but answered with "İyiyim": neutral, not red.
                  final confirmed =
                      late &&
                      s.lastAckAt != null &&
                      sameDay(s.lastAckAt!, now) &&
                      s.engine.handled.contains(
                        '${dayKey(now)}|${exp.type.id}',
                      );
                  return ListTile(
                    leading: Icon(
                      first != null
                          ? Icons.check_circle
                          : confirmed
                          ? Icons.check_circle_outline
                          : late
                          ? Icons.error
                          : Icons.hourglass_empty,
                      color: first != null
                          ? Colors.green
                          : confirmed
                          ? Colors.blueGrey
                          : late
                          ? Colors.red
                          : Colors.grey,
                    ),
                    title: Text(exp.type.label),
                    subtitle: Text('Beklenen ${exp.windowText}'),
                    trailing: Text(
                      first != null
                          ? hm(first.time)
                          : confirmed
                          ? 'Atlandı, onaylandı'
                          : late
                          ? 'Olmadı'
                          : 'Bekleniyor',
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
