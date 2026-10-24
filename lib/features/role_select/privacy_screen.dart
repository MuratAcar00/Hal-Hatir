import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/ui/app_scaffold.dart';

/// Shown once on first launch.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String text) => ListTile(
      leading: Icon(icon, size: 32),
      title: Text(text, style: const TextStyle(fontSize: 17)),
    );
    return AppScaffold(
      title: 'Gizlilik',
      roleSwitch: false,
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          children: [
            const Text(
              'Sessiz Komşu nasıl çalışır?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            item(
              Icons.videocam_off,
              'Kamera ve mikrofon yok. Giyilecek bir cihaz da yok.',
            ),
            item(
              Icons.sensors,
              'Sadece priz, kapı ve hareket sensörlerinin "ne zaman" '
              'çalıştığı kullanılır.',
            ),
            item(
              Icons.home,
              'Ham veri evde kalır; aileye yalnızca durum ve uyarı gider.',
            ),
            item(
              Icons.local_hospital,
              "Tıbbi cihaz veya acil durum hizmeti değildir. "
              "Acil durumda 112'yi arayın.",
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: context.read<AppState>().markPrivacySeen,
                child: const Text('Anladım', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
