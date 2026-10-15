part of 'appointment_booking_screens.dart';

class _AppointmentTypeOption extends StatelessWidget {
  const _AppointmentTypeOption({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? colors.primary : colors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? colors.primary : colors.onSurfaceVariant, size: 21),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: selected ? colors.onPrimaryContainer : colors.onSurface, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? colors.primary : colors.onSurfaceVariant, size: 19),
          ],
        ),
      ),
    );
  }
}
