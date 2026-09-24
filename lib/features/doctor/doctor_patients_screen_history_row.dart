part of 'doctor_patients_screen.dart';

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.date, required this.title, required this.status});
  final String date;
  final String title;
  final String status;

  @override
  Widget build(BuildContext context) => Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.event_available_outlined, color: AppColors.primary, size: 19)), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text(date, style: Theme.of(context).textTheme.bodyMedium)])), StatusBadge(label: status, color: AppColors.success)]);
}
