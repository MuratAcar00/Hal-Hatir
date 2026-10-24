import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

/// At this width and above both roles are shown side by side.
const wideBreakpoint = 900.0;

/// Scaffold with role switch (top right) and the safety footer.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.roleSwitch = true,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool roleSwitch;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...actions,
          if (roleSwitch && !wide)
            PopupMenuButton<String>(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Rolü değiştir',
              onSelected: (v) => state.setRole(
                v == 'home'
                    ? Role.home
                    : v == 'family'
                    ? Role.family
                    : null,
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'home',
                  child: Text('Evi simüle et (yaşlı)'),
                ),
                PopupMenuItem(value: 'family', child: Text('Aile uygulaması')),
                PopupMenuItem(value: 'select', child: Text('Rol seçimine dön')),
              ],
            ),
        ],
      ),
      body: wide
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: body,
              ),
            )
          : body,
      bottomNavigationBar: const SafetyFooter(),
    );
  }
}

class SafetyFooter extends StatelessWidget {
  const SafetyFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam_off,
                      size: 16,
                      color: cs.onSecondaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Kamera ve ses yok. Ham veri evde kalır.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sessiz Komşu acil durum hizmetinin yerine geçmez. '
                "Acil durumda 112'yi arayın.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
