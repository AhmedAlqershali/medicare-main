part of 'organization_doctors_screen.dart';

class _OrganizationDoctorFormScreenState extends State<OrganizationDoctorFormScreen> {
  late final TextEditingController _nameController = TextEditingController(text: widget.doctor.name.replaceFirst('د. ', ''));
  late final TextEditingController _specialtyController = TextEditingController(text: widget.doctor.specialty);
  late final TextEditingController _phoneController = TextEditingController(text: widget.doctor.phone);
  late final TextEditingController _emailController = TextEditingController(text: widget.doctor.email);
  List<Map<String, dynamic>> _clinics = const [];
  String? _selectedClinicId;
  String? _clinicError;

  List<String> get _specialtyOptions {
    final current = _specialtyController.text.trim();
    return current.isNotEmpty && !doctorSpecialties.contains(current)
        ? [current, ...doctorSpecialties]
        : doctorSpecialties;
  }

  @override
  void initState() {
    super.initState();
    _selectedClinicId = widget.doctor.clinicId;
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (organizationId == null || organizationId.isEmpty) return;
    try {
      final clinics = await FirestoreClinicRepository.instance.fetchClinicsForOrganization(organizationId);
      if (!mounted) return;
      setState(() {
        _clinics = clinics;
        _selectedClinicId ??= clinics.where((clinic) => clinic['name'] == widget.doctor.clinic).map((clinic) => clinic['id'] as String?).firstOrNull;
      });
    } catch (error) {
      if (mounted) setState(() => _clinicError = error.toString());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    final selectedClinic = _clinics.where((clinic) => clinic['id'] == _selectedClinicId).firstOrNull;
    if (selectedClinic == null) {
      setState(() => _clinicError = 'اختر عيادة موجودة ضمن المؤسسة الحالية.');
      return;
    }
    final updated = widget.doctor.copyWith(
      name: 'د. ${_nameController.text.trim()}',
      specialty: _specialtyController.text.trim(),
      clinic: selectedClinic['name'] as String? ?? '',
      clinicId: selectedClinic['id'] as String,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تعديل بيانات الطبيب')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(children: [
              CustomTextField(label: 'اسم الطبيب', prefixIcon: Icons.badge_outlined, controller: _nameController),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(value: _specialtyOptions.contains(_specialtyController.text) ? _specialtyController.text : null, decoration: const InputDecoration(labelText: 'التخصص', prefixIcon: Icon(Icons.medical_information_outlined)), items: _specialtyOptions.map((specialty) => DropdownMenuItem(value: specialty, child: Text(specialty))).toList(), onChanged: (value) => setState(() => _specialtyController.text = value ?? '')),
              const SizedBox(height: AppSpacing.md),
              InputDecorator(decoration: InputDecoration(labelText: 'العيادة', prefixIcon: const Icon(Icons.local_hospital_outlined), errorText: _clinicError), child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, value: _selectedClinicId, hint: const Text('اختر العيادة'), items: _clinics.map((clinic) => DropdownMenuItem<String>(value: clinic['id'] as String?, child: Text(clinic['name'] as String? ?? ''))).toList(), onChanged: (value) => setState(() => _selectedClinicId = value)))),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'رقم الهاتف', prefixIcon: Icons.phone_outlined, controller: _phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'البريد الإلكتروني', prefixIcon: Icons.email_outlined, controller: _emailController, readOnly: true, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(width: double.infinity, child: PrimaryButton(label: 'حفظ', icon: Icons.check_rounded, onPressed: _save)),
            ]),
          ),
        ),
      );
}
