import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

/// Light / dark choice, persisted. Default: light.
class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs)
    : mode = _prefs.getBool(_key) == true ? ThemeMode.dark : ThemeMode.light;

  static const _key = 'darkMode';
  final SharedPreferences _prefs;
  ThemeMode mode;

  bool get isDark => mode == ThemeMode.dark;

  void toggle() {
    mode = isDark ? ThemeMode.light : ThemeMode.dark;
    _prefs.setBool(_key, isDark);
    notifyListeners();
  }
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final primary = dark ? AppColors.darkPrimary : AppColors.primary;
  final bg = dark ? AppColors.darkBackground : AppColors.background;
  final card = dark ? AppColors.darkCard : AppColors.card;
  final text = dark ? AppColors.darkText : const Color(0xFF212529);
  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: b,
    primary: primary,
    surface: card,
    onSurface: text,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  final hoverElevation = WidgetStateProperty.resolveWith<double>(
    (states) => states.contains(WidgetState.hovered) ? 6 : 0,
  );
  const hoverShadow = WidgetStatePropertyAll<Color>(Colors.black54);
  return base.copyWith(
    scaffoldBackgroundColor: bg,
    extensions: [dark ? StatusColors.dark : StatusColors.light],
    cardTheme: CardThemeData(
      color: card,
      elevation: 2,
      shadowColor: Colors.black26,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border(b)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: primary,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: primary,
      ),
    ),
    textTheme: base.textTheme
        .apply(bodyColor: text, displayColor: text)
        .copyWith(
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: text,
          ),
          bodyMedium: TextStyle(fontSize: 16, color: text),
        ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: shape).copyWith(
        elevation: hoverElevation,
        shadowColor: hoverShadow,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ).copyWith(elevation: hoverElevation, shadowColor: hoverShadow),
    ),
  );
}
