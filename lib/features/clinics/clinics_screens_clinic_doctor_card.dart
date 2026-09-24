part of 'clinics_screens.dart';

class _ClinicDoctorCard extends StatelessWidget {
  const _ClinicDoctorCard({required this.doctor, required this.onTap});
  final ClinicDoctorData doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(children: [
          AppAvatar(initials: doctor.initials, size: 52, backgroundColor: doctor.color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(doctor.name, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text(doctor.specialty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600)), const SizedBox(height: 5), Row(children: [const Icon(Icons.star_rounded, color: AppColors.warning, size: 16), const SizedBox(width: 3), Text(doctor.rating, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(width: AppSpacing.sm), const Icon(Icons.circle, color: AppColors.success, size: 7), const SizedBox(width: 4), Text('متاحة اليوم', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700))])])),
          IconButton(onPressed: onTap, icon: const Icon(Icons.chevron_left_rounded), color: AppColors.primary, tooltip: 'عرض الملف'),
        ]),
      );
}
