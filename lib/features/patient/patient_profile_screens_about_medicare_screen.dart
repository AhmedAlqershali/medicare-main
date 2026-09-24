part of 'patient_profile_screens.dart';

class AboutMedicareScreen extends StatelessWidget {
  const AboutMedicareScreen({super.key});

  @override
  Widget build(BuildContext context) => _ChoiceScreen(title: 'عن Medicare', child: Column(children: [
        const SizedBox(height: AppSpacing.md),
        const _BrandMark(),
        const SizedBox(height: AppSpacing.md),
        Text('Medicare', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text('منصة رعاية صحية تساعدك على اكتشاف الأطباء والعيادات وحجز مواعيدك بسهولة.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
        _NavigationTile(icon: Icons.info_outline, title: 'عن التطبيق', onTap: () => _showMessage(context, 'Medicare منصة للرعاية الصحية وحجز المواعيد.')),
        _NavigationTile(icon: Icons.privacy_tip_outlined, title: 'سياسة الخصوصية', onTap: () => _showMessage(context, 'سياسة الخصوصية متاحة عبر إدارة المؤسسة.')),
        _NavigationTile(icon: Icons.description_outlined, title: 'شروط الاستخدام', onTap: () => _showMessage(context, 'شروط الاستخدام متاحة عبر إدارة المؤسسة.')),
        const SizedBox(height: AppSpacing.md),
        Text('الإصدار 1.0.0', style: Theme.of(context).textTheme.bodyMedium),
      ]));

  static void _showMessage(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
