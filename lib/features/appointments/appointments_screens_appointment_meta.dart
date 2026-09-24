part of 'appointments_screens.dart';

class _AppointmentMeta extends StatelessWidget {
  const _AppointmentMeta({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, color: AppColors.primary, size: 17), const SizedBox(width: 6), Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)))]);
}
