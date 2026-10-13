part of 'doctor_profile_screens.dart';

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.icon, required this.title, required this.onTap, this.color});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tileColor = color ?? colors.onSurface;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: tileColor),
      title: Text(title, style: TextStyle(color: tileColor, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_left_rounded, color: colors.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
