part of 'appointment_booking_screens.dart';

class _DateOption extends StatelessWidget {
  const _DateOption({required this.date, required this.selected, required this.onTap});
  final AppointmentDate date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.onPrimary : colors.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? colors.primary : colors.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(date.day, style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(date.number, style: TextStyle(color: foreground, fontSize: 20, fontWeight: FontWeight.w800)),
            Text(date.month, style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
