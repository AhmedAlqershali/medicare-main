part of 'patient_home_screen.dart';

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tileColor = color == AppColors.mint
        ? colors.primaryContainer
        : color == AppColors.sky
            ? colors.secondaryContainer
            : color == AppColors.peach
                ? colors.tertiaryContainer
                : color;
    return Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(border: Border.all(color: colors.outlineVariant), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: tileColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: colors.primary, size: 20)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700))),
              Icon(Icons.chevron_left_rounded, color: colors.onSurfaceVariant, size: 19),
            ]),
          ),
        ),
      );
  }
}
