import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/alert_engine.dart';
import '../../core/app_state.dart';
import '../../core/clock.dart';
import '../../core/medical.dart';
import '../../core/models.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_scaffold.dart';
import '../../core/ui/hover_card.dart';
import 'memory_game.dart';

class HomeSimulatorScreen extends StatelessWidget {
  const HomeSimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const AppScaffold(title: 'Ev simülatörü', body: HomeSimulatorBody());
}

/// Simulator controls; also reused in the web dashboard side panel.
class HomeSimulatorBody extends StatelessWidget {
  const HomeSimulatorBody({super.key});

  static const _eventButtons = [
    (ActivityType.kettle, Icons.coffee_maker, 'Çaydanlığı aç'),
    (ActivityType.door, Icons.door_front_door, 'Kapıyı aç'),
    (ActivityType.motionBedroom, Icons.bed, 'Yatak odası hareketi'),
    (ActivityType.motionKitchen, Icons.kitchen, 'Mutfak hareketi'),
    (ActivityType.bathroomDoor, Icons.wc, 'Banyo Kapısı'),
    (ActivityType.fridge, Icons.kitchen_outlined, 'Buzdolabı Kapağı'),
    (ActivityType.couch, Icons.weekend_outlined, 'Koltuk/TV Sensörü'),
    (ActivityType.medicine, Icons.medical_services_outlined, 'İlaç Kutusu'),
  ];

  static const _medicalButtons = [
    (
      MedicalKind.bloodPressure,
      Icons.monitor_heart,
      'Tansiyonu Ölç',
      'Tansiyon ölçümü kaydedildi',
    ),
    (
      MedicalKind.glucose,
      Icons.water_drop,
      'Kan Şekerini Ölç',
      'Kan şekeri ölçümü kaydedildi',
    ),
    (
      MedicalKind.memoryGame,
      Icons.psychology,
      'Hafıza Oyununu Oyna',
      'Hafıza oyunu tamamlandı',
    ),
  ];

  Widget _grid(List<Widget> children) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.9,
    children: children,
  );

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onPressed,
  ) => HoverLift(
    radius: 14,
    shadow: false,
    child: FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: context.sc.primary.withValues(alpha: 0.08),
        foregroundColor: context.sc.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: context.sc.primary.withValues(alpha: 0.25)),
        ),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = s.now;
    final today = s.eventsOn(now);
    return ListView(
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
            _StatusChip(
              color: context.sc.offline,
              icon: Icons.power_off,
              text: 'Merkez cihaz çevrimdışı: sensör olayları alınmıyor',
            ),
          if (s.engine.isGuestDay)
            _StatusChip(
              color: context.sc.guest,
              icon: Icons.groups,
              text: 'Çoklu Kişi Algılandı: bugün uyarılar susturuldu',
            ),
          if (s.engine.inactivity != Inactivity.none)
            _StatusChip(
              color: context.sc.offline,
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
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: context.sc.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    expandedInsets: EdgeInsets.zero,
                    style: ButtonStyle(
                      side: WidgetStatePropertyAll(
                        BorderSide(
                          color: AppColors.border(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (st) => st.contains(WidgetState.selected)
                            ? context.sc.primary.withValues(alpha: 0.18)
                            : Colors.transparent,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (st) => st.contains(WidgetState.selected)
                            ? context.sc.primary
                            : context.sc.muted,
                      ),
                      textStyle: const WidgetStatePropertyAll(
                        TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    segments: [
                      for (final sp in SimClock.speeds)
                        ButtonSegment(value: sp, label: Text('${sp}x')),
                    ],
                    selected: {s.clock.speed},
                    onSelectionChanged: (v) => s.setSpeed(v.first),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Simülasyon hızı',
                    style: TextStyle(fontSize: 11, color: context.sc.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sensörler',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: context.sc.muted,
            ),
          ),
          const SizedBox(height: 8),
          _grid([
            for (final (type, icon, label) in _eventButtons)
              _tile(
                context,
                icon,
                label,
                s.deviceOffline ? null : () => s.addEvent(type),
              ),
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Text(
            'Tıbbi ve Bilişsel Aktiviteler',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: context.sc.muted,
            ),
          ),
          const SizedBox(height: 8),
          _grid([
            for (final (kind, icon, label, done) in _medicalButtons)
              _tile(
                context,
                icon,
                label,
                s.deviceOffline
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        int? score;
                        if (kind == MedicalKind.memoryGame) {
                          score = await showDialog<int>(
                            context: context,
                            builder: (_) => const MemoryGameDialog(),
                          );
                          if (score == null) return; // closed unfinished
                        }
                        s.addMedical(kind, score: score);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              score == null
                                  ? '$done (simüle)'
                                  : '$done: skor %$score',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
              ),
          ]),
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
      color: context.sc.attention.withValues(alpha: 0.18),
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.sc.attention, width: 3),
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
                    backgroundColor: context.sc.normal,
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
                  backgroundColor: context.sc.normal,
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
