part of 'doctor_profile_screens.dart';

class DoctorAboutScreen extends StatelessWidget {
  const DoctorAboutScreen({super.key});

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
              const SectionHeader(title: 'المميزات'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [const Icon(Icons.calendar_month_outlined, color: AppColors.primary), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('جدولة المواعيد', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('تتبع المواعيد اليومية والأسبوعية.', style: Theme.of(context).textTheme.bodyMedium)]))]))),
              const SizedBox(height: AppSpacing.sm),
              AppCard(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [const Icon(Icons.people_alt_outlined, color: AppColors.primary), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('إدارة المرضى', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('راجع معلومات المريض وملاحظات المتابعة.', style: Theme.of(context).textTheme.bodyMedium)]))]))),
              const SizedBox(height: AppSpacing.sm),
              AppCard(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [const Icon(Icons.notifications_active_outlined, color: AppColors.primary), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('الإشعارات الفورية', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('استقبل تحديثات المواعيد والرسائل الجديدة.', style: Theme.of(context).textTheme.bodyMedium)]))]))),
            ],
          ),
        ),
      );
}
