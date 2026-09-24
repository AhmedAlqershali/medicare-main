import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/models/account_role.dart';
import '../../core/routing/auth_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import 'account_type_selection_screen.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'medicare_entry_screen.dart';
import 'models/auth_flow_stage.dart';
import 'role_login_screen.dart';

class MedicareEntryScreenState extends State<MedicareEntryScreen> {
  AuthFlowStage _stage = AuthFlowStage.splash;
  int _page = 0;
  Timer? _timer;

  static const _pages = [
    {'title': 'رعايتك الصحية تبدأ بسهولة', 'description': 'الوصول إلى العيادات والخدمات الصحية أصبح أقرب وأبسط.', 'icon': Icons.favorite_outline_rounded, 'color': AppColors.mint},
    {'title': 'اعثر على طبيبك بثقة', 'description': 'اكتشف الأطباء واحجز موعدك المناسب في خطوات واضحة.', 'icon': Icons.medical_services_outlined, 'color': AppColors.sky},
    {'title': 'كل مواعيدك في مكان واحد', 'description': 'تابع مواعيدك ورحلة رعايتك الصحية بكل راحة.', 'icon': Icons.calendar_month_outlined, 'color': AppColors.peach},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), _finishSplash);
  }

  void _finishSplash() {
    if (!mounted) return;
    if (AuthRepositoryImpl.instance.isAuthenticated) {
      final role = AuthRepositoryImpl.instance.currentRole;
      if (role != null) {
        AuthNavigation.openRoleHome(context, role);
        return;
      }
    }
    setState(() => _stage = AuthFlowStage.onboarding);
  }

  void _next() {
    if (_page == _pages.length - 1) {
      setState(() => _stage = AuthFlowStage.accountType);
      return;
    }
    setState(() => _page++);
  }

  void _openLogin(AccountRole role) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RoleLoginScreen(role: role)));

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == AuthFlowStage.splash) return _buildSplash(context);
    if (_stage == AuthFlowStage.accountType) return AccountTypeSelectionScreen(onSelected: _openLogin);
    return _buildOnboarding(context);
  }

  Widget _buildSplash(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 78, height: 78, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.add_rounded, color: Colors.white, size: 42)),
              const SizedBox(height: AppSpacing.md),
              Text('Medicare', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 30, color: AppColors.primaryDark)),
              const SizedBox(height: AppSpacing.xs),
              Text('رعايتك الصحية، أقرب إليك', style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
        ),
      );

  Widget _buildOnboarding(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
            child: Column(children: [
              Align(alignment: AlignmentDirectional.centerStart, child: TextButton(onPressed: () => setState(() => _stage = AuthFlowStage.accountType), child: const Text('تخطي'))),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: double.infinity, height: 250, decoration: BoxDecoration(color: _pages[_page]['color'] as Color, borderRadius: BorderRadius.circular(28)), child: Icon(_pages[_page]['icon'] as IconData, color: AppColors.primaryDark, size: 62)),
                  const SizedBox(height: AppSpacing.xl),
                  Text(_pages[_page]['title'] as String, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_pages[_page]['description'] as String, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
                ]),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var index = 0; index < _pages.length; index++) AnimatedContainer(duration: const Duration(milliseconds: 220), margin: const EdgeInsets.symmetric(horizontal: 3), width: index == _page ? 22 : 7, height: 7, decoration: BoxDecoration(color: index == _page ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(8)))]),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(label: _page == _pages.length - 1 ? 'ابدأ الآن' : 'التالي', onPressed: _next, icon: Icons.arrow_back_rounded),
            ]),
          ),
        ),
      );
}
