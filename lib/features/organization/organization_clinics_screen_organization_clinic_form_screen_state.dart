part of 'organization_clinics_screen.dart';

class _OrganizationClinicFormScreenState extends State<OrganizationClinicFormScreen> {
  late final TextEditingController _nameController = TextEditingController(text: widget.clinic?.name ?? '');
  late final TextEditingController _locationController = TextEditingController(text: widget.clinic?.location ?? '');
  late final TextEditingController _phoneController = TextEditingController(text: widget.clinic?.phone ?? '');
  late final TextEditingController _descriptionController = TextEditingController(text: widget.clinic?.description ?? '');
  final Map<String, String> _errors = {};

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final errors = <String, String>{};
    if (_nameController.text.trim().isEmpty) errors['name'] = 'أدخل اسم العيادة';
    if (_locationController.text.trim().isEmpty) errors['location'] = 'أدخل الموقع';
    if (_phoneController.text.trim().isEmpty) errors['phone'] = 'أدخل رقم الهاتف';
    if (_descriptionController.text.trim().isEmpty) errors['description'] = 'أدخل وصفاً مختصراً';
    setState(() => _errors
      ..clear()
      ..addAll(errors));
    if (errors.isNotEmpty) return;

    final clinic = (widget.clinic ?? OrganizationClinic(id: 'clinic-${DateTime.now().millisecondsSinceEpoch}', name: '', location: '', phone: '', description: '', status: 'نشطة', doctorsCount: 0, departmentsCount: 0, patientsCount: 0, icon: Icons.local_hospital_rounded, color: AppColors.sky, departments: const []))
        .copyWith(
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
          phone: _phoneController.text.trim(),
          description: _descriptionController.text.trim(),
        );
    Navigator.of(context).pop(clinic);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.clinic == null ? 'إضافة عيادة' : 'تعديل العيادة')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(children: [
              CustomTextField(label: 'اسم العيادة', prefixIcon: Icons.local_hospital_outlined, controller: _nameController, errorText: _errors['name']),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'الموقع', prefixIcon: Icons.location_on_outlined, controller: _locationController, errorText: _errors['location']),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'رقم الهاتف', prefixIcon: Icons.phone_outlined, controller: _phoneController, errorText: _errors['phone'], keyboardType: TextInputType.phone),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'وصف مختصر', prefixIcon: Icons.description_outlined, controller: _descriptionController, errorText: _errors['description']),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(width: double.infinity, child: PrimaryButton(label: 'حفظ', icon: Icons.check_rounded, onPressed: _save)),
            ]),
          ),
        ),
      );
}
