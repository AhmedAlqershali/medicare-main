part of 'doctor_profile_screens.dart';

class _DoctorEditProfileScreenState extends State<DoctorEditProfileScreen> {
  late final _nameController = TextEditingController(text: widget.profile.name);
  late final _specialtyController = TextEditingController(text: widget.profile.specialty);
  late final _clinicController = TextEditingController(text: widget.profile.clinic);
  late final _emailController = TextEditingController(text: widget.profile.email);
  late final _phoneController = TextEditingController(text: widget.profile.phone);

  @override
  void dispose() { _nameController.dispose(); _specialtyController.dispose(); _clinicController.dispose(); _emailController.dispose(); _phoneController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(
              children: [
                CustomTextField(label: 'اسم الطبيب', prefixIcon: Icons.badge_outlined, controller: _nameController),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(label: 'التخصص', prefixIcon: Icons.medical_information_outlined, controller: _specialtyController),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(label: 'العيادة', prefixIcon: Icons.local_hospital_outlined, controller: _clinicController),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(label: 'البريد الإلكتروني', prefixIcon: Icons.email_outlined, controller: _emailController, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(label: 'رقم الهاتف', prefixIcon: Icons.phone_outlined, controller: _phoneController, keyboardType: TextInputType.phone),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(label: 'حفظ التغييرات', icon: Icons.check_rounded, onPressed: _save),
                ),
              ],
            ),
          ),
        ),
      );

  void _save() => Navigator.of(context).pop(DoctorProfile(name: _nameController.text.trim(), specialty: _specialtyController.text.trim(), clinic: _clinicController.text.trim(), email: _emailController.text.trim(), phone: _phoneController.text.trim()));
}
