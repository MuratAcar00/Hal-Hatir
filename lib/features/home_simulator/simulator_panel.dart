import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/clock.dart';
import '../../core/models.dart';
import '../../core/ui/app_colors.dart';

/// Demo controls: plain gray column with text buttons.
class SimulatorPanel extends StatelessWidget {
  const SimulatorPanel({super.key, required this.sidebar});

  /// true: fixed-width column on the right edge; false: full-width block.
  final bool sidebar;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final fast = s.clock.speed != SimClock.speeds.first;
    final offline = s.deviceOffline;

    Widget sensor(String label, ActivityType type) => TextButton(
      onPressed: offline ? null : () => s.addEvent(type),
      child: Text(label),
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: sidebar ? MainAxisSize.max : MainAxisSize.min,
      children: [
        const Text(
          'Simülatör',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        sensor('Çaydanlık', ActivityType.kettle),
        sensor('Kapı', ActivityType.door),
        sensor('Mutfak', ActivityType.motionKitchen),
        sensor('Yatak Odası', ActivityType.motionBedroom),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => s.setSpeed(fast ? SimClock.speeds.first : 600),
          child: Text(fast ? 'Normal hıza dön' : 'Hızlı İleri Sar'),
        ),
        if (s.alertState != AlertState.normal)
          TextButton(onPressed: s.acknowledge, child: const Text('İyiyim')),
        const Spacer(),
        TextButton(
          onPressed: s.startToday,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.muted,
            textStyle: const TextStyle(
              fontSize: 13,
              decoration: TextDecoration.underline,
            ),
          ),
          child: const Text('Günü Başlat'),
        ),
      ],
    );

    if (sidebar) {
      return Container(
        width: 240,
        color: AppColors.panel,
        padding: const EdgeInsets.fromLTRB(24, 32, 16, 24),
        child: column,
      );
    }
    return Container(
      width: double.infinity,
      color: AppColors.panel,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in column.children)
            if (c is! Spacer) c,
        ],
      ),
    );
  }
}
