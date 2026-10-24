import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/ui/app_scaffold.dart';
import 'core/ui/app_theme.dart';
import 'features/dashboard/dashboard_shell.dart';
import 'features/family/family_screen.dart';
import 'features/home_simulator/home_simulator_screen.dart';
import 'features/role_select/privacy_screen.dart';
import 'features/role_select/role_select_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load();
  final theme = ThemeController(await SharedPreferences.getInstance());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: theme),
      ],
      child: const SessizKomsuApp(),
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
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: context.watch<ThemeController>().mode,
      home: LayoutBuilder(
        builder: (context, c) => !privacySeen
            ? const PrivacyScreen()
            : c.maxWidth >= wideBreakpoint
            ? const DashboardShell()
            : switch (role) {
                null => const RoleSelectScreen(),
                Role.home => const HomeSimulatorScreen(),
                Role.family => const FamilyScreen(),
              },
      ),
    );
  }
}
