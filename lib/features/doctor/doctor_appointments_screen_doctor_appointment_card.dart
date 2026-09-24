part of 'doctor_appointments_screen.dart';

class _DoctorAppointmentCard extends StatelessWidget {
  const _DoctorAppointmentCard({required this.appointment, required this.onDetails});
  final DoctorAppointment appointment;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [AppAvatar(initials: appointment.patientInitials, size: 52, backgroundColor: appointment.avatarColor), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(appointment.patientName, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text('${appointment.age}  •  ${appointment.gender}', style: Theme.of(context).textTheme.bodyMedium)])), StatusBadge(label: appointment.statusLabel, color: appointment.statusColor)]), const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: _Meta(icon: Icons.calendar_month_outlined, value: appointment.date)), const SizedBox(width: AppSpacing.sm), Expanded(child: _Meta(icon: Icons.schedule_outlined, value: appointment.time))]), const SizedBox(height: AppSpacing.xs), _Meta(icon: Icons.medical_services_outlined, value: appointment.type), const SizedBox(height: AppSpacing.md), SizedBox(width: double.infinity, child: OutlinedButton(onPressed: onDetails, child: const Text('عرض التفاصيل')))]));
}
