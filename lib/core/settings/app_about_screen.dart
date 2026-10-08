import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/medicare_widgets.dart';

class AppAboutScreen extends StatelessWidget {
  const AppAboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('عن Medicare')),
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
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(18)),
                        child: const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 30),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Medicare', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text('منصة رعاية صحية متصلة لتقديم مواعيد، ملفات مرضى، وتحديثات علاجية في مكان واحد.', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _AboutSection(title: 'المميزات'),
              const SizedBox(height: AppSpacing.sm),
              _AboutItem(icon: Icons.calendar_month_outlined, title: 'جدولة المواعيد', description: 'تتبع المواعيد اليومية والأسبوعية.'),
              _AboutItem(icon: Icons.people_alt_outlined, title: 'إدارة المرضى', description: 'راجع معلومات المريض وملاحظات المتابعة.'),
              _AboutItem(icon: Icons.notifications_active_outlined, title: 'الإشعارات الفورية', description: 'استقبل تحديثات المواعيد والرسائل الجديدة.'),
              const SizedBox(height: AppSpacing.lg),
              Text('الإصدار 1.0.0', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted)),
            ],
          ),
        ),
      );
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(title, style: Theme.of(context).textTheme.titleMedium);
}

class _AboutItem extends StatelessWidget {
  const _AboutItem({required this.icon, required this.title, required this.description});

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
