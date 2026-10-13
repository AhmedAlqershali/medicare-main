import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/medicare_widgets.dart';

class AppHelpScreen extends StatelessWidget {
  const AppHelpScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('المساعدة')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            children: [
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.support_agent_outlined, color: AppColors.primary, size: 30),
                      const SizedBox(height: AppSpacing.md),
                      Text('دليل استخدام Medicare', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text('استخدم هذه التعليمات للوصول إلى ملفاتك، مواعيدك، وإعدادات حسابك.', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _HelpSection(title: 'الإجراءات الشائعة'),
              const SizedBox(height: AppSpacing.sm),
              _HelpItem(icon: Icons.person_outline, title: 'ملف الحساب', description: 'راجع بيانات حسابك وتحديثها من شاشة الملف الشخصي.'),
              _HelpItem(icon: Icons.notifications_active_outlined, title: 'الإشعارات', description: 'استخدم إعداد الإشعارات لإدارة صلاحيات إشعارات التطبيق.'),
              _HelpItem(icon: Icons.brightness_6_outlined, title: 'المظهر', description: 'اختر الوضع الفاتح أو الداكن أو الالتزام بالنظام.'),
              _HelpItem(icon: Icons.lock_outline, title: 'تغيير كلمة المرور', description: 'استخدم شاشة تغيير كلمة المرور لإدارة دخول حسابك.'),
            ],
          ),
        ),
      );
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(title, style: Theme.of(context).textTheme.titleMedium);
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text(description, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
