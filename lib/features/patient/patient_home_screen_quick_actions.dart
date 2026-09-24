part of 'patient_home_screen.dart';

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onBook, required this.onClinics});
  final VoidCallback onBook;
  final VoidCallback onClinics;

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.55,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _QuickAction(label: 'مواعيدي', icon: Icons.event_available_outlined, color: AppColors.mint, onTap: onBook),
          _QuickAction(label: 'الأطباء', icon: Icons.medical_services_outlined, color: AppColors.sky, onTap: _noop),
          _QuickAction(label: 'مواعيدي', icon: Icons.event_available_outlined, color: AppColors.peach, onTap: _noop),
          _QuickAction(label: 'العيادات', icon: Icons.local_hospital_outlined, color: const Color(0xFFEDEAF7), onTap: onClinics),
        ],
      );

  static void _noop() {}
}
