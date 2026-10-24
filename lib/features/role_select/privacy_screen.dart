import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/safety_footer.dart';

/// Shown once on first launch.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget line(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(text, style: const TextStyle(fontSize: 20, height: 1.35)),
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    children: [
                      const Text(
                        'Sessiz Komşu',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nasıl çalışır?',
                        style: TextStyle(fontSize: 20, color: AppColors.muted),
                      ),
                      const SizedBox(height: 40),
                      line('Kamera ve mikrofon yok. Giyilecek bir cihaz da yok.'),
                      line(
                        'Yalnızca priz, kapı ve hareket sensörlerinin ne zaman '
                        'çalıştığı kullanılır.',
                      ),
                      line(
                        'Ham veri evde kalır. Aileye yalnızca durum ve uyarı gider.',
                      ),
                      line(
                        "Tıbbi cihaz veya acil durum hizmeti değildir. "
                        "Acil durumda 112'yi arayın.",
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: context.read<AppState>().markPrivacySeen,
                          child: const Text(
                            'Anladım',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SafetyFooter(),
          ],
        ),
      ),
    );
  }
}
