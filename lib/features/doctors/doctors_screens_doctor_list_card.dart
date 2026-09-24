part of 'doctors_screens.dart';

class _DoctorListCard extends StatelessWidget {
  const _DoctorListCard({required this.doctor, required this.onTap});
  final DoctorData doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            AppAvatar(initials: doctor.initials, size: 54, backgroundColor: doctor.color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(doctor.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(doctor.specialty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
            ])),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Text(doctor.clinic, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.location_on_outlined, color: AppColors.muted, size: 15),
            const SizedBox(width: 4),
            Expanded(child: Text(doctor.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12))),
          ]),
          const Spacer(),
          Row(children: [
            const Icon(Icons.star_rounded, color: AppColors.warning, size: 17),
            const SizedBox(width: 4),
            Text(doctor.rating, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
            const Spacer(),
            const Icon(Icons.circle, color: AppColors.success, size: 7),
            const SizedBox(width: 4),
            Text('متاحة اليوم', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(width: double.infinity, height: 38, child: OutlinedButton(onPressed: onTap, child: const Text('عرض الملف'))),
        ]),
      );
}
