part of 'auth_screens.dart';

class DoctorPlaceholderScreen extends StatelessWidget {
  const DoctorPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
            child: Column(children: [
              const SizedBox(height: AppSpacing.lg),
              const _BrandMark(size: 68),
              const SizedBox(height: AppSpacing.lg),
              const Text('مرحبا خالد'),
              Text('تجربة الطبيب قريباً', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text('نجهّز لك مساحة مهنية تساعدك على إدارة مواعيدك والتواصل مع مرضاك بسهولة.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(children: [
                  Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.medical_information_outlined, color: AppColors.primaryDark, size: 27)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const StatusBadge(label: 'قيد التجهيز', color: AppColors.primary),
                    const SizedBox(height: AppSpacing.xs),
                    Text('أدوات الطبيب ستتوفر قريباً', style: Theme.of(context).textTheme.titleMedium),
                  ])),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: 'العودة لاختيار الحساب', onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const UserTypeScreen()))),
            ]),
          ),
        ),
      );
}
