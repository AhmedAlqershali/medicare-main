part of 'patient_home_screen.dart';

class _ClinicsSection extends StatelessWidget {
  const _ClinicsSection({required this.clinics});
  final List<ClinicEntity> clinics;

  @override
  Widget build(BuildContext context) => clinics.isEmpty
      ? const EmptyState(title: 'لا توجد عيادات', message: 'لم تُسجل عيادات متاحة لهذه المؤسسة.')
      : Column(children: [
          for (final clinic in clinics.take(5)) ...[
            ClinicCard(name: clinic.name, location: clinic.location),
            const SizedBox(height: AppSpacing.sm),
          ],
        ]);
}
