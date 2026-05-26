// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

abstract class AppTheme {
  // ── Brand colours ─────────────────────────────────────────────────────────
  static const Color _green900  = Color(0xFF1B5E20);
  static const Color _green700  = Color(0xFF2E7D32);
  static const Color _green500  = Color(0xFF4CAF50);
  static const Color _green100  = Color(0xFFE8F5E9);
  static const Color _amber600  = Color(0xFFFFB300);
  static const Color _red700    = Color(0xFFD32F2F);

  // ── Light theme ───────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor:   _green700,
          brightness:  Brightness.light,
          primary:     _green700,
          secondary:   _green500,
          error:       _red700,
          surface:     Colors.white,
          onPrimary:   Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: _green700,
          foregroundColor: Colors.white,
          elevation:       0,
          centerTitle:     false,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _green500,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _green700,
            foregroundColor: Colors.white,
            minimumSize:    const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _green700,
            side:            const BorderSide(color: _green700),
            minimumSize:    const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:  const BorderSide(color: _green700, width: 2),
          ),
          filled:    true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color:     Colors.white,
        ),
        chipTheme: ChipThemeData(
          backgroundColor:   _green100,
          labelStyle:        const TextStyle(color: _green900),
          selectedColor:     _green500,
          secondaryLabelStyle: const TextStyle(color: Colors.white),
        ),
        dividerTheme: const DividerThemeData(thickness: 1, space: 1),
      );

  // ── Dark theme ────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor:  _green500,
          brightness: Brightness.dark,
          primary:    _green500,
          secondary:  _green700,
          error:      Colors.redAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation:       0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  // ── Status colours (shared across screens) ────────────────────────────────
  static Color statusColor(String? status) {
    switch (status) {
      case 'planted':   return _green500;
      case 'monitored': return _green700;
      case 'dead':      return _red700;
      case 'replaced':  return _amber600;
      default:          return Colors.grey;
    }
  }

  static IconData statusIcon(String? status) {
    switch (status) {
      case 'planted':   return Icons.park;
      case 'monitored': return Icons.monitor;
      case 'dead':      return Icons.close;
      case 'replaced':  return Icons.refresh;
      default:          return Icons.hourglass_empty;
    }
  }
}
