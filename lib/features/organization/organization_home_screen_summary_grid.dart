part of 'organization_home_screen.dart';

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.clinics, required this.doctors, required this.patients, required this.appointments});
  final int clinics;
  final int doctors;
  final int patients;
  final int appointments;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
          _SummaryCard(width: width, label: 'عدد العيادات', value: '$clinics', icon: Icons.local_hospital_outlined, color: AppColors.sky),
          _SummaryCard(width: width, label: 'عدد الأطباء', value: '$doctors', icon: Icons.medical_information_outlined, color: AppColors.mint),
          _SummaryCard(width: width, label: 'عدد المرضى', value: '$patients', icon: Icons.people_outline, color: AppColors.peach),
          _SummaryCard(width: width, label: 'عدد المواعيد', value: '$appointments', icon: Icons.calendar_month_outlined, color: AppColors.mint),
        ]);
      });
}
