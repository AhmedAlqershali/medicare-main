part of 'auth_screens.dart';

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});
  final _OnboardingData data;

  @override
  Widget build(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(color: data.color, borderRadius: BorderRadius.circular(28)),
          child: Stack(alignment: Alignment.center, children: [
            PositionedDirectional(top: 24, end: 28, child: Icon(Icons.add_rounded, color: AppColors.primary.withValues(alpha: .14), size: 54)),
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), shape: BoxShape.circle),
              child: Icon(data.icon, color: AppColors.primaryDark, size: 54),
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(data.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 310),
          child: Text(data.description, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
        ),
      ]);
}
