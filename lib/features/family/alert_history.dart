import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';

String levelLabel(AlertState s) => switch (s) {
  AlertState.normal => 'Normal',
  AlertState.softCheck => 'Yakınınıza soruldu',
  AlertState.familyAlert => 'Aileye uyarı',
  AlertState.secondContactAlert => 'İkinci kişiye uyarı',
};

/// In-app notification banner while the family is being alerted.
class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.alertState != AlertState.familyAlert &&
        s.alertState != AlertState.secondContactAlert) {
      return const SizedBox.shrink();
    }
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.notifications_active),
        title: const Text('Bildirim: yakınınız cevap vermedi'),
        subtitle: Text('Neden uyardı? ${s.engine.explanation ?? ''}'),
      ),
    );
  }
}

class WeeklySummary extends StatelessWidget {
  const WeeklySummary({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final since = dayOf(s.now).subtract(const Duration(days: 6));
    final week = s.engine.history.where((h) => !h.start.isBefore(since));
    final family = week.where((h) => h.maxLevel.index >= 2).length;
    final falseAlarms = week.where((h) => h.falseAlarm).length;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.summarize),
        title: const Text('Haftalık özet (son 7 gün)'),
        subtitle: Text(
          '${week.length} kontrol sorusu, $family aile uyarısı, '
          '$falseAlarms yanlış alarm',
        ),
      ),
    );
  }
}

class AlertHistoryList extends StatelessWidget {
  const AlertHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final items = s.engine.history.reversed.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Uyarı geçmişi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (items.isEmpty) const ListTile(title: Text('Henüz uyarı yok.')),
            for (final h in items)
              ListTile(
                isThreeLine: true,
                leading: Icon(
                  h.falseAlarm ? Icons.thumb_down_alt : Icons.warning_amber,
                  color: h.falseAlarm ? Colors.grey : Colors.orange,
                ),
                title: Text(
                  '${dateText(h.start)} ${hm(h.start)} · ${levelLabel(h.maxLevel)}',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Neden uyardı? ${h.explanation}'),
                    Text(
                      h.resolvedAt == null
                          ? 'Devam ediyor'
                          : 'Kapandı: ${hm(h.resolvedAt!)}',
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: h.falseAlarm
                          ? const Chip(
                              label: Text('Yanlış alarm olarak işaretlendi'),
                            )
                          : TextButton(
                              onPressed: () => s.markFalseAlarm(h),
                              child: const Text('Bu uyarı yanlış alarmdı'),
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
