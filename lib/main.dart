import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/ui/app_colors.dart';
import 'core/ui/app_scaffold.dart';
import 'features/family/family_screen.dart';
import 'features/home_simulator/home_simulator_screen.dart';
import 'features/role_select/privacy_screen.dart';
import 'features/role_select/role_select_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load();
  runApp(
    ChangeNotifierProvider.value(value: state, child: const SessizKomsuApp()),
  );
}

/// "Güven ve Huzur" theme.
ThemeData _theme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.card,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 2,
      shadowColor: Colors.black26,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
    ),
    textTheme: base.textTheme
        .apply(bodyColor: const Color(0xFF212529))
        .copyWith(
          titleMedium: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
          bodyMedium: const TextStyle(fontSize: 16),
        ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: shape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );
}

class SessizKomsuApp extends StatelessWidget {
  const SessizKomsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.select((AppState s) => s.role);
    final privacySeen = context.select((AppState s) => s.privacySeen);
    return MaterialApp(
      title: 'Sessiz Komşu',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: LayoutBuilder(
        builder: (context, c) => !privacySeen
            ? const PrivacyScreen()
            : c.maxWidth >= wideBreakpoint
            ? const _SplitView()
            : switch (role) {
                null => const RoleSelectScreen(),
                Role.home => const HomeSimulatorScreen(),
                Role.family => const FamilyScreen(),
              },
      ),
    );
  }
}

/// Wide screens (projector/web): both roles at once, larger text.
class _SplitView extends StatelessWidget {
  const _SplitView();

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(1.25)),
      child: const Row(
        children: [
          Expanded(child: HomeSimulatorScreen()),
          VerticalDivider(width: 1),
          Expanded(child: FamilyScreen()),
        ],
      ),
    );
  }
}
