part of 'auth_widgets.dart';

class AuthPrompt extends StatelessWidget {
  const AuthPrompt({super.key, required this.label, required this.action, required this.onPressed});
  final String label;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        TextButton(onPressed: onPressed, child: Text(action)),
      ]);
}
