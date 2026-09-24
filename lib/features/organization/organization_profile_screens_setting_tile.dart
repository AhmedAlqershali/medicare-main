part of 'organization_profile_screens.dart';

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.icon, required this.title, required this.onTap, this.color = AppColors.ink});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4), leading: Icon(icon, color: color), title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)), trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.muted), onTap: onTap);
}
