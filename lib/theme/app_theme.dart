// Theme tokens for both themes, ported from skins.css.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeId { sportDark, clean }

extension AppThemeIdX on AppThemeId {
  String get key => this == AppThemeId.sportDark ? 'sport-dark' : 'clean';
  static AppThemeId fromKey(String? k) =>
      k == 'clean' ? AppThemeId.clean : AppThemeId.sportDark;
}

/// Full set of design tokens for a single theme.
class AppTokens {
  final AppThemeId id;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color accent;
  final Color accentText;
  final Color phase1;
  final Color phase2;
  final Color phase3;
  final Color danger;
  final Color success;
  final double radius;
  final double radiusSm;
  final double letterDisplay; // letter-spacing in logical px scaled to em-ish
  final double letterTight;
  final List<BoxShadow> cardShadow;
  final Color navBg;
  final Gradient? cardGradient; // null => flat surface
  final Gradient coachTint;
  final Color restBg;
  final Color restText;
  final Color restActionBg;
  final Color backdrop;

  const AppTokens({
    required this.id,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.accentText,
    required this.phase1,
    required this.phase2,
    required this.phase3,
    required this.danger,
    required this.success,
    required this.radius,
    required this.radiusSm,
    required this.letterDisplay,
    required this.letterTight,
    required this.cardShadow,
    required this.navBg,
    required this.cardGradient,
    required this.coachTint,
    required this.restBg,
    required this.restText,
    required this.restActionBg,
    required this.backdrop,
  });

  Color phaseColor(int n) => n == 1 ? phase1 : (n == 2 ? phase2 : phase3);

  static AppTokens of(AppThemeId id) =>
      id == AppThemeId.clean ? _clean : _sportDark;

  // ===== Sport Dark =====
  static const _sportDark = AppTokens(
    id: AppThemeId.sportDark,
    bg: Color(0xFF0A0A0B),
    surface: Color(0xFF111114),
    surface2: Color(0xFF1A1A1F),
    surface3: Color(0xFF22222A),
    border: Color(0xFF26262D),
    borderStrong: Color(0xFF3A3A44),
    text: Color(0xFFF4F4F5),
    textMuted: Color(0xFFA1A1AA),
    textFaint: Color(0xFF71717A),
    accent: Color(0xFFC5FB45),
    accentText: Color(0xFF0A0A0B),
    phase1: Color(0xFF4ADE80),
    phase2: Color(0xFFFB923C),
    phase3: Color(0xFFC084FC),
    danger: Color(0xFFF87171),
    success: Color(0xFF4ADE80),
    radius: 18,
    radiusSm: 12,
    letterDisplay: -0.7,
    letterTight: -0.3,
    cardShadow: [
      BoxShadow(color: Color(0x0AFFFFFF), blurRadius: 0, spreadRadius: 1),
    ],
    navBg: Color(0xEB111114),
    cardGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF131318), Color(0xFF0F0F13)],
    ),
    coachTint: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x00C5FB45), Color(0x0AC5FB45)],
    ),
    restBg: Color(0xFFC5FB45),
    restText: Color(0xFF0A0A0B),
    restActionBg: Color(0x2E000000),
    backdrop: Color(0xB3000000),
  );

  // ===== Clean =====
  static const _clean = AppTokens(
    id: AppThemeId.clean,
    bg: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF1F5F9),
    surface3: Color(0xFFE2E8F0),
    border: Color(0xFFE5E7EB),
    borderStrong: Color(0xFFCBD5E1),
    text: Color(0xFF0F172A),
    textMuted: Color(0xFF64748B),
    textFaint: Color(0xFF94A3B8),
    accent: Color(0xFF0F172A),
    accentText: Color(0xFFFFFFFF),
    phase1: Color(0xFF10B981),
    phase2: Color(0xFFF97316),
    phase3: Color(0xFF8B5CF6),
    danger: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    radius: 16,
    radiusSm: 10,
    letterDisplay: -0.5,
    letterTight: -0.2,
    cardShadow: [
      BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 4)),
    ],
    navBg: Color(0xEBFFFFFF),
    cardGradient: null,
    coachTint: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x000F172A), Color(0x050F172A)],
    ),
    restBg: Color(0xFF0F172A),
    restText: Color(0xFFF8FAFC),
    restActionBg: Color(0x26FFFFFF),
    backdrop: Color(0x660F172A),
  );

  // ===== Text helpers (Inter + JetBrains Mono) =====
  TextStyle display(double size, {FontWeight weight = FontWeight.w700, Color? color, double? height}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterDisplay,
        color: color ?? text,
        height: height,
      );

  TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color? color, double? height}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? text,
        height: height,
      );

  TextStyle mono(double size, {FontWeight weight = FontWeight.w700, Color? color}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color ?? text,
      );

  TextStyle label(double size, {Color? color, double spacing = 0.6}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: spacing,
        color: color ?? textMuted,
      );
}
