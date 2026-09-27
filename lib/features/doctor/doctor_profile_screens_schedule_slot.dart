part of 'doctor_profile_screens.dart';

class _ScheduleSlot extends StatelessWidget {
const _ScheduleSlot({
required this.time,
required this.booked,
required this.onEdit,
required this.onDelete,
});

final String time;
final bool booked;
final VoidCallback? onEdit;
final VoidCallback? onDelete;

@override
Widget build(BuildContext context) {
final color =
booked ? AppColors.primary : AppColors.mint;

final foreground =
booked ? Colors.white : AppColors.ink;

return Container(
width: 180,
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: color,
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: booked
? AppColors.primary
    : AppColors.border,
),
),
child: Column(
children: [
Icon(
booked
? Icons.event_available_outlined
    : Icons.access_time_outlined,
color: booked
? Colors.white
    : AppColors.primary,
size: 20,
),

const SizedBox(height: 5),

Text(
time,
style: TextStyle(
color: foreground,
fontSize: 12,
fontWeight: FontWeight.w800,
),
),

const SizedBox(height: 4),

Text(
booked ? 'يوجد حجز' : 'متاح للحجز',
style: TextStyle(
color: foreground,
fontSize: 11,
fontWeight: FontWeight.w600,
),
),

const SizedBox(height: 6),

Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
IconButton(
onPressed: onEdit,
icon: Icon(
Icons.edit_outlined,
color: foreground,
),
tooltip: booked
? 'لا يمكن تعديل فترة محجوزة'
    : 'تعديل',
),
IconButton(
onPressed: onDelete,
icon: Icon(
Icons.delete_outline,
color: foreground,
),
tooltip: booked
? 'لا يمكن حذف فترة محجوزة'
    : 'حذف',
),
],
),
],
),
);
}
}
