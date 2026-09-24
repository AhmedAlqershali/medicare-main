part of 'clinics_screens.dart';

class _ClinicsEmptyState extends StatelessWidget {
  const _ClinicsEmptyState();

  @override
  Widget build(BuildContext context) => const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: EmptyState(title: 'لم نجد عيادات مطابقة', message: 'جرّب البحث باسم مختلف أو اختر تصنيفًا آخر', icon: Icons.local_hospital_outlined)));
}
