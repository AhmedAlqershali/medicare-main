part of 'patient_home_screen.dart';

class _DoctorsSection extends StatelessWidget {
  const _DoctorsSection({required this.doctors});
  final List<DoctorEntity> doctors;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 188,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: doctors.isEmpty
              ? [const EmptyState(title: 'لا يوجد أطباء', message: 'لم تُسجل أطباء متاحون لهذه المؤسسة.')]
              : [for (final doctor in doctors.take(5)) ...[
                  _DoctorCard(initials: doctor.initials, name: doctor.name, specialty: doctor.specialty, clinic: doctor.clinic, color: Color(doctor.colorValue)),
                  const SizedBox(width: AppSpacing.sm),
                ]],
        ),
      );
}
