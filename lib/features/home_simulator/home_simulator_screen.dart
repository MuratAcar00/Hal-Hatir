import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/alert_engine.dart';
import '../../core/app_state.dart';
import '../../core/clock.dart';
import '../../core/models.dart';
import '../../core/ui/app_colors.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        children: [
          if (s.demoRunning)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.play_circle),
                title: Text(
                  s.demoLabel!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.stop),
                  tooltip: 'Demoyu durdur',
                  onPressed: s.stopDemo,
                ),
              ),
            ),
          if (s.deviceOffline)
            const _StatusChip(
              color: AppColors.offline,
              icon: Icons.power_off,
              text: 'Merkez cihaz çevrimdışı: sensör olayları alınmıyor',
            ),
          if (s.engine.isGuestDay)
            const _StatusChip(
              color: AppColors.guest,
              icon: Icons.groups,
              text: 'Çoklu Kişi Algılandı: bugün uyarılar susturuldu',
            ),
          if (s.engine.inactivity != Inactivity.none)
            const _StatusChip(
              color: AppColors.offline,
              icon: Icons.luggage,
              text: 'Uzun Süreli Hareketsizlik (Tatil/Hastane)',
            ),
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
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
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
          // Full-width, tall sensor buttons.
          for (final (type, icon, label) in _eventButtons)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                height: 76,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                    foregroundColor: AppColors.primary,
                    overlayColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onPressed: s.deviceOffline ? null : () => s.addEvent(type),
                  child: Row(
                    children: [
                      Icon(icon, size: 34),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(Icons.touch_app_outlined),
                    ],
                  ),
                ),
              ),
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
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: Icon(s.deviceOffline ? Icons.power : Icons.power_off),
            label: Text(
              s.deviceOffline
                  ? 'Elektrik/İnternet Geri Ver'
                  : 'Elektrik/İnternet Kes',
            ),
            onPressed: s.toggleOffline,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.groups),
                  label: const Text('Misafir senaryosu'),
                  onPressed: s.guestScenario,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.hourglass_bottom),
                  label: const Text('48 saat sessizlik'),
                  onPressed: s.silence48Scenario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              icon: Icon(s.demoRunning ? Icons.stop : Icons.play_arrow),
              label: Text(
                s.demoRunning ? 'Demoyu durdur' : 'Demo senaryosunu oynat',
                style: const TextStyle(fontSize: 18),
              ),
              onPressed: s.demoRunning ? s.stopDemo : s.playDemo,
            ),
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

// No person-name setting yet; demo default.
const personName = 'Ayşe Hanım';

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.color,
    required this.icon,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    color: color.withValues(alpha: 0.15),
    child: ListTile(
      leading: Icon(icon, color: color),
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    ),
  );
}

/// The gentle "İyi misiniz?" question with one big button.
class _CheckInCard extends StatefulWidget {
  const _CheckInCard();

  @override
  State<_CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends State<_CheckInCard> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return Card(
      color: AppColors.attention.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (s.alertState == AlertState.softCheck) ...[
              // Asked by the central device speaker, not the phone.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.attention, width: 3),
                ),
                child: const Text(
                  '🔊 Merkez Cihaz Hoparlörü: $personName iyi misiniz?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 90,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.normal,
                  ),
                  icon: const Icon(Icons.radio_button_checked, size: 32),
                  onPressed: s.acknowledge,
                  label: const Text(
                    'Cihazın Üzerindeki Fiziksel Tuşa Bas (İyiyim)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
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
                  backgroundColor: AppColors.normal,
                ),
                onPressed: s.acknowledge,
                child: const Text('İyiyim', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 8),
            Text(switch (s.alertState) {
              AlertState.familyAlert => 'Ailenize haber verildi',
              AlertState.secondContactAlert => 'İkinci kişiye haber verildi',
              _ => 'Cevap gelmezse 15 dakika sonra ailenize haber verilecek',
            }),
          ],
        ),
      ),
    );
  }
}
