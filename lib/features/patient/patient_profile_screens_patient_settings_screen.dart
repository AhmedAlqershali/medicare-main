part of 'patient_profile_screens.dart';

class PatientSettingsScreen extends StatelessWidget {
  const PatientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl), children: [
            const _SettingsSectionTitle(title: 'الحساب'),
            _NavigationTile(icon: Icons.person_outline, title: 'الملف الشخصي', onTap: () => Navigator.of(context).pop()),
            _NavigationTile(icon: Icons.lock_outline, title: 'تغيير كلمة المرور', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))),
            _NavigationTile(icon: Icons.logout_rounded, title: 'تسجيل الخروج', iconColor: const Color(0xFFC84C4C), onTap: () => _showLogoutDialog(context)),
            const SizedBox(height: AppSpacing.lg),
            const _SettingsSectionTitle(title: 'التفضيلات'),
            _NavigationTile(icon: Icons.language_outlined, title: 'اللغة', value: 'العربية', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LanguageScreen()))),
            _NavigationTile(icon: Icons.notifications_none_rounded, title: 'الإشعارات', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()))),
            _NavigationTile(icon: Icons.brightness_6_outlined, title: 'الوضع الداكن / المظهر', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppearanceScreen()))),
            const SizedBox(height: AppSpacing.lg),
            const _SettingsSectionTitle(title: 'الدعم'),
            _NavigationTile(icon: Icons.support_agent_outlined, title: 'المساعدة والدعم', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen()))),
            _NavigationTile(icon: Icons.info_outline, title: 'عن Medicare', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutMedicareScreen()))),
          ]),
        ),
      );

  static Future<void> _showLogoutDialog(BuildContext context) async {
    await showDialog<void>(context: context, builder: (context) => AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
            FilledButton(onPressed: () { Navigator.of(context).pop(); AuthNavigation.openSignedOutFlow(context); }, child: const Text('تسجيل الخروج')),
          ],
        ));
  }
}
