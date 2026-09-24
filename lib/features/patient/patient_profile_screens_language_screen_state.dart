part of 'patient_profile_screens.dart';

class _LanguageScreenState extends State<LanguageScreen> {
  String _language = 'العربية';

  @override
  Widget build(BuildContext context) => _ChoiceScreen(title: 'لغة التطبيق', child: Column(children: ['العربية', 'English'].map((language) => _SelectionTile(title: language, selected: _language == language, onTap: () => setState(() => _language = language))).toList()));
}
