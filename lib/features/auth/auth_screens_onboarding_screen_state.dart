part of 'auth_screens.dart';

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingData(
      title: 'رعايتك الصحية تبدأ بسهولة',
      description: 'الوصول إلى العيادات والخدمات الصحية أصبح أقرب وأبسط.',
      icon: Icons.favorite_outline_rounded,
      color: AppColors.mint,
    ),
    _OnboardingData(
      title: 'اعثر على طبيبك بثقة',
      description: 'اكتشف الأطباء واحجز موعدك المناسب في خطوات واضحة.',
      icon: Icons.medical_services_outlined,
      color: AppColors.sky,
    ),
    _OnboardingData(
      title: 'كل مواعيدك في مكان واحد',
      description: 'تابع مواعيدك ورحلة رعايتك الصحية بكل راحة.',
      icon: Icons.calendar_month_outlined,
      color: AppColors.peach,
    ),
  ];

  void _next() {
    if (_page == _pages.length - 1) {
      _openUserType();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  void _skip() => _openUserType();

  void _openUserType() {
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const UserTypeScreen()));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
            child: Column(children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(onPressed: _skip, child: const Text('تخطي')),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) => _OnboardingPage(data: _pages[index]),
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var index = 0; index < _pages.length; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _page ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(color: index == _page ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(8)),
                  ),
              ]),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(label: _page == _pages.length - 1 ? 'ابدأ الآن' : 'التالي', onPressed: _next, icon: Icons.arrow_back_rounded),
            ]),
          ),
        ),
      );
}
