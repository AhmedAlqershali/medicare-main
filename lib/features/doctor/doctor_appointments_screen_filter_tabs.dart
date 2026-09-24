part of 'doctor_appointments_screen.dart';

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onChanged});
  final DoctorAppointmentFilter selected;
  final ValueChanged<DoctorAppointmentFilter> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            for (final item in const [
              (DoctorAppointmentFilter.today, 'اليوم'),
              (DoctorAppointmentFilter.upcoming, 'القادمة'),
              (DoctorAppointmentFilter.completed, 'المكتملة'),
              (DoctorAppointmentFilter.cancelled, 'الملغاة'),
            ])
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(item.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected == item.$1 ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected == item.$1 ? Colors.white : AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
