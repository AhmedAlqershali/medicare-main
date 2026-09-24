part of 'doctor_home_screen.dart';

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onTabSelected});
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: _Action(icon: Icons.calendar_month_outlined, label: 'مواعيدي', onTap: () => onTabSelected(1))),
        Expanded(child: _Action(icon: Icons.people_outline, label: 'المرضى', onTap: () => onTabSelected(2))),
        Expanded(child: _Action(icon: Icons.schedule_outlined, label: 'الجدول', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DoctorScheduleScreen())))),
        Expanded(child: _Action(icon: Icons.person_outline, label: 'الملف الشخصي', onTap: () => onTabSelected(3))),
      ]);
}
