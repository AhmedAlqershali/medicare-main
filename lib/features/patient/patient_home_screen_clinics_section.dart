part of 'patient_home_screen.dart';

class _ClinicsSection extends StatelessWidget {
  const _ClinicsSection({
    required this.clinics,
  });

  final List<ClinicEntity> clinics;

  @override
  Widget build(BuildContext context) {
    if (clinics.isEmpty) {
      return const EmptyState(
        title: 'لا توجد عيادات',
        message: 'لا توجد عيادات متاحة في مؤسستك حاليًا.',
      );
    }

    return Column(
      children: [
        for (final clinic in clinics.take(5)) ...[
          ClinicCard(
            name: clinic.name,
            location: clinic.location,
          ),
          const SizedBox(
            height: AppSpacing.sm,
          ),
        ],
      ],
    );
  }
}