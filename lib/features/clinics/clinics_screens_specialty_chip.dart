part of 'clinics_screens.dart';

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(10)), child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 12)));
}
