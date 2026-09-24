part of 'patient_profile_screens.dart';

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)));
}
