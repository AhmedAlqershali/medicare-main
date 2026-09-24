part of 'appointments_screens.dart';

class _EmptyAppointments extends StatelessWidget {
  const _EmptyAppointments({required this.status});
  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = status == AppointmentStatus.upcoming;
    return Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 76, height: 76, decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(24)), child: Icon(status == AppointmentStatus.completed ? Icons.task_alt_rounded : status == AppointmentStatus.cancelled ? Icons.event_busy_outlined : Icons.calendar_month_outlined, color: AppColors.primary, size: 35)), const SizedBox(height: AppSpacing.lg), Text(isUpcoming ? 'لا توجد مواعيد قادمة' : status == AppointmentStatus.completed ? 'لا توجد مواعيد مكتملة' : 'لا توجد مواعيد ملغاة', style: Theme.of(context).textTheme.titleMedium), if (isUpcoming) ...[const SizedBox(height: AppSpacing.xs), Text('سيحدد الطبيب موعد الزيارة القادمة من ملفك.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)]])));
  }
}
