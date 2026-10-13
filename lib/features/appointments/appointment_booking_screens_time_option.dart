part of 'appointment_booking_screens.dart';

class _TimeOption extends StatelessWidget {
  const _TimeOption({required this.label, required this.selected, required this.unavailable, required this.onTap});
  final String label;
  final bool selected;
  final bool unavailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: unavailable ? null : onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 92,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: unavailable ? colors.surfaceContainerHighest : selected ? colors.primaryContainer : colors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? colors.primary : colors.outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: unavailable ? colors.onSurfaceVariant : selected ? colors.onPrimaryContainer : colors.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            decoration: unavailable ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
