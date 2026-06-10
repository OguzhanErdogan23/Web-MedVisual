import 'package:flutter/material.dart';

/// MedVisual renkleri: tibbi/akademik, acik tema, indigo + teal vurgu.
abstract final class AppColors {
  static const indigo = Color(0xFF3F51B5);
  static const teal = Color(0xFF00897B);
  static const surface = Color(0xFFF7F8FC);
  static const danger = Color(0xFFC62828);
  static const warning = Color(0xFFEF6C00);
  static const success = Color(0xFF2E7D32);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.indigo,
    primary: AppColors.indigo,
    secondary: AppColors.teal,
    brightness: Brightness.light,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.indigo,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: Color(0xFFE3E6F0)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5DAE8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5DAE8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.indigo, width: 1.6),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.teal,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.indigo.withValues(alpha: 0.12),
      labelTextStyle: WidgetStatePropertyAll(
        base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Koyu tema: ayni indigo + teal tohumu, Material 3, koyu yuzeyler.
ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.indigo,
    secondary: AppColors.teal,
    brightness: Brightness.dark,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  const cardColor = Color(0xFF1C1F26);
  const fieldColor = Color(0xFF22262F);
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFF12141A),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF181B22),
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.primary,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: cardColor,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: Color(0xFF2C313B)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fieldColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2C313B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2C313B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.teal,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF181B22),
      indicatorColor: scheme.primary.withValues(alpha: 0.22),
      labelTextStyle: WidgetStatePropertyAll(
        base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
