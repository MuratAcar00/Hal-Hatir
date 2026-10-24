import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/ui/app_theme.dart';
import 'features/family/family_screen.dart';
import 'features/role_select/privacy_screen.dart';

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
    final privacySeen = context.select((AppState s) => s.privacySeen);
    return MaterialApp(
      title: 'Sessiz Komşu',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: privacySeen ? const FamilyScreen() : const PrivacyScreen(),
    );
  }
}
