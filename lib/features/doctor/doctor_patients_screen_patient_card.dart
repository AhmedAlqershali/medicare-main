part of 'doctor_patients_screen.dart';

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient, required this.onTap});
  final DoctorPatient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Row(children: [AppAvatar(initials: patient.initials, size: 52, backgroundColor: patient.avatarColor), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(patient.name, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text('${patient.age}  •  ${patient.gender}', style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 3), Text('آخر موعد: ${patient.lastAppointment}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11))])), StatusBadge(label: patient.status, color: patient.status == 'مستقر' ? AppColors.success : AppColors.primary), const SizedBox(width: 4), const Icon(Icons.chevron_left_rounded, color: AppColors.muted)])));
}
