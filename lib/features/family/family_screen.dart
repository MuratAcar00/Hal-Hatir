import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/alert_engine.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/safety_footer.dart';
import '../home_simulator/simulator_panel.dart';

const personName = 'Ayşe Hanım';

const _months = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

String _sensorLabel(ActivityType t) => switch (t) {
  ActivityType.kettle => 'Çaydanlık',
  ActivityType.door => 'Kapı',
  ActivityType.motionKitchen => 'Mutfak',
  ActivityType.motionBedroom => 'Yatak odası',
};

class _Status {
  const _Status(this.text, this.color, {this.detail, this.actions = const []});
  final String text;
  final Color color;
  final String? detail;
  final List<(String, VoidCallback)> actions;
}

Future<void> _call(String number) =>
    launchUrl(Uri(scheme: 'tel', path: number));

_Status _statusOf(AppState s) {
  final e = s.engine;
  if (s.deviceOffline) {
    return _Status(
      'Bağlantı yok. Durum bilinmiyor.',
      AppColors.muted,
      actions: [('Yeniden bağlan', s.toggleOffline)],
    );
  }
  if (e.inactivity == Inactivity.asking) {
    return _Status(
      '48 saattir hareket yok. Evde kimse yok mu?',
      AppColors.attention,
      actions: [('Evet, alarmları dondur', s.confirmInactivity)],
    );
  }
  if (e.inactivity == Inactivity.frozen) {
    return _Status(
      'Alarmlar donduruldu.',
      AppColors.muted,
      actions: [
        (
          'Dondurmayı kaldır',
          () => s.updateSettings(s.settings.copyWith(paused: false)),
        ),
      ],
    );
  }
  if (s.alertState == AlertState.normal) {
    if (e.isGuestDay) {
      return const _Status('Bugün misafir var. Uyarılar kapalı.', AppColors.muted);
    }
    if (s.settings.paused) {
      return const _Status('Uyarılar duraklatıldı.', AppColors.muted);
    }
    final started = s.eventsOn(s.now).isNotEmpty;
    return _Status(
      started
          ? '$personName güne başladı. Her şey normal.'
          : 'Henüz hareket yok. Her şey normal.',
      AppColors.normal,
    );
  }
  final phone = s.settings.familyPhone;
  return _Status(
    "${s.now.hour < 12 ? 'Sabah rutini' : 'Günlük rutin'} gecikti. Kontrol edin.",
    s.alertState == AlertState.softCheck
        ? AppColors.attention
        : AppColors.alert,
    detail: e.explanation,
    actions: [
      if (phone.isNotEmpty) ('Aileyi ara', () => _call(phone)),
      ("112'yi ara", () => _call('112')),
    ],
  );
}

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final content = _Content(showSimulator: !wide);
    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: content,
                      ),
                    ),
                  ),
                  const SimulatorPanel(sidebar: true),
                ],
              )
            : content,
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.showSimulator});
  final bool showSimulator;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = s.now;
    final status = _statusOf(s);
    final recent = _recent(s);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
            children: [
              Text(
                hm(now),
                style: const TextStyle(
                  fontSize: 112,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${weekdayLong[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 64),
              Text(
                status.text,
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                  color: status.color,
                ),
              ),
              if (status.detail != null) ...[
                const SizedBox(height: 12),
                Text(
                  status.detail!,
                  style: const TextStyle(fontSize: 16, color: AppColors.muted),
                ),
              ],
              if (status.actions.isNotEmpty) const SizedBox(height: 16),
              for (final (label, onTap) in status.actions)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: onTap, child: Text(label)),
                ),
              const SizedBox(height: 64),
              if (recent.isEmpty)
                const Text(
                  'Henüz kayıt yok.',
                  style: TextStyle(fontSize: 18, color: AppColors.muted),
                ),
              for (var i = 0; i < recent.length; i++) ...[
                if (i > 0) const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    _line(recent[i], now),
                    style: const TextStyle(
                      fontSize: 20,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
              if (showSimulator) ...[
                const SizedBox(height: 48),
                const SimulatorPanel(sidebar: false),
              ],
            ],
          ),
        ),
        const SafetyFooter(),
      ],
    );
  }

  /// Last three events; yesterday fills in when today is short.
  List<SensorEvent> _recent(AppState s) {
    final all = [
      ...s.eventsOn(s.now.subtract(const Duration(days: 1))),
      ...s.eventsOn(s.now),
    ];
    return all.reversed.take(3).toList();
  }

  String _line(SensorEvent e, DateTime now) {
    final prefix = sameDay(e.time, now)
        ? ''
        : sameDay(e.time, now.subtract(const Duration(days: 1)))
        ? 'Dün '
        : '${two(e.time.day)}.${two(e.time.month)} ';
    return '$prefix${hm(e.time)} - ${_sensorLabel(e.type)}';
  }
}
