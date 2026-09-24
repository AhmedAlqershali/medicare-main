part of 'patient_profile_screens.dart';

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({required this.title, required this.selected, required this.onTap});
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(padding: EdgeInsets.zero, child: ListTile(onTap: onTap, title: Text(title), trailing: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off_outlined, color: selected ? AppColors.primary : AppColors.muted)));
}
