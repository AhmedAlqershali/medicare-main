part of 'patient_profile_screens.dart';

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.patient, required this.onEdit});
  final PatientProfile patient;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => AppCard(child: Column(children: [
        const AppAvatar(initials: 'س أ', size: 82, backgroundColor: AppColors.mint),
        const SizedBox(height: AppSpacing.md),
        Text(patient.name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(patient.email, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        const StatusBadge(label: 'مريض', color: AppColors.primary),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('تعديل الملف الشخصي')),
      ]));
}
