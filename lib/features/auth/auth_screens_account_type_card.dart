part of 'auth_screens.dart';

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({required this.title, required this.description, required this.icon, required this.color, required this.selected, required this.onTap});
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? color : colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? colors.primary : colors.outlineVariant, width: selected ? 1.5 : 1),
            boxShadow: selected ? const [BoxShadow(color: Color(0x0A173A3A), blurRadius: 14, offset: Offset(0, 5))] : null,
          ),
          child: Row(children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: selected ? colors.onPrimary.withValues(alpha: .16) : color, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: colors.primary, size: 26)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: selected ? AppColors.ink : null)),
              const SizedBox(height: 3),
              Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: selected ? AppColors.muted : null)),
            ])),
            Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: selected ? colors.primary : colors.onSurfaceVariant),
          ]),
        ),
      ),
    );
  }
}
