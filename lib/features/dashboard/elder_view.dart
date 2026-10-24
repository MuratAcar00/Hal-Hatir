import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/medical.dart';
import '../../core/models.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/hover_card.dart';
import '../home_simulator/home_simulator_screen.dart';

/// What the elderly person sees on the home tablet: large, calm, few choices.
class ElderView extends StatelessWidget {
  const ElderView({super.key, required this.trailing});

  /// Role menu (and simulator button on narrow screens), top right.
  final Widget trailing;

  static const _actions = [
    (
      MedicalKind.bloodPressure,
      Icons.monitor_heart,
      'Tansiyonumu ölçtüm',
      'Tansiyon ölçümü kaydedildi',
    ),
    (
      MedicalKind.glucose,
      Icons.water_drop,
      'Şekerimi ölçtüm',
      'Kan şekeri ölçümü kaydedildi',
    ),
    (
      MedicalKind.memoryGame,
      Icons.psychology,
      'Hafıza oyunu oynamak istiyorum',
      'Hafıza oyunu tamamlandı',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final sc = context.sc;
    final now = s.now;
    final greeting = now.hour < 12
        ? 'Günaydın'
        : now.hour < 18
        ? 'İyi günler'
        : 'İyi akşamlar';
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
          children: [
            Align(alignment: Alignment.centerRight, child: trailing),
            const SizedBox(height: 8),
            Text(greeting, style: TextStyle(fontSize: 22, color: sc.muted)),
            const Text(
              personName,
              style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              hm(now),
              style: TextStyle(
                fontSize: 84,
                height: 1.05,
                fontWeight: FontWeight.w800,
                color: sc.primary,
              ),
            ),
            Text(dateText(now), style: TextStyle(fontSize: 18, color: sc.muted)),
            const SizedBox(height: 20),
            if (s.alertState != AlertState.normal)
              const CheckInCard()
            else
              DashCard(
                child: Row(
                  children: [
                    Icon(Icons.verified_user, size: 36, color: sc.primary),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Her şey yolunda',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Şu an yapmanız gereken bir şey yok.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (s.familyMessage != null) ...[
              const SizedBox(height: 16),
              DashCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, color: sc.guest),
                        const SizedBox(width: 10),
                        Text(
                          'Ailenizden mesaj',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: sc.muted,
                          ),
                        ),
                        const Spacer(),
                        if (s.familyMessageAt != null)
                          Text(
                            hm(s.familyMessageAt!),
                            style: TextStyle(fontSize: 13, color: sc.muted),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.familyMessage!,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Bugün yapabilecekleriniz',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: sc.muted,
              ),
            ),
            const SizedBox(height: 10),
            for (final (kind, icon, label, done) in _actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 72,
                  child: FilledButton.tonalIcon(
                    icon: Icon(icon, size: 30),
                    label: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: s.deviceOffline
                        ? null
                        : () => runMedicalAction(context, s, kind, done),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
