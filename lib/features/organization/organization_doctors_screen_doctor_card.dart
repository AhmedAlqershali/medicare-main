part of 'organization_doctors_screen.dart';

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor, required this.onTap});
  final OrganizationDoctor doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Row(children: [AppAvatar(initials: doctor.initials, size: 52, backgroundColor: doctor.avatarColor), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(doctor.name, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text(doctor.specialty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600)), const SizedBox(height: 3), Text(doctor.clinic, style: Theme.of(context).textTheme.bodyMedium)])), StatusBadge(label: doctor.status, color: doctor.status == 'نشط' ? AppColors.success : AppColors.muted)])));
}
