part of 'doctor_appointments_screen.dart';

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, color: AppColors.primary, size: 17), const SizedBox(width: 6), Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)))]);
}
