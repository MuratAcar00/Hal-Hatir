import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/clock.dart';
import '../../core/models.dart';
import '../../core/ui/app_scaffold.dart';

class HomeSimulatorScreen extends StatelessWidget {
  const HomeSimulatorScreen({super.key});

  static const _eventButtons = [
    (ActivityType.kettle, Icons.coffee_maker, 'Çaydanlığı aç'),
    (ActivityType.door, Icons.door_front_door, 'Kapıyı aç'),
    (ActivityType.motionBedroom, Icons.bed, 'Yatak odası hareketi'),
    (ActivityType.motionKitchen, Icons.kitchen, 'Mutfak hareketi'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = s.now;
    final today = s.eventsOn(now);
    return AppScaffold(
      title: 'Ev simülatörü',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (s.alertState != AlertState.normal) const _CheckInCard(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(dateText(now)),
                  Text(
                    hm(now),
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: [
                      for (final sp in SimClock.speeds)
                        ButtonSegment(value: sp, label: Text('${sp}x')),
                    ],
                    selected: {s.clock.speed},
                    onSelectionChanged: (v) => s.setSpeed(v.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              for (final (type, icon, label) in _eventButtons)
                FilledButton.tonal(
                  onPressed: () => s.addEvent(type),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 36),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.wb_sunny),
                  label: const Text('Bugünü başlat'),
                  onPressed: s.startToday,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.fast_forward),
                  label: const Text('Sabah rutinini atla'),
                  onPressed: s.skipMorning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Bugünkü olaylar',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (today.isEmpty) const Text('Henüz olay yok.'),
          for (final e in today.reversed)
            ListTile(
              dense: true,
              leading: Text(hm(e.time)),
              title: Text(e.type.label),
            ),
        ],
      ),
    );
  }
}

/// The gentle "İyi misiniz?" question with one big button.
class _CheckInCard extends StatelessWidget {
  const _CheckInCard();

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final familyNotified = s.alertState != AlertState.softCheck;
    return Card(
      color: Colors.orange.shade100,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'İyi misiniz?',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 110,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                ),
                onPressed: s.acknowledge,
                child: const Text('İyiyim', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              familyNotified
                  ? 'Ailenize haber verildi. "İyiyim" derseniz rahatlarlar.'
                  : 'Cevap gelmezse 15 dakika sonra ailenize haber verilecek.',
            ),
          ],
        ),
      ),
    );
  }
}
