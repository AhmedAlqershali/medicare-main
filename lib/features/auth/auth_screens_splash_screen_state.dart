part of 'auth_screens.dart';

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();
    _navigationTimer = Timer(const Duration(milliseconds: 1500), _openOnboarding);
  }

  void _openOnboarding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()));
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const _BrandMark(size: 78),
                const SizedBox(height: AppSpacing.md),
                Text('Medicare', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 30, color: AppColors.primaryDark)),
                const SizedBox(height: AppSpacing.xs),
                Text('رعايتك الصحية، أقرب إليك', style: Theme.of(context).textTheme.bodyMedium),
              ]),
            ),
          ),
        ),
      );
}
