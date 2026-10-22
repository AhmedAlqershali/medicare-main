part of 'organization_doctors_screen.dart';

class _OrganizationDoctorFormScreenState extends State<OrganizationDoctorFormScreen> {
  late final TextEditingController _nameController = TextEditingController(text: widget.doctor.name.replaceFirst('د. ', ''));
  late final TextEditingController _phoneController = TextEditingController(text: widget.doctor.phone);
  late final TextEditingController _emailController = TextEditingController(text: widget.doctor.email);
  List<MedicalCatalogEntry> _specialties = const [];
  List<MedicalCatalogEntry> _services = const [];
  MedicalCatalogEntry? _selectedSpecialty;
  late Set<String> _selectedServiceIds = widget.doctor.serviceIds.toSet();
  bool _specialtyChangedByUser = false;
  List<Map<String, dynamic>> _clinics = const [];
  String? _selectedClinicId;
  String? _clinicError;

  @override
  void initState() {
    super.initState();
    _selectedClinicId = widget.doctor.clinicId;
    _loadClinics();
    _loadSpecialties();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final entries = await FirestoreMedicalCatalogRepository.instance
          .fetchEntries(kind: MedicalCatalogKind.service);
      if (mounted) setState(() => _services = entries);
    } catch (error) {
      if (mounted) setState(() => _clinicError = error.toString());
    }
  }

  Future<void> _loadSpecialties() async {
    try {
      final entries = await FirestoreMedicalCatalogRepository.instance
          .fetchEntries(kind: MedicalCatalogKind.specialty);
      if (!mounted) return;
      setState(() {
        _specialties = entries;
        _selectedSpecialty = entries
            .where((entry) => entry.id == widget.doctor.specialtyId)
          .firstOrNull ??
          entries.where((entry) =>
            entry.nameAr.trim() ==
              displayDoctorSpecialty(context, widget.doctor.specialty).trim() ||
            entry.nameAr.trim() == widget.doctor.specialty.trim() ||
            entry.nameEn.trim().toLowerCase() ==
              widget.doctor.specialty.trim().toLowerCase()).firstOrNull;
      });
    } catch (error) {
      if (mounted) setState(() => _clinicError = error.toString());
    }
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
        specialty: _selectedSpecialty == null ||
            (widget.doctor.specialtyId == null && !_specialtyChangedByUser)
          ? widget.doctor.specialty
          : _selectedSpecialty!.displayName,
      specialtyId: _selectedSpecialty?.id ?? widget.doctor.specialtyId,
      serviceIds: _selectedServiceIds.toList(),
          serviceNames: _services.isEmpty
            ? widget.doctor.serviceNames
            : _services
              .where((service) => _selectedServiceIds.contains(service.id))
              .map((service) => service.displayName)
              .toList(),
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
              SearchableCatalogField(label: 'التخصص الأساسي', entries: _specialties, selectedId: _selectedSpecialty?.id, legacyValue: widget.doctor.specialtyId == null ? widget.doctor.specialty : null, onChanged: (entry) => setState(() {
                _selectedSpecialty = entry;
                _specialtyChangedByUser = true;
              })),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: Text('الخدمات التي يقدمها الطبيب', style: Theme.of(context).textTheme.titleSmall),
              ),
              if (_services.isEmpty)
                const ListTile(title: Text('لا توجد خدمات نشطة في الدليل بعد.'))
              else
                for (final service in _services)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _selectedServiceIds.contains(service.id),
                    title: Text(service.displayName),
                    subtitle: Text(
                      service.specialtyIds
                          .map((id) => _specialties.where((item) => item.id == id).firstOrNull?.displayName)
                          .whereType<String>()
                          .join('، '),
                    ),
                    onChanged: (selected) => setState(() {
                      if (selected == true) {
                        _selectedServiceIds.add(service.id);
                      } else {
                        _selectedServiceIds.remove(service.id);
                      }
                    }),
                  ),
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
