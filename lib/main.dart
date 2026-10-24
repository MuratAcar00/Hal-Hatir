import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/ui/app_scaffold.dart';
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
      home: LayoutBuilder(
        builder: (context, c) => c.maxWidth >= wideBreakpoint
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
