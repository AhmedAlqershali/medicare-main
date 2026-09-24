part of 'appointment_booking_screens.dart';

class _AppointmentTypeOption extends StatelessWidget {
  const _AppointmentTypeOption({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md), decoration: BoxDecoration(color: selected ? AppColors.mint : AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? AppColors.primary : AppColors.border)), child: Row(children: [Icon(icon, color: selected ? AppColors.primary : AppColors.muted, size: 21), const SizedBox(width: AppSpacing.xs), Expanded(child: Text(label, style: TextStyle(color: selected ? AppColors.primaryDark : AppColors.ink, fontSize: 12, fontWeight: FontWeight.w700))), Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.primary : AppColors.muted, size: 19)])));
}
