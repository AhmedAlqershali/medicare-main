part of 'patient_profile_screens.dart';

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({required this.icon, required this.title, required this.onTap, this.value, this.iconColor});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => AppCard(padding: EdgeInsets.zero, child: ListTile(onTap: onTap, leading: Icon(icon, color: iconColor ?? AppColors.primary), title: Text(title), trailing: value == null ? const Icon(Icons.chevron_left_rounded, color: AppColors.muted) : Text(value!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700))));
}
