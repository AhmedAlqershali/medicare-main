part of 'appointment_booking_screens.dart';

class _DoctorSummary extends StatelessWidget {
  const _DoctorSummary({required this.data});
  final AppointmentBookingData data;

  @override
  Widget build(BuildContext context) => AppCard(child: Row(children: [AppAvatar(initials: data.doctorInitials, size: 62, backgroundColor: data.avatarColor), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data.doctorName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17)), const SizedBox(height: 4), Text(data.specialty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600)), const SizedBox(height: 5), Row(children: [const Icon(Icons.local_hospital_outlined, color: AppColors.muted, size: 15), const SizedBox(width: 4), Expanded(child: Text(data.clinicName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium))]), const SizedBox(height: 3), Row(children: [const Icon(Icons.location_on_outlined, color: AppColors.muted, size: 15), const SizedBox(width: 4), Expanded(child: Text(data.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium))])]))]));
}
