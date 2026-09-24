part of 'clinics_screens.dart';

class _ClinicListCard extends StatelessWidget {
  const _ClinicListCard({required this.clinic, required this.onTap});
  final ClinicData clinic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: clinic.color, borderRadius: BorderRadius.circular(15)), child: Icon(clinic.icon, color: AppColors.primaryDark, size: 26)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(clinic.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text(clinic.category, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600))])),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Text(clinic.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [const Icon(Icons.location_on_outlined, color: AppColors.muted, size: 16), const SizedBox(width: 4), Expanded(child: Text(clinic.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)))]),
          const SizedBox(height: AppSpacing.xs),
          Row(children: [const Icon(Icons.people_outline, color: AppColors.muted, size: 16), const SizedBox(width: 4), Text('${clinic.doctors.length} أطباء', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)), const Spacer(), StatusBadge(label: clinic.status, color: AppColors.success)]),
          const Spacer(),
          SizedBox(width: double.infinity, height: 38, child: OutlinedButton(onPressed: onTap, child: const Text('عرض العيادة'))),
        ]),
      );
}
