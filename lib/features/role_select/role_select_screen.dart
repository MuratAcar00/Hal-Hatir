import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/ui/app_scaffold.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    Widget roleButton(IconData icon, String label, Role role) => SizedBox(
      width: double.infinity,
      height: 110,
      child: FilledButton.tonalIcon(
        icon: Icon(icon, size: 40),
        label: Text(label, style: const TextStyle(fontSize: 22)),
        onPressed: () => state.setRole(role),
      ),
    );
    return AppScaffold(
      title: 'Sessiz Komşu',
      roleSwitch: false,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Yalnız yaşayan yakınınızın günlük ritmini öğrenir; '
              'rutin sapması veya uzun sessizlik olursa önce kendisine sorar, '
              'cevap yoksa aileye haber verir.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            roleButton(Icons.home, 'Evi simüle et (yaşlı)', Role.home),
            const SizedBox(height: 16),
            roleButton(Icons.family_restroom, 'Aile uygulaması', Role.family),
          ],
        ),
      ),
    );
  }
}
