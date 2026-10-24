import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/hover_card.dart';
import 'dashboard_widgets.dart';

/// Simulated hardware. Battery and signal are demo values, not measurements.
class DeviceInfo {
  const DeviceInfo(
    this.name,
    this.room,
    this.icon, {
    this.type,
    this.battery,
    this.signal = 'Güçlü',
  });

  final String name;
  final String room;
  final IconData icon;
  final ActivityType? type; // null: the central device
  final int? battery; // null: mains powered
  final String signal;
}

const demoDevices = [
  DeviceInfo('Merkez Cihaz', 'Salon', Icons.router_outlined),
  DeviceInfo(
    'Çaydanlık Prizi',
    'Mutfak',
    Icons.electrical_services,
    type: ActivityType.kettle,
  ),
  DeviceInfo(
    'Kapı Sensörü',
    'Giriş',
    Icons.door_front_door_outlined,
    type: ActivityType.door,
    battery: 85,
    signal: 'İyi',
  ),
  DeviceInfo(
    'Yatak Odası Hareket Sensörü',
    'Yatak odası',
    Icons.sensors,
    type: ActivityType.motionBedroom,
    battery: 90,
  ),
  DeviceInfo(
    'Mutfak Hareket Sensörü',
    'Mutfak',
    Icons.sensors,
    type: ActivityType.motionKitchen,
    battery: 78,
    signal: 'İyi',
  ),
  DeviceInfo(
    'Banyo Kapısı Sensörü',
    'Banyo',
    Icons.wc,
    type: ActivityType.bathroomDoor,
    battery: 82,
  ),
  DeviceInfo(
    'Buzdolabı Kapak Sensörü',
    'Mutfak',
    Icons.kitchen,
    type: ActivityType.fridge,
    battery: 91,
  ),
  DeviceInfo(
    'Koltuk/TV Sensörü',
    'Salon',
    Icons.weekend_outlined,
    type: ActivityType.couch,
    battery: 88,
    signal: 'İyi',
  ),
  DeviceInfo(
    'İlaç Kutusu Sensörü',
    'Yatak odası',
    Icons.medical_services_outlined,
    type: ActivityType.medicine,
    battery: 64,
  ),
];

Color _batteryColor(BuildContext context, int? b) {
  if (b == null || b > 50) return context.sc.normal;
  return b > 20 ? context.sc.attention : context.sc.alert;
}

String _lastSignal(AppState s, DeviceInfo d) {
  if (s.deviceOffline) return 'Sinyal yok';
  if (d.type == null) return 'Şimdi';
  SensorEvent? last;
  for (final e in s.events) {
    if (e.type != d.type || e.time.isAfter(s.now)) continue;
    if (last == null || e.time.isAfter(last.time)) last = e;
  }
  return last == null ? 'Kayıt yok' : timeOrDate(last.time, s.now);
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final c = online ? context.sc.normal : context.sc.offline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          online ? 'Çevrimiçi' : 'Çevrimdışı',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c),
        ),
      ],
    );
  }
}

class _PowerBar extends StatelessWidget {
  const _PowerBar({required this.device});

  final DeviceInfo device;

  @override
  Widget build(BuildContext context) {
    final b = device.battery;
    final color = _batteryColor(context, b);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (b ?? 100) / 100,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          b == null ? 'Şebeke' : '%$b',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Compact list card for the overview page.
class DevicesCard extends StatelessWidget {
  const DevicesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sensors, color: context.sc.primary),
              const SizedBox(width: 10),
              const Text(
                'Cihaz Durumları',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final d in demoDevices.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: context.sc.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(d.icon, size: 20, color: context.sc.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                d.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _StatusDot(online: !s.deviceOffline),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _PowerBar(device: d),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            '+${demoDevices.length - 5} cihaz daha: Cihaz Durumları sayfasında. '
            'Pil ve sinyal değerleri simülasyondur.',
            style: TextStyle(fontSize: 11, color: context.sc.muted),
          ),
        ],
      ),
    );
  }
}

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final online = !s.deviceOffline;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        Text(
          online
              ? '${demoDevices.length} cihaz bağlı ve çalışıyor.'
              : 'Merkez cihaz çevrimdışı: sensör verisi alınamıyor.',
          style: TextStyle(fontSize: 15, color: context.sc.muted),
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 280,
          children: [
            for (final d in demoDevices)
              DashCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: context.sc.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(d.icon, color: context.sc.primary),
                        ),
                        const Spacer(),
                        _StatusDot(online: online),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      d.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      d.room,
                      style: TextStyle(fontSize: 13, color: context.sc.muted),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      d.battery == null ? 'Güç' : 'Pil',
                      style: TextStyle(fontSize: 12, color: context.sc.muted),
                    ),
                    const SizedBox(height: 6),
                    _PowerBar(device: d),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.wifi, size: 16, color: context.sc.muted),
                        const SizedBox(width: 6),
                        Text(
                          online ? 'Sinyal: ${d.signal}' : 'Sinyal yok',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: context.sc.muted),
                        const SizedBox(width: 6),
                        Text(
                          'Son sinyal: ${_lastSignal(s, d)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Pil ve sinyal değerleri demo için simüle edilmiştir. '
          'Son sinyal saatleri gerçek sensör olaylarından gelir.',
          style: TextStyle(fontSize: 12, color: context.sc.muted),
        ),
      ],
    );
  }
}
