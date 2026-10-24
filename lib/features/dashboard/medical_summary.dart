import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/medical.dart';
import '../../core/models.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/hover_card.dart';
import 'dashboard_widgets.dart';

/// "Günlük Medikal Özet": simulated device readings, never a diagnosis.
class MedicalSummaryCard extends StatelessWidget {
  const MedicalSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = s.now;
    final bp = s.lastMedical(MedicalKind.bloodPressure);
    final gl = s.lastMedical(MedicalKind.glucose);
    final game = s.lastMedical(MedicalKind.memoryGame);
    final sc = context.sc;

    bool fresh(MedicalReading? r) =>
        r != null && now.difference(r.time) < const Duration(hours: 48);
    String since(MedicalReading r) {
      final d = now.difference(r.time);
      return d.inMinutes < 1 ? 'şimdi' : '${ago(d)} önce';
    }

    String overdue(MedicalReading r) =>
        'Son ölçüm ${since(r)} - ölçüm gecikti';

    final items = [
      _Vital(
        icon: Icons.monitor_heart,
        color: sc.primary,
        label: 'Kan Basıncı (Tansiyon)',
        value: bp == null ? '—' : '120/80',
        unit: bp == null ? '' : 'mmHg',
        note: bp == null
            ? 'Ölçüm yok'
            : fresh(bp)
            ? 'Son ölçüm ${since(bp)} - Normal'
            : overdue(bp),
        noteColor: bp != null && !fresh(bp) ? sc.attention : null,
      ),
      _Vital(
        icon: Icons.water_drop,
        color: sc.guest,
        label: 'Açlık Kan Şekeri',
        value: gl == null ? '—' : '95',
        unit: gl == null ? '' : 'mg/dL',
        note: gl == null
            ? 'Ölçüm yok'
            : fresh(gl)
            ? '${gl.time.hour < 12 ? 'Sabah ölçümü' : 'Gün içi ölçüm'}'
                  ' - Hedef aralıkta'
            : overdue(gl),
        noteColor: gl != null && !fresh(gl) ? sc.attention : null,
      ),
      _Vital(
        icon: Icons.psychology,
        color: sc.primary,
        label: 'Bilişsel Aktivite Skoru',
        value: game == null ? '—' : '%${game.score ?? 85}',
        unit: '',
        note: game == null
            ? 'Oyun kaydı yok'
            : sameDay(game.time, now)
            ? 'Günlük hafıza oyunu tamamlandı'
            : 'Bugün henüz oynanmadı',
      ),
    ];

    return DashCard(
      restShadow: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: sc.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Günlük Medikal Özet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sc.guest.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Simülasyon',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: sc.guest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth < 720) {
                return Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      items[i],
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: items[i]),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Simüle edilmiş örnek veridir. Tıbbi tanı değildir; sağlık '
            'cihazı veya doktor değerlendirmesinin yerine geçmez.',
            style: TextStyle(fontSize: 11, color: sc.muted),
          ),
        ],
      ),
    );
  }
}

class _Vital extends StatelessWidget {
  const _Vital({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
    required this.note,
    this.noteColor,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;
  final String note;
  final Color? noteColor;

  @override
  Widget build(BuildContext context) {
    final muted = context.sc.muted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      if (unit.isNotEmpty)
                        TextSpan(
                          text: ' $unit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                            color: muted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: TextStyle(fontSize: 12, color: noteColor ?? muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
