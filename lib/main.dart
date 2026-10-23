import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/firestore/firestore_service.dart';
import 'core/settings/app_theme_service.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/medicare_entry_screen.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AuthRepositoryImpl.instance.restoreSession();
  if (AuthRepositoryImpl.instance.isAuthenticated) {
    await FirebaseMessagingService.instance.initialize();
  }
  final themeMode = ValueNotifier<ThemeMode>(await _loadThemeMode());
  runApp(MedicareApp(themeMode: themeMode));
}

Future<ThemeMode> _loadThemeMode() async {
  final uid = AuthRepositoryImpl.instance.currentUser?.id;
  final mode = await AppThemeService(FirestoreService()).loadThemeMode(uid);
  return mode.materialMode;
}

class MedicareApp extends StatelessWidget {
  const MedicareApp({super.key, required this.themeMode});

  final ValueNotifier<ThemeMode> themeMode;

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      notifier: themeMode,
      child: AnimatedBuilder(
        animation: themeMode,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Medicare',
          theme: buildAppTheme(),
          darkTheme: buildAppDarkTheme(),
          themeMode: themeMode.value,
          locale: const Locale('ar'),
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MedicareEntryScreen(),
        ),
      ),
    );
  }
}