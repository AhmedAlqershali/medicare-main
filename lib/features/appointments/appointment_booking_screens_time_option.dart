part of 'appointment_booking_screens.dart';

class _TimeOption extends StatelessWidget {
  const _TimeOption({required this.label, required this.selected, required this.unavailable, required this.onTap});
  final String label;
  final bool selected;
  final bool unavailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(onTap: unavailable ? null : onTap, borderRadius: BorderRadius.circular(11), child: Container(width: 92, alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: unavailable ? AppColors.canvas : selected ? AppColors.mint : AppColors.surface, borderRadius: BorderRadius.circular(11), border: Border.all(color: unavailable ? AppColors.border : selected ? AppColors.primary : AppColors.border)), child: Text(label, style: TextStyle(color: unavailable ? AppColors.muted : selected ? AppColors.primaryDark : AppColors.ink, fontSize: 12, fontWeight: FontWeight.w700, decoration: unavailable ? TextDecoration.lineThrough : null))));
}
