part of 'organization_profile_screens.dart';

class _OrganizationProfileFormScreenState extends State<OrganizationProfileFormScreen> {
  late final TextEditingController _nameController = TextEditingController(text: widget.profile.name);
  late final TextEditingController _emailController = TextEditingController(text: widget.profile.email);
  late final TextEditingController _phoneController = TextEditingController(text: widget.profile.phone);
  late final TextEditingController _locationController = TextEditingController(text: widget.profile.location);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = OrganizationProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      location: _locationController.text.trim(),
      clinicsCount: widget.profile.clinicsCount,
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تعديل الملف')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(children: [
              CustomTextField(label: 'اسم المؤسسة', prefixIcon: Icons.business_outlined, controller: _nameController),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'البريد الإلكتروني', prefixIcon: Icons.email_outlined, controller: _emailController, readOnly: true, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'رقم الهاتف', prefixIcon: Icons.phone_outlined, controller: _phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'الموقع', prefixIcon: Icons.location_on_outlined, controller: _locationController),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(width: double.infinity, child: PrimaryButton(label: 'حفظ', icon: Icons.check_rounded, onPressed: _save)),
            ]),
          ),
        ),
      );
}
