part of 'clinics_screens.dart';

class _ClinicInfoRow extends StatelessWidget {
  const _ClinicInfoRow({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: AppColors.primary, size: 19)), const SizedBox(width: AppSpacing.sm), Text('$title: ', style: Theme.of(context).textTheme.bodyMedium), Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)))]);
}
