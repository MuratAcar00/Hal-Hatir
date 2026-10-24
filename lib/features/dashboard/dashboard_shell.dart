import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_scaffold.dart';
import '../../core/ui/app_theme.dart';
import '../family/alert_history.dart';
import '../family/settings_screen.dart';
import '../home_simulator/home_simulator_screen.dart';
import 'devices.dart';
import 'elder_view.dart';
import 'health_page.dart';
import 'notes_page.dart';
import 'overview_page.dart';
import 'report_page.dart';
import 'skeleton.dart';

enum DashPage {
  overview('Genel Bakış', Icons.dashboard_outlined, Icons.dashboard),
  health('Sağlık Trendleri', Icons.monitor_heart_outlined, Icons.monitor_heart),
  devices('Cihaz Durumları', Icons.sensors_outlined, Icons.sensors),
  report('Haftalık Rapor', Icons.assessment_outlined, Icons.assessment),
  notes('Notlar', Icons.sticky_note_2_outlined, Icons.sticky_note_2),
  settings('Ayarlar', Icons.settings_outlined, Icons.settings);

  const DashPage(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Demo view: who is looking at the panel.
enum ViewRole {
  family('Aile', 'Aile Üyesi', 'Birincil yakın', Icons.family_restroom),
  caregiver('Bakıcı', 'Bakıcı', 'Bakım desteği', Icons.volunteer_activism),
  elder('Yaşlı', personName, 'Evdeki kullanıcı', Icons.elderly);

  const ViewRole(this.label, this.person, this.sub, this.icon);
  final String label;
  final String person;
  final String sub;
  final IconData icon;
}

/// Wide-screen web dashboard: sidebar, header, page, simulator side panel.
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DashPage _page = DashPage.overview;
  ViewRole _role = ViewRole.family;
  bool _first = true;

  List<DashPage> get _pages => _role == ViewRole.caregiver
      ? [
          for (final p in DashPage.values)
            if (p != DashPage.settings) p,
        ]
      : DashPage.values;

  void _select(DashPage p) {
    if (p == _page) return;
    setState(() {
      _page = p;
      _first = false;
    });
  }

  void _setRole(ViewRole r) {
    if (r == _role) return;
    setState(() {
      _role = r;
      _first = false;
      if (!_pages.contains(_page)) _page = DashPage.overview;
    });
  }

  Widget _content() => switch (_page) {
    DashPage.overview => const OverviewPage(),
    DashPage.health => const HealthPage(),
    DashPage.devices => const DevicesPage(),
    DashPage.report => const ReportPage(),
    DashPage.notes => NotesPage(author: _role.person),
    DashPage.settings => Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: const SettingsScreen(embedded: true),
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final showPanel = MediaQuery.sizeOf(context).width >= 1240;
    final elder = _role == ViewRole.elder;
    void openSimulator() => _scaffoldKey.currentState?.openEndDrawer();
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: showPanel
          ? null
          : const Drawer(width: 420, child: SafeArea(child: SimulatorPanel())),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                if (!elder)
                  _Sidebar(pages: _pages, page: _page, onSelect: _select),
                Expanded(
                  child: Column(
                    children: [
                      if (!elder)
                        _Header(
                          page: _page,
                          role: _role,
                          onRole: _setRole,
                          onSimulator: showPanel ? null : openSimulator,
                          onSettings: () => _select(DashPage.settings),
                        ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: elder
                                  ? ElderView(
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!showPanel) ...[
                                            FilledButton.tonalIcon(
                                              icon: const Icon(
                                                Icons.home_outlined,
                                              ),
                                              label: const Text(
                                                'Ev Simülatörü',
                                              ),
                                              onPressed: openSimulator,
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          RoleMenu(
                                            role: _role,
                                            onRole: _setRole,
                                            child: _RolePill(role: _role),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SkeletonGate(
                                      key: ValueKey('$_page-$_role'),
                                      delay: Duration(
                                        milliseconds: _first ? 1000 : 450,
                                      ),
                                      child: Center(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 1400,
                                          ),
                                          child: _content(),
                                        ),
                                      ),
                                    ),
                            ),
                            if (showPanel) ...[
                              const VerticalDivider(width: 1),
                              const SizedBox(width: 400, child: SimulatorPanel()),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SafetyFooter(),
        ],
      ),
    );
  }
}

/// Role switcher popup (Aile / Bakıcı / Yaşlı), optional "Ayarlar" entry.
class RoleMenu extends StatelessWidget {
  const RoleMenu({
    super.key,
    required this.role,
    required this.onRole,
    required this.child,
    this.onSettings,
  });

  final ViewRole role;
  final ValueChanged<ViewRole> onRole;
  final VoidCallback? onSettings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Görünümü değiştir',
      offset: const Offset(0, 48),
      onSelected: (v) {
        if (v == 'settings') {
          onSettings?.call();
        } else {
          onRole(ViewRole.values.byName(v));
        }
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(enabled: false, child: Text('Görünüm')),
        for (final r in ViewRole.values)
          CheckedPopupMenuItem<String>(
            value: r.name,
            checked: r == role,
            child: Text(r.label),
          ),
        if (onSettings != null) ...[
          const PopupMenuDivider(),
          const PopupMenuItem<String>(value: 'settings', child: Text('Ayarlar')),
        ],
      ],
      child: child,
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});

  final ViewRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, size: 18, color: context.sc.primary),
          const SizedBox(width: 8),
          Text(
            'Görünüm: ${role.label}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Icon(Icons.expand_more, size: 18),
        ],
      ),
    );
  }
}

/// Elderly person's home simulator, as a dashboard side panel / drawer.
class SimulatorPanel extends StatelessWidget {
  const SimulatorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ev Simülatörü',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  '$personName\'nın evi · demo kontrolleri',
                  style: TextStyle(fontSize: 12, color: context.sc.muted),
                ),
              ],
            ),
          ),
          const Expanded(child: HomeSimulatorBody()),
        ],
      ),
    );
  }
}

Color _line(BuildContext context) =>
    AppColors.border(Theme.of(context).brightness);

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.pages,
    required this.page,
    required this.onSelect,
  });

  final List<DashPage> pages;
  final DashPage page;
  final ValueChanged<DashPage> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final attention = s.alertState != AlertState.normal;
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(right: BorderSide(color: _line(context))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.sc.primary,
                        Color.lerp(context.sc.primary, Colors.black, 0.3)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sessiz Komşu',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text('Aile Paneli', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final p in pages)
                  _NavItem(
                    page: p,
                    active: p == page,
                    badge: p == DashPage.overview && attention,
                    onTap: () => onSelect(p),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (s.deviceOffline
                        ? context.sc.offline
                        : attention
                        ? context.sc.attention
                        : context.sc.normal)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.deviceOffline
                        ? 'Merkez cihaz çevrimdışı'
                        : attention
                        ? 'Aktif uyarı var'
                        : 'Tüm sistemler çalışıyor',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Demo sürümü · simüle veri',
                    style: TextStyle(fontSize: 11, color: context.sc.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.page,
    required this.active,
    required this.badge,
    required this.onTap,
  });

  final DashPage page;
  final bool active;
  final bool badge;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final primary = context.sc.primary;
    final active = widget.active;
    return Semantics(
      button: true,
      selected: active,
      label: widget.page.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
            decoration: BoxDecoration(
              color: active
                  ? primary.withValues(alpha: 0.14)
                  : _hover
                  ? primary.withValues(alpha: 0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: active ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  active ? widget.page.activeIcon : widget.page.icon,
                  color: active ? primary : context.sc.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.page.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      color: active ? primary : null,
                    ),
                  ),
                ),
                if (widget.badge)
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: context.sc.alert,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.page,
    required this.role,
    required this.onRole,
    required this.onSimulator,
    required this.onSettings,
  });

  final DashPage page;
  final ViewRole role;
  final ValueChanged<ViewRole> onRole;
  final VoidCallback? onSimulator;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final theme = context.watch<ThemeController>();
    final active = s.alertState != AlertState.normal;
    final recent = s.engine.history.reversed.take(4).toList();
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _line(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.label,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$personName · ${dateText(s.now)} ${hm(s.now)}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: context.sc.muted),
                ),
              ],
            ),
          ),
          if (onSimulator != null) ...[
            FilledButton.tonalIcon(
              icon: const Icon(Icons.home_outlined),
              label: const Text('Ev Simülatörü'),
              onPressed: onSimulator,
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            tooltip: theme.isDark ? 'Açık tema' : 'Koyu tema',
            icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: theme.toggle,
          ),
          PopupMenuButton<int>(
            tooltip: 'Bildirimler',
            offset: const Offset(0, 48),
            icon: Badge(
              isLabelVisible: active,
              smallSize: 9,
              backgroundColor: context.sc.alert,
              child: const Icon(Icons.notifications_outlined),
            ),
            itemBuilder: (_) => <PopupMenuEntry<int>>[
              if (active)
                PopupMenuItem(
                  value: 0,
                  child: Text('Şimdi: ${levelLabel(s.alertState)}'),
                ),
              for (final h in recent)
                PopupMenuItem(
                  value: 1,
                  child: Text('${hm(h.start)} · ${levelLabel(h.maxLevel)}'),
                ),
              if (!active && recent.isEmpty)
                const PopupMenuItem(
                  enabled: false,
                  value: 2,
                  child: Text('Yeni bildirim yok'),
                ),
            ],
          ),
          const SizedBox(width: 4),
          RoleMenu(
            role: role,
            onRole: onRole,
            onSettings: role == ViewRole.family ? onSettings : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          context.sc.primary,
                          Color.lerp(context.sc.primary, Colors.black, 0.3)!,
                        ],
                      ),
                    ),
                    child: Icon(role.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.person,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(role.sub, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  const Icon(Icons.expand_more, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
