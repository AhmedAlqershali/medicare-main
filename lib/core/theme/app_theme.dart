import 'package:flutter/material.dart';

enum AppThemeMode {
  light,
  dark,
  system;

  String get value => name;

  static AppThemeMode fromValue(String? value) {
    for (final mode in AppThemeMode.values) {
      if (mode.value == value) return mode;
    }
    return AppThemeMode.system;
  }

  ThemeMode get materialMode => switch (this) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };
}

class AppThemeScope extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const AppThemeScope({super.key, required ValueNotifier<ThemeMode> notifier, required super.child});

  static ValueNotifier<ThemeMode>? of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    return scope?.notifier;
  }
}

abstract final class AppColors {
  static const primary = Color(0xFF147D82);
  static const primaryDark = Color(0xFF0D5E66);
  static const ink = Color(0xFF172B3A);
  static const muted = Color(0xFF71818C);
  static const canvas = Color(0xFFF6F9F9);
  static const surface = Colors.white;
  static const border = Color(0xFFE4ECEC);
  static const mint = Color(0xFFE6F4F2);
  static const sky = Color(0xFFE8F1F8);
  static const peach = Color(0xFFFFF1E7);
  static const success = Color(0xFF248A68);
  static const warning = Color(0xFFB56B2A);
}

abstract final class AppSpacing {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

ThemeData buildAppTheme() {
  const textColor = AppColors.ink;
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryDark,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: textColor,
      error: Color(0xFFC84C4C),
    ),
    textTheme: base.textTheme.copyWith(
      displaySmall: const TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2),
      headlineSmall: const TextStyle(color: textColor, fontSize: 21, fontWeight: FontWeight.w800, height: 1.25),
      titleMedium: const TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700, height: 1.35),
      bodyLarge: const TextStyle(color: textColor, fontSize: 15, height: 1.55),
      bodyMedium: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.45),
      labelLarge: const TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
    ),
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.canvas, foregroundColor: textColor, elevation: 0, centerTitle: false),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
  );
}

ThemeData buildAppDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFF101C22),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryDark,
      onSecondary: Colors.white,
      surface: Color(0xFF18262D),
      onSurface: Color(0xFFF4F7F8),
      error: Color(0xFFFF6B6B),
    ),
    textTheme: base.textTheme.copyWith(
      displaySmall: const TextStyle(color: Color(0xFFF4F7F8), fontSize: 28, fontWeight: FontWeight.w800, height: 1.2),
      headlineSmall: const TextStyle(color: Color(0xFFF4F7F8), fontSize: 21, fontWeight: FontWeight.w800, height: 1.25),
      titleMedium: const TextStyle(color: Color(0xFFF4F7F8), fontSize: 16, fontWeight: FontWeight.w700, height: 1.35),
      bodyLarge: const TextStyle(color: Color(0xFFDDE6E9), fontSize: 15, height: 1.55),
      bodyMedium: const TextStyle(color: Color(0xFF9FB0B7), fontSize: 13, height: 1.45),
      labelLarge: const TextStyle(color: Color(0xFFF4F7F8), fontSize: 14, fontWeight: FontWeight.w700),
    ),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF101C22), foregroundColor: Color(0xFFF4F7F8), elevation: 0, centerTitle: false),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF18262D),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF334A55))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF334A55))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
  );
}