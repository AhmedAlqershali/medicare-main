part of 'patient_profile_screens.dart';

class _AppearanceScreenState extends State<AppearanceScreen> {
  String _appearance = 'النظام';

  @override
  Widget build(BuildContext context) => _ChoiceScreen(title: 'المظهر', child: Column(children: ['النظام', 'فاتح', 'داكن'].map((appearance) => _SelectionTile(title: appearance, selected: _appearance == appearance, onTap: () => setState(() => _appearance = appearance))).toList()));
}
