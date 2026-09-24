part of 'patient_home_screen.dart';

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primaryDark, size: 20)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700))),
              const Icon(Icons.chevron_left_rounded, color: AppColors.muted, size: 19),
            ]),
          ),
        ),
      );
}
