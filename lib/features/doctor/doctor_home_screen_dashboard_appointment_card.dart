part of 'doctor_home_screen.dart';

class _DashboardAppointmentCard extends StatelessWidget {
  const _DashboardAppointmentCard({required this.appointment, required this.onDetails});
  final DoctorAppointment appointment;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [AppAvatar(initials: appointment.patientInitials, size: 48, backgroundColor: appointment.avatarColor), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(appointment.patientName, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text('${appointment.time}  •  ${appointment.type}', style: Theme.of(context).textTheme.bodyMedium)])), StatusBadge(label: appointment.statusLabel, color: appointment.statusColor)]), const SizedBox(height: AppSpacing.xs), Align(alignment: AlignmentDirectional.centerStart, child: TextButton(onPressed: onDetails, child: const Text('عرض التفاصيل')))]));
}
