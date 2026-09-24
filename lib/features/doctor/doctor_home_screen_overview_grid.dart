part of 'doctor_home_screen.dart';

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.appointments, required this.patients});
  final int appointments;
  final int patients;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
          _OverviewCard(width: width, label: 'المواعيد', value: '$appointments', icon: Icons.calendar_today_outlined, color: AppColors.sky),
          _OverviewCard(width: width, label: 'المرضى', value: '$patients', icon: Icons.people_outline, color: AppColors.mint),
          _OverviewCard(width: width, label: 'القادمة', value: '${appointments}', icon: Icons.upcoming_outlined, color: AppColors.peach),
          _OverviewCard(width: width, label: 'المكتملة', value: '0', icon: Icons.task_alt_outlined, color: AppColors.mint),
        ]);
      });
}
