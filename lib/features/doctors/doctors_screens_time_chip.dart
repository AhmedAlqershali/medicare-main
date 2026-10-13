part of 'doctors_screens.dart';

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: selected ? colors.primaryContainer : colors.surface, borderRadius: BorderRadius.circular(11), border: Border.all(color: selected ? colors.primary : colors.outlineVariant)),
          child: Text(label, style: TextStyle(color: selected ? colors.onPrimaryContainer : colors.onSurface, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      );
  }
}
