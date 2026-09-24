part of 'doctor_home_screen.dart';

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Column(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.primary, size: 22)), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 11))])));
}
