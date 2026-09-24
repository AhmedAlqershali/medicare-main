part of 'patient_profile_screens.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) => _ChoiceScreen(title: 'المساعدة والدعم', child: Column(children: [
        _NavigationTile(icon: Icons.quiz_outlined, title: 'الأسئلة الشائعة', onTap: () => _showMessage(context, 'ستجد هنا إجابات عن أكثر الأسئلة شيوعاً.')),
        _NavigationTile(icon: Icons.mail_outline, title: 'تواصل معنا', onTap: () => _showMessage(context, 'يمكنك التواصل مع فريق Medicare من خلال هذه الواجهة قريباً.')),
        _NavigationTile(icon: Icons.report_problem_outlined, title: 'الإبلاغ عن مشكلة', onTap: () => _showMessage(context, 'يرجى التواصل مع إدارة المؤسسة للإبلاغ عن المشكلة.')),
      ]));

  static void _showMessage(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
