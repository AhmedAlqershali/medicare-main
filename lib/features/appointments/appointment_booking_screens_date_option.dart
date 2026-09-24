part of 'appointment_booking_screens.dart';

class _DateOption extends StatelessWidget {
  const _DateOption({required this.date, required this.selected, required this.onTap});
  final AppointmentDate date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Container(width: 82, padding: const EdgeInsets.symmetric(vertical: 9), decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? AppColors.primary : AppColors.border)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(date.day, style: TextStyle(color: selected ? Colors.white : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(date.number, style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontSize: 20, fontWeight: FontWeight.w800)), Text(date.month, style: TextStyle(color: selected ? Colors.white : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600))])));
}
