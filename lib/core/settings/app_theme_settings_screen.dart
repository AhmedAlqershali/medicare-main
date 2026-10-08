import 'package:flutter/material.dart';

import '../auth/services/firebase_auth_repository.dart';
import '../firestore/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/medicare_widgets.dart';
import 'app_theme_service.dart';

class AppThemeSettingsScreen extends StatefulWidget {
  const AppThemeSettingsScreen({super.key});

  @override
  State<AppThemeSettingsScreen> createState() => _AppThemeSettingsScreenState();
}

class _AppThemeSettingsScreenState extends State<AppThemeSettingsScreen> {
  AppThemeMode _selectedMode = AppThemeMode.system;

  @override
  void initState() {
    super.initState();
    _selectedMode = AppThemeMode.fromValue(AppThemeScope.of(context)?.value.name);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = AppThemeScope.of(context);
    if (notifier == null) {
      return Scaffold(body: SafeArea(child: Text('تعذر تهيئة المظهر')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('المظهر')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
          children: [
            Text('اختر المظهر المطلوب للتطبيق.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                children: [
                  _ThemeChoice(mode: AppThemeMode.light, label: 'فاتح', selected: _selectedMode == AppThemeMode.light, onTap: () => _select(AppThemeMode.light)),
                  const Divider(height: 1),
                  _ThemeChoice(mode: AppThemeMode.dark, label: 'داكن', selected: _selectedMode == AppThemeMode.dark, onTap: () => _select(AppThemeMode.dark)),
                  const Divider(height: 1),
                  _ThemeChoice(mode: AppThemeMode.system, label: 'النظام', selected: _selectedMode == AppThemeMode.system, onTap: () => _select(AppThemeMode.system)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(AppThemeMode mode) async {
    final notifier = AppThemeScope.of(context);
    if (notifier == null) return;

    setState(() => _selectedMode = mode);
    notifier.value = mode.materialMode;

    final uid = FirebaseAuthRepository.instance.currentUser?.id;
    await AppThemeService(FirestoreService()).saveThemeMode(uid, mode);
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({required this.mode, required this.label, required this.selected, required this.onTap});

  final AppThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        leading: Icon(mode == AppThemeMode.dark ? Icons.dark_mode_outlined : mode == AppThemeMode.light ? Icons.light_mode_outlined : Icons.settings_system_daydream_outlined),
        title: Text(label),
        trailing: selected ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
        onTap: onTap,
      );
}
