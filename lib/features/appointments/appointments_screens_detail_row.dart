part of 'appointments_screens.dart';

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, required this.icon, this.valueColor});
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: AppColors.primary, size: 19)), const SizedBox(width: AppSpacing.sm), Text('$label: ', style: Theme.of(context).textTheme.bodyMedium), Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: valueColor ?? AppColors.ink, fontWeight: FontWeight.w700)))]);
}
