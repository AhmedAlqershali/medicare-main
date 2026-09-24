import 'package:flutter/material.dart';

import '../../core/auth/models/account_role.dart';
import '../../core/routing/auth_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import 'auth_widgets.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'invitation_activation_screen.dart';

class InvitationActivationScreenState extends State<InvitationActivationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (!email.contains('@') || password.length < 6 || (widget.role == AccountRole.organization && password != confirmPassword)) {
      setState(() => _error = widget.role == AccountRole.patient ? 'أدخل بريد المريض الصحيح وكلمة مرور من ٦ أحرف أو أكثر.' : 'أدخل البريد المدعو وكلمة مرور من ٦ أحرف أو أكثر.');
      if (widget.role == AccountRole.organization && password != confirmPassword) {
        setState(() => _error = 'كلمتا المرور غير متطابقتين.');
      }
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final result = widget.role == AccountRole.patient
          ? await AuthRepositoryImpl.instance.activatePatientAccount(email: email, password: password)
          : await AuthRepositoryImpl.instance.activateInvitation(role: widget.role, email: email, password: password);
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

  String get _title => switch (widget.role) {
        AccountRole.patient => 'تفعيل حساب المريض',
        AccountRole.doctor => 'تفعيل دعوة الطبيب',
        AccountRole.organization => 'تفعيل المؤسسة',
      };

  String get _subtitle => switch (widget.role) {
        AccountRole.patient => 'أدخل البريد الذي أضافه الطبيب ثم أنشئ كلمة مرور جديدة',
        AccountRole.doctor => 'استخدم البريد الإلكتروني المطابق للدعوة التي أرسلتها المؤسسة',
        AccountRole.organization => 'استخدم البريد الإلكتروني الخاص بالمؤسسة',
      };

  @override
  Widget build(BuildContext context) => AuthScaffold(
        showBack: true,
        title: _title,
        subtitle: _subtitle,
        children: [
          CustomTextField(label: widget.role == AccountRole.patient ? 'البريد الإلكتروني للمريض' : 'البريد الإلكتروني المدعو', prefixIcon: Icons.email_outlined, controller: _emailController, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
          const SizedBox(height: AppSpacing.md),
          CustomTextField(label: 'كلمة مرور جديدة', prefixIcon: Icons.lock_outline_rounded, controller: _passwordController, obscureText: true, textInputAction: TextInputAction.done, onSubmitted: (_) => _activate()),
          if (widget.role == AccountRole.organization) ...[
            const SizedBox(height: AppSpacing.md),
            CustomTextField(label: 'تأكيد كلمة المرور', prefixIcon: Icons.verified_user_outlined, controller: _confirmPasswordController, obscureText: true, textInputAction: TextInputAction.done, onSubmitted: (_) => _activate()),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: const TextStyle(color: Color(0xFFC84C4C), fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: widget.role == AccountRole.patient ? 'تفعيل الحساب' : 'تفعيل الحساب', icon: Icons.verified_user_outlined, onPressed: _activate, isLoading: _loading),
          const SizedBox(height: AppSpacing.md),
          Text(widget.role == AccountRole.patient ? 'لا يتم إرسال بريد فعلي. استخدم البريد نفسه الذي أضافه الطبيب.' : 'استخدم البريد الإلكتروني المرسل مع الدعوة لتنشيط الحساب في Firebase.', style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
}
