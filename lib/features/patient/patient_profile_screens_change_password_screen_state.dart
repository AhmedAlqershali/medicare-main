part of 'patient_profile_screens.dart';

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final Map<String, String> _errors = {};
  bool _success = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final errors = <String, String>{};
    if (_currentController.text.isEmpty) errors['current'] = 'أدخل كلمة المرور الحالية';
    if (_newController.text.length < 6) errors['new'] = 'يجب أن تتكون من 6 أحرف على الأقل';
    if (_confirmController.text.isEmpty || _confirmController.text != _newController.text) errors['confirm'] = 'كلمتا المرور غير متطابقتين';
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
      _success = false;
    });
    if (errors.isNotEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      setState(() => _error = 'لا توجد جلسة Firebase نشطة.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final credential = EmailAuthProvider.credential(email: email, password: _currentController.text);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newController.text);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = true;
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message ?? 'تعذر تغيير كلمة المرور.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تغيير كلمة المرور')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(children: [
              CustomTextField(label: 'كلمة المرور الحالية', prefixIcon: Icons.lock_outline, controller: _currentController, obscureText: true, errorText: _errors['current'], textInputAction: TextInputAction.next),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'كلمة المرور الجديدة', prefixIcon: Icons.lock_reset_outlined, controller: _newController, obscureText: true, errorText: _errors['new'], textInputAction: TextInputAction.next),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'تأكيد كلمة المرور الجديدة', prefixIcon: Icons.verified_user_outlined, controller: _confirmController, obscureText: true, errorText: _errors['confirm'], textInputAction: TextInputAction.done),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: 'تغيير كلمة المرور', icon: Icons.check_rounded, onPressed: _changePassword, isLoading: _loading),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(color: Color(0xFFC84C4C), fontWeight: FontWeight.w700)),
              ],
              if (_success) ...[
                const SizedBox(height: AppSpacing.md),
                Text('تم تغيير كلمة المرور بنجاح.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
              ],
            ]),
          ),
        ),
      );
}
