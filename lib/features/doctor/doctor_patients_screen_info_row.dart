part of 'doctor_patients_screen.dart';

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, color: AppColors.primary, size: 20), const SizedBox(width: AppSpacing.sm), Text(label, style: Theme.of(context).textTheme.bodyMedium), const Spacer(), Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700))]);
}
