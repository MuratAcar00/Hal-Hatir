import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'features/family/family_screen.dart';
import 'features/home_simulator/home_simulator_screen.dart';
import 'features/role_select/role_select_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load();
  runApp(
    ChangeNotifierProvider.value(value: state, child: const SessizKomsuApp()),
  );
}

class SessizKomsuApp extends StatelessWidget {
  const SessizKomsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.select((AppState s) => s.role);
    return MaterialApp(
      title: 'Sessiz Komşu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: switch (role) {
        null => const RoleSelectScreen(),
        Role.home => const HomeSimulatorScreen(),
        Role.family => const FamilyScreen(),
      },
    );
  }
}
