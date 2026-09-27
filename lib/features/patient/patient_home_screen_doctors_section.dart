part of 'patient_home_screen.dart';

class _DoctorsSection extends StatelessWidget {
  const _DoctorsSection({
    required this.doctors,
  });

  final List<DoctorEntity> doctors;

  @override
  Widget build(BuildContext context) {
    if (doctors.isEmpty) {
      return const SizedBox(
        height: 120,
        child: EmptyState(
          title: 'لا يوجد أطباء',
          message: 'لا يوجد أطباء تابعون لعيادتك حاليًا.',
        ),
      );
    }

    return SizedBox(
      height: 188,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          for (final doctor in doctors.take(5)) ...[
            _DoctorCard(
              initials: doctor.initials,
              name: doctor.name,
              specialty: doctor.specialty,
              clinic: doctor.clinic,
              color: Color(doctor.colorValue),
            ),
            const SizedBox(
              width: AppSpacing.sm,
            ),
          ],
        ],
      ),
    );
  }
}