part of 'patient_profile_screens.dart';

class _ChoiceScreen extends StatelessWidget {
  const _ChoiceScreen({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)), body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl), child: child)));
}
