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

  static AppThemeMode fromMaterialMode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => AppThemeMode.light,
        ThemeMode.dark => AppThemeMode.dark,
        ThemeMode.system => AppThemeMode.system,
      };

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
  static const primary = Color(0xFF0F7479);
  static const primaryDark = Color(0xFF0B5E63);
  static const ink = Color(0xFF172B3A);
  static const muted = Color(0xFF667982);
  static const canvas = Color(0xFFF4F8F9);
  static const surface = Colors.white;
  static const border = Color(0xFFDCE7EA);
  static const mint = Color(0xFFE3F4F2);
  static const sky = Color(0xFFE8F1F7);
  static const peach = Color(0xFFFFF1E7);
  static const success = Color(0xFF197653);
  static const warning = Color(0xFF92520C);
  static const error = Color(0xFFB42336);

  static const darkCanvas = Color(0xFF101A20);
  static const darkSurface = Color(0xFF18252C);
  static const darkBorder = Color(0xFF30424A);
  static const darkInk = Color(0xFFEAF2F4);
  static const darkMuted = Color(0xFFA6B7BD);
  static const darkPrimary = Color(0xFF75D1CB);
  static const darkPrimaryContainer = Color(0xFF244341);
  static const darkSuccess = Color(0xFF71D4A5);
  static const darkWarning = Color(0xFFFFC66D);
  static const darkError = Color(0xFFFF8A80);
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
  const colorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.mint,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.primaryDark,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.sky,
    onSecondaryContainer: AppColors.ink,
    tertiary: AppColors.success,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.peach,
    onTertiaryContainer: AppColors.ink,
    surface: AppColors.surface,
    onSurface: textColor,
    surfaceTint: AppColors.primary,
    outline: AppColors.muted,
    outlineVariant: AppColors.border,
    error: AppColors.error,
    onError: Colors.white,
  );
  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: base.textTheme.copyWith(
      displaySmall: const TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2),
      headlineSmall: const TextStyle(color: textColor, fontSize: 21, fontWeight: FontWeight.w800, height: 1.25),
      titleMedium: const TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700, height: 1.35),
      bodyLarge: const TextStyle(color: textColor, fontSize: 15, height: 1.55),
      bodyMedium: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.45),
      labelLarge: const TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
    ),
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.canvas, foregroundColor: textColor, elevation: 0, centerTitle: false),
    dividerColor: AppColors.border,
    dialogBackgroundColor: AppColors.surface,
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.surface, surfaceTintColor: AppColors.surface),
    navigationBarTheme: const NavigationBarThemeData(backgroundColor: AppColors.surface, indicatorColor: AppColors.mint),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
  );
}

ThemeData buildAppDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  const textColor = AppColors.darkInk;
  const colorScheme = ColorScheme.dark(
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.darkCanvas,
    primaryContainer: AppColors.darkPrimaryContainer,
    onPrimaryContainer: AppColors.darkPrimary,
    secondary: AppColors.darkPrimary,
    onSecondary: AppColors.darkCanvas,
    secondaryContainer: Color(0xFF263A46),
    onSecondaryContainer: Color(0xFFD8EAF1),
    tertiary: AppColors.darkSuccess,
    onTertiary: AppColors.darkCanvas,
    tertiaryContainer: Color(0xFF3A3025),
    onTertiaryContainer: Color(0xFFFFD9AD),
    surface: AppColors.darkSurface,
    onSurface: textColor,
    surfaceTint: AppColors.darkPrimary,
    outline: AppColors.darkMuted,
    outlineVariant: AppColors.darkBorder,
    error: AppColors.darkError,
    onError: AppColors.darkCanvas,
  );
  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.darkCanvas,
    textTheme: base.textTheme.copyWith(
      displaySmall: const TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2),
      headlineSmall: const TextStyle(color: textColor, fontSize: 21, fontWeight: FontWeight.w800, height: 1.25),
      titleMedium: const TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700, height: 1.35),
      bodyLarge: const TextStyle(color: Color(0xFFD8E4E8), fontSize: 15, height: 1.55),
      bodyMedium: const TextStyle(color: AppColors.darkMuted, fontSize: 13, height: 1.45),
      labelLarge: const TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
    ),
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.darkCanvas, foregroundColor: textColor, elevation: 0, centerTitle: false),
    dividerColor: AppColors.darkBorder,
    dialogBackgroundColor: AppColors.darkSurface,
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.darkSurface, surfaceTintColor: AppColors.darkSurface),
    navigationBarTheme: const NavigationBarThemeData(backgroundColor: AppColors.darkSurface, indicatorColor: AppColors.darkPrimaryContainer),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.darkBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.darkBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.5)),
    ),
  );
}