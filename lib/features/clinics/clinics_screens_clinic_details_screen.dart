part of 'clinics_screens.dart';

class ClinicDetailsScreen extends StatelessWidget {
  const ClinicDetailsScreen({super.key, required this.clinic});
  final ClinicData clinic;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تفاصيل العيادة'), leading: const BackButton()),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppCard(child: Row(children: [
                Container(width: 68, height: 68, decoration: BoxDecoration(color: clinic.color, borderRadius: BorderRadius.circular(19)), child: Icon(clinic.icon, color: AppColors.primaryDark, size: 32)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(clinic.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(clinic.category, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 7),
                  Row(children: [const Icon(Icons.location_on_outlined, color: AppColors.muted, size: 16), const SizedBox(width: 4), Expanded(child: Text(clinic.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium))]),
                ])),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(label: clinic.status, color: AppColors.success),
              ])),
              const SizedBox(height: AppSpacing.xl),
              Text('عن العيادة', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(clinic.description, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.xl),
              Text('معلومات العيادة', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(child: Column(children: [
                _ClinicInfoRow(icon: Icons.location_on_outlined, title: 'الموقع', value: clinic.location),
                const Divider(height: AppSpacing.lg),
                _ClinicInfoRow(icon: Icons.schedule_outlined, title: 'ساعات العمل', value: clinic.hours),
                const Divider(height: AppSpacing.lg),
                _ClinicInfoRow(icon: Icons.people_outline, title: 'عدد الأطباء', value: '${clinic.doctors.length} أطباء'),
              ])),
              const SizedBox(height: AppSpacing.xl),
              Text('التخصصات', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final specialty in clinic.specialties) _SpecialtyChip(label: specialty)]),
              const SizedBox(height: AppSpacing.xl),
              Text('أطباء العيادة', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ...clinic.doctors.map((doctor) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ClinicDoctorCard(
                      doctor: doctor,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DoctorDetailsScreen.preview(doctorId: doctor.id, initials: doctor.initials, name: doctor.name, specialty: doctor.specialty, clinic: clinic.name, location: clinic.location, rating: doctor.rating, reviews: doctor.reviews, experience: doctor.experience, bio: doctor.bio, services: doctor.services, color: doctor.color))),
                    ),
                  )),
              const SizedBox(height: AppSpacing.md),
              Text('موقع العيادة', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: EdgeInsets.zero,
                child: Container(
                  height: 154,
                  decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(20)),
                  child: Stack(alignment: Alignment.center, children: [
                    Icon(Icons.map_outlined, color: AppColors.primary.withValues(alpha: .18), size: 92),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 34),
                      const SizedBox(height: AppSpacing.xs),
                      Text('موقع العيادة على الخريطة', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                    ]),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );

}
