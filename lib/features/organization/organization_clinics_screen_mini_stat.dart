part of 'organization_clinics_screen.dart';

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primary, size: 20)),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ]),
      );
}
