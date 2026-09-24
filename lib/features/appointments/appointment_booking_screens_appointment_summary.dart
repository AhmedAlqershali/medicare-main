part of 'appointment_booking_screens.dart';

class _AppointmentSummary extends StatelessWidget {
  const _AppointmentSummary({required this.data, required this.date, required this.time, required this.type, required this.notes});
  final AppointmentBookingData data;
  final AppointmentDate? date;
  final String? time;
  final String type;
  final String notes;

  @override
  Widget build(BuildContext context) => AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ملخص الموعد', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: AppSpacing.md), _SummaryLine(label: 'الطبيب', value: data.doctorName), _SummaryLine(label: 'التخصص', value: data.specialty), _SummaryLine(label: 'العيادة', value: data.clinicName), _SummaryLine(label: 'التاريخ', value: date == null ? 'لم يتم الاختيار' : '${date!.day} ${date!.number} ${date!.month}'), _SummaryLine(label: 'الوقت', value: time ?? 'لم يتم الاختيار'), _SummaryLine(label: 'نوع الموعد', value: type), if (notes.trim().isNotEmpty) _SummaryLine(label: 'الملاحظات', value: notes.trim())]));
}
