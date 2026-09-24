part of 'patient_profile_screens.dart';

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final Map<String, bool> _settings = {'تذكيرات المواعيد': true, 'تحديثات المواعيد': true, 'التنبيهات العامة': false};

  @override
  Widget build(BuildContext context) => _ChoiceScreen(title: 'الإشعارات', child: Column(children: _settings.keys.map((title) => SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: Text(title), value: _settings[title]!, activeThumbColor: AppColors.primary, activeTrackColor: AppColors.primary.withValues(alpha: 0.5), onChanged: (value) => setState(() => _settings[title] = value))).toList()));
}
