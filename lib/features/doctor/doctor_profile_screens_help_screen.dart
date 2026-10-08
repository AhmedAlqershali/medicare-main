part of 'doctor_profile_screens.dart';

class DoctorHelpScreen extends StatelessWidget {
  const DoctorHelpScreen({super.key});

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
                      Text('استخدم هذه التعليمات للوصول إلى المواعيد، إدارة مرضى، ومعلومات المريض.', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'الإجراءات الشائعة'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('عرض المواعيد', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('افتح قائمة المواعيد من لوحة الطبيب لتكامل مع جدول المواعيد الحالية.', style: Theme.of(context).textTheme.bodyMedium)]))),
              const SizedBox(height: AppSpacing.sm),
              AppCard(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('إدارة مرضى', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('استخدم شاشة المرضى لتراجع بيانات المريض وملاحظات المتابعة.', style: Theme.of(context).textTheme.bodyMedium)]))),
              const SizedBox(height: AppSpacing.sm),
              AppCard(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('الإشعارات', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('تفعيل الإشعارات من إعدادات الملف الشخصي يتيح استقبال إشعارات المواعيد والرسائل الجديدة.', style: Theme.of(context).textTheme.bodyMedium)]))),
              const SizedBox(height: AppSpacing.sm),
              AppCard(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('المظهر', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('اختر الوضع الفاتح أو الداكن أو الالتزام بالنظام من إعدادات الملف الشخصي.', style: Theme.of(context).textTheme.bodyMedium)]))),
            ],
          ),
        ),
      );
}
