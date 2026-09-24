part of 'patient_profile_screens.dart';

class _EditPatientProfileScreenState extends State<EditPatientProfileScreen> {
  late final TextEditingController _nameController = TextEditingController(text: widget.patient.name);
  late final TextEditingController _phoneController = TextEditingController(text: widget.patient.phone);
  late final TextEditingController _emailController = TextEditingController(text: widget.patient.email);
  late final TextEditingController _birthDateController = TextEditingController(text: widget.patient.birthDate);
  late String _gender = widget.patient.gender;
  final Map<String, String> _errors = {};

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _save() {
    final errors = <String, String>{};
    if (_nameController.text.trim().isEmpty) errors['name'] = 'أدخل الاسم الكامل';
    if (_phoneController.text.trim().isEmpty) errors['phone'] = 'أدخل رقم الهاتف';
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) errors['email'] = 'أدخل بريداً إلكترونياً صحيحاً';
    if (_birthDateController.text.trim().isEmpty) errors['birthDate'] = 'أدخل تاريخ الميلاد';
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;

    Navigator.of(context).pop(PatientProfile(name: _nameController.text.trim(), phone: _phoneController.text.trim(), email: _emailController.text.trim(), birthDate: _birthDateController.text.trim(), gender: _gender));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('حدّث معلوماتك لتبقى بياناتك الصحية محدثة.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              CustomTextField(label: 'الاسم الكامل', prefixIcon: Icons.badge_outlined, controller: _nameController, errorText: _errors['name'], textInputAction: TextInputAction.next),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'رقم الهاتف', prefixIcon: Icons.phone_outlined, controller: _phoneController, errorText: _errors['phone'], keyboardType: TextInputType.phone, textInputAction: TextInputAction.next),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'البريد الإلكتروني', prefixIcon: Icons.email_outlined, controller: _emailController, errorText: _errors['email'], keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, readOnly: true),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'تاريخ الميلاد', hintText: 'مثال: ١٥ مايو ١٩٩٦', prefixIcon: Icons.cake_outlined, controller: _birthDateController, errorText: _errors['birthDate'], textInputAction: TextInputAction.next),
              const SizedBox(height: AppSpacing.lg),
              Text('الجنس', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(spacing: AppSpacing.sm, children: ['أنثى', 'ذكر'].map((gender) => ChoiceChip(label: Text(gender), selected: _gender == gender, onSelected: (_) => setState(() => _gender = gender))).toList()),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: 'حفظ التغييرات', icon: Icons.check_rounded, onPressed: _save),
            ]),
          ),
        ),
      );
}
