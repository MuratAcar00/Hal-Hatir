import 'package:flutter/material.dart';

/// "Güven ve Huzur" palette (light) and "Premium Dark / Slate" (dark).
class AppColors {
  static const primary = Color(0xFF006D77);
  static const background = Color(0xFFF8F9FA);
  static const card = Color(0xFFFFFFFF);

  // Light status colors.
  static const normal = Color(0xFF2A9D8F);
  static const attention = Color(0xFFF4A261);
  static const alert = Color(0xFFE76F51);
  static const offline = Color(0xFF6C757D);
  static const guest = Color(0xFF5E8CA8); // calm blue, guest mode

  static const muted = Color(0xFF6C757D);
  static const health = Color(0xFFFFF3E6);

  // Dark.
  static const darkPrimary = Color(0xFF2DD4BF);
  static const darkBackground = Color(0xFF0F172A);
  static const darkCard = Color(0xFF1E293B);
  static const darkText = Color(0xFFF8FAFC);

  /// Thin card / divider line.
  static Color border(Brightness b) => b == Brightness.dark
      ? const Color(0xFF334155)
      : const Color(0xFFE2E8F0);
}

/// Status colors that resolve by brightness.
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.primary,
    required this.normal,
    required this.attention,
    required this.alert,
    required this.offline,
    required this.guest,
    required this.muted,
    required this.health,
  });

  final Color primary;
  final Color normal;
  final Color attention;
  final Color alert;
  final Color offline;
  final Color guest;
  final Color muted;
  final Color health;

  static const light = StatusColors(
    primary: AppColors.primary,
    normal: AppColors.normal,
    attention: AppColors.attention,
    alert: AppColors.alert,
    offline: AppColors.offline,
    guest: AppColors.guest,
    muted: AppColors.muted,
    health: AppColors.health,
  );

  static const dark = StatusColors(
    primary: AppColors.darkPrimary,
    normal: Color(0xFF0D9488),
    attention: Color(0xFFD97706),
    alert: Color(0xFFDC2626),
    offline: Color(0xFF475569),
    guest: Color(0xFF3B6E96),
    muted: Color(0xFF94A3B8),
    health: Color(0xFF3A2E1F),
  );

  @override
  StatusColors copyWith() => this;

  @override
  StatusColors lerp(StatusColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

extension StatusColorsX on BuildContext {
  StatusColors get sc =>
      Theme.of(this).extension<StatusColors>() ?? StatusColors.light;
}
