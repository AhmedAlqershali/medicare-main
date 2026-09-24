part of 'patient_home_screen.dart';

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.initials, required this.name, required this.specialty, required this.clinic, required this.color});
  final String initials;
  final String name;
  final String specialty;
  final String clinic;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 198,
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              AppAvatar(initials: initials, size: 44, backgroundColor: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14))),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Text(specialty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(clinic, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            Row(children: [
              const Icon(Icons.circle, color: AppColors.success, size: 7),
              const SizedBox(width: 5),
              Text('متاحة اليوم', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
      );
}
