import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'app_colors.dart';

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
    return Material(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Kamera ve ses yok. Ham veri evde kalır.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sessiz Komşu acil durum hizmetinin yerine geçmez. '
                "Acil durumda 112'yi arayın.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
