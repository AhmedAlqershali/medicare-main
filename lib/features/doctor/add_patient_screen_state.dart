import 'package:flutter/material.dart';

import '../../core/auth/services/firebase_auth_repository.dart';
import '../../core/firestore/repositories/firestore_patient_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import '../auth/auth_widgets.dart';
import 'add_patient_screen.dart';

class AddPatientScreenState extends State<AddPatientScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _error;
  bool _success = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final doctorId = FirebaseAuthRepository.instance.session.doctorId;
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (_nameController.text.trim().isEmpty || !_isEmail(email)) {
      setState(() => _error = 'أدخل اسم المريض وبريداً إلكترونياً صحيحاً.');
      return;
    }
    if (doctorId == null) {
      setState(() => _error = 'لا يوجد طبيب نشط مرتبط بالجلسة الحالية.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirestorePatientRepository.instance.createPatient(doctorId: doctorId, organizationId: organizationId, name: _nameController.text.trim(), email: email, invitedBy: FirebaseAuthRepository.instance.session.currentUser?.id ?? '');
      if (mounted) setState(() => _success = true);
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isEmail(String value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Scaffold(appBar: AppBar(title: const Text('إضافة مريض')), body: SafeArea(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 64), const SizedBox(height: AppSpacing.lg), Text('تمت إضافة المريض بنجاح.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: AppSpacing.sm), Text('يمكن للمريض تفعيل الحساب لاحقاً باستخدام نفس البريد الإلكتروني الذي تم إدخاله.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: AppSpacing.xl), PrimaryButton(label: 'العودة إلى المرضى', onPressed: () => Navigator.of(context).pop())]))));
    }
    return AuthScaffold(showBack: true, title: 'إضافة مريض', subtitle: 'أضف المريض إلى قائمة عيادتك، وسيتم تفعيله لاحقاً باستخدام البريد نفسه', children: [CustomTextField(label: 'اسم المريض', prefixIcon: Icons.badge_outlined, controller: _nameController), const SizedBox(height: AppSpacing.md), CustomTextField(label: 'البريد الإلكتروني الشخصي', prefixIcon: Icons.email_outlined, controller: _emailController, keyboardType: TextInputType.emailAddress), if (_error != null) ...[const SizedBox(height: AppSpacing.sm), Text(_error!, style: const TextStyle(color: Color(0xFFC84C4C), fontWeight: FontWeight.w700))], const SizedBox(height: AppSpacing.xl), PrimaryButton(label: 'إضافة المريض', icon: Icons.person_add_alt_1_outlined, onPressed: _submit, isLoading: _loading)]);
  }
}
