import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_scaffold.dart';
import '../../core/ui/section_card.dart';
import '../../core/alert_engine.dart';
import 'alert_history.dart';
import 'health_trends.dart';
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
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.verified_outlined,
                  color: AppColors.normal,
                  size: 30,
                ),
                title: Text(
                  "Yakınınız ${hm(s.lastAckAt!)}'de iyi olduğunu bildirdi",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          SectionCard(
            icon: Icons.schedule,
            title: 'Son Aktivite',
            child: Text(
              last == null
                  ? 'Kayıt yok'
                  : '${sameDay(last.time, s.now) ? 'Bugün' : dateText(last.time)} '
                        '${hm(last.time)} · ${last.type.label}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const _ExpectedVsActual(),
          const SectionCard(
            icon: Icons.show_chart,
            title: 'Haftalık ritim: günün ilk hareketi',
            child: SizedBox(height: 200, child: WeeklyChart()),
          ),
          const HealthTrendsCard(),
          const WeeklySummary(),
          const AlertHistoryList(),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme
                    .copyWith(primary: Colors.white, onPrimary: color),
              ),
              child: action!,
            ),
          ],
        ],
      ),
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    // Hardware / mode states look different from the red health alert.
    if (s.deviceOffline) {
      return const _ModeCard(
        color: AppColors.offline,
        icon: Icons.power_off,
        title: 'Merkez Cihaz: Çevrimdışı (Elektrik kesintisi olabilir)',
        detail:
            'Sensör verisi alınamıyor. Bu bir sağlık uyarısı değildir; '
            'bağlantı gelince izleme devam eder.',
      );
    }
    if (s.engine.inactivity == Inactivity.asking) {
      return _ModeCard(
        color: AppColors.offline,
        icon: Icons.luggage,
        title: 'Uzun Süreli Hareketsizlik (Tatil/Hastane)',
        detail:
            '48 saattir hiç sensör verisi yok. Evde kimse yok mu? '
            'Tatilde mi / hastanede mi?',
        action: FilledButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Evet, evde kimse yok: alarmları dondur'),
          onPressed: s.confirmInactivity,
        ),
      );
    }
    if (s.engine.inactivity == Inactivity.frozen) {
      return _ModeCard(
        color: AppColors.offline,
        icon: Icons.ac_unit,
        title: 'Alarmlar donduruldu (Tatil/Hastane)',
        detail: 'Yeni bir sensör olayı gelince izleme kendiliğinden başlar.',
        action: OutlinedButton(
          onPressed: () => s.updateSettings(s.settings.copyWith(paused: false)),
          child: const Text('Dondurmayı kaldır'),
        ),
      );
    }
    if (s.alertState == AlertState.normal && s.engine.isGuestDay) {
      return const _ModeCard(
        color: AppColors.guest,
        icon: Icons.groups,
        title: 'Çoklu Kişi Algılandı',
        detail:
            'Mutfak ve yatak odasında aynı anda hareket var (misafir/temizlikçi). '
            'Bugün uyarılar susturuldu; yarın normale döner.',
      );
    }
    final (color, title, detail) = switch (s.alertState) {
      AlertState.normal => (
        AppColors.normal,
        'Bugün Normal',
        s.settings.paused
            ? 'Ziyaretçi / tatil modu açık: uyarılar duraklatıldı.'
            : s.settings.isMonitoring(s.now)
            ? 'Rutin beklendiği gibi.'
            : 'İzleme saatleri dışında, yeni uyarı gönderilmez.',
      ),
      AlertState.softCheck => (
        AppColors.attention,
        'Dikkat',
        'Beklenen bir hareket olmadı. Yakınınıza "İyi misiniz?" diye soruldu.',
      ),
      AlertState.familyAlert => (
        AppColors.alert,
        'Uyarı',
        'Yakınınız 15 dakikadır cevap vermedi. Lütfen arayın.',
      ),
      AlertState.secondContactAlert => (
        AppColors.alert,
        'Uyarı',
        'Hâlâ cevap yok. ${s.settings.secondContactName.isEmpty ? 'İkinci kişiye' : '${s.settings.secondContactName} adlı kişiye'} de haber verildi.',
      ),
    };
    return Card(
      color: color,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  s.alertState == AlertState.normal
                      ? Icons.favorite
                      : Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              detail,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (s.engine.explanation != null) ...[
              const SizedBox(height: 8),
              Text(
                'Neden uyardı? ${s.engine.explanation}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
            if (s.alertState == AlertState.familyAlert ||
                s.alertState == AlertState.secondContactAlert) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CallButton(
                    label: 'Yakınımı ara',
                    phone: s.settings.familyPhone,
                  ),
                  if (s.alertState == AlertState.secondContactAlert)
                    _CallButton(
                      label: s.settings.secondContactName.isEmpty
                          ? 'İkinci kişiyi ara'
                          : '${s.settings.secondContactName} adlı kişiyi ara',
                      phone: s.settings.secondContactPhone,
                    ),
                  _CallButton(
                    label: "112'yi ara",
                    phone: '112',
                    emergency: true,
                  ),
                ],
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.checklist,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bugün beklenen / gerçekleşen (${isWeekend(now) ? 'hafta sonu' : 'hafta içi'})',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
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
                          ? AppColors.normal
                          : confirmed
                          ? AppColors.offline
                          : late
                          ? AppColors.alert
                          : AppColors.muted,
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

/// Opens the phone dialer. Without a number it explains what is missing.
class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.label,
    required this.phone,
    this.emergency = false,
  });

  final String label;
  final String phone;
  final bool emergency;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: emergency ? Colors.white : Colors.white24,
        foregroundColor: emergency ? AppColors.alert : Colors.white,
      ),
      icon: const Icon(Icons.call),
      label: Text(label),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        if (phone.isEmpty) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Telefon numarası yok. Ayarlar\'dan ekleyin.'),
            ),
          );
          return;
        }
        final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
        if (!ok) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Arama başlatılamadı.')),
          );
        }
      },
    );
  }
}
