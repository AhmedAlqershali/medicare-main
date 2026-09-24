part of 'organization_clinics_screen.dart';

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({required this.clinic, required this.onTap});
  final OrganizationClinic clinic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: clinic.color, borderRadius: BorderRadius.circular(15)), child: Icon(clinic.icon, color: AppColors.primaryDark, size: 24)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(clinic.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(clinic.location, style: Theme.of(context).textTheme.bodyMedium),
              ])),
              StatusBadge(label: clinic.status, color: clinic.status == 'نشطة' ? AppColors.success : AppColors.muted),
            ]),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(child: _Meta(icon: Icons.people_outline, value: '${clinic.doctorsCount} أطباء')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _Meta(icon: Icons.category_outlined, value: '${clinic.departmentsCount} أقسام')),
            ]),
            const SizedBox(height: AppSpacing.xs),
            _Meta(icon: Icons.medical_services_outlined, value: '${clinic.patientsCount} مريضاً'),
          ]),
        ),
      );
}
