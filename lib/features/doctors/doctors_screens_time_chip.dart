part of 'doctors_screens.dart';

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: selected ? AppColors.mint : AppColors.surface, borderRadius: BorderRadius.circular(11), border: Border.all(color: selected ? AppColors.primary : AppColors.border)),
          child: Text(label, style: TextStyle(color: selected ? AppColors.primaryDark : AppColors.ink, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      );
}
