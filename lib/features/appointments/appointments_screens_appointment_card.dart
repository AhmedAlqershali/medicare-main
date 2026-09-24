part of 'appointments_screens.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, required this.appointment, required this.onDetails, this.onRebook});
  final AppointmentData appointment;
  final VoidCallback onDetails;
  final VoidCallback? onRebook;

  @override
  Widget build(BuildContext context) {
    final status = _statusDetails(appointment.status);
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        AppAvatar(initials: appointment.doctorInitials, size: 52, backgroundColor: appointment.avatarColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(appointment.doctorName, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text(appointment.specialty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600))])),
        StatusBadge(label: status.label, color: status.color),
      ]),
      const SizedBox(height: AppSpacing.md),
      _AppointmentMeta(icon: Icons.local_hospital_outlined, value: appointment.clinicName),
      const SizedBox(height: AppSpacing.xs),
      Row(children: [Expanded(child: _AppointmentMeta(icon: Icons.calendar_month_outlined, value: appointment.date)), const SizedBox(width: AppSpacing.sm), Expanded(child: _AppointmentMeta(icon: Icons.schedule_outlined, value: appointment.time))]),
      const SizedBox(height: AppSpacing.xs),
      _AppointmentMeta(icon: Icons.medical_services_outlined, value: appointment.type),
      const SizedBox(height: AppSpacing.md),
      Row(children: [Expanded(child: OutlinedButton(onPressed: onDetails, child: const Text('عرض التفاصيل'))), if (onRebook != null) ...[const SizedBox(width: AppSpacing.sm), Expanded(child: TextButton(onPressed: onRebook, child: const Text('إعادة الحجز')))]]),
    ]));
  }
}
