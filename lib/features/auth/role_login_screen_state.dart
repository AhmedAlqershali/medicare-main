import 'package:flutter/material.dart';

import '../../core/auth/models/account_role.dart';
import '../../core/routing/auth_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import 'auth_widgets.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'invitation_activation_screen.dart';
import 'role_login_screen.dart';

class RoleLoginScreenState extends State<RoleLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'أدخل البريد الإلكتروني وكلمة المرور.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AuthRepositoryImpl.instance.login(role: widget.role, email: _emailController.text, password: _passwordController.text);
      if (!mounted) return;
      setState(() => _loading = false);
      if (!result.success) {
        setState(() => _error = result.message);
        return;
      }
      AuthNavigation.openRoleHome(context, widget.role);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
      return;
    }
  }

  void _createAccount() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => InvitationActivationScreen(role: widget.role)));
  }

  String get _title => switch (widget.role) {
        AccountRole.patient => 'دخول المريض',
        AccountRole.doctor => 'دخول الطبيب',
        AccountRole.organization => 'دخول المؤسسة الطبية',
      };

  String get _createLabel => switch (widget.role) {
        AccountRole.patient => 'تفعيل حساب المريض',
        AccountRole.doctor => 'تفعيل دعوة الطبيب',
        AccountRole.organization => 'تسجيل المؤسسة',
      };

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      title: _title,
      subtitle: 'أدخل بيانات الحساب المرتبط بدورك في Medicare',
      children: [
        CustomTextField(label: 'البريد الإلكتروني', prefixIcon: Icons.email_outlined, controller: _emailController, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(label: 'كلمة المرور', prefixIcon: Icons.lock_outline_rounded, controller: _passwordController, obscureText: true, textInputAction: TextInputAction.done, onSubmitted: (_) => _login()),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error!, style: const TextStyle(color: Color(0xFFC84C4C), fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: AppSpacing.sm),
        Align(alignment: AlignmentDirectional.centerStart, child: TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('استعادة كلمة المرور متاحة عبر Firebase Authentication أو فريق الإدارة.'))), child: const Text('نسيت كلمة المرور؟'))),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(label: 'تسجيل الدخول', icon: Icons.login_rounded, onPressed: _login, isLoading: _loading),
        const SizedBox(height: AppSpacing.lg),
        AuthPrompt(label: 'لا تملك حساباً مفعلاً؟', action: _createLabel, onPressed: _createAccount),
      ],
    );
  }
}
