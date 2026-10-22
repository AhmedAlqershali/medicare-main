  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';

  import '../../core/auth/services/firebase_auth_repository.dart';
  import '../../core/firestore/repositories/firestore_doctor_repository.dart';
  import '../../core/firestore/repositories/firestore_clinic_repository.dart';
  import '../../core/firestore/repositories/firestore_medical_catalog_repository.dart';
  import '../../core/auth/models/medical_catalog_entry.dart';
  import '../../core/theme/app_theme.dart';
  import '../../core/widgets/medicare_widgets.dart';
  import '../../core/widgets/searchable_catalog_field.dart';
  import '../auth/auth_widgets.dart';
  import 'add_doctor_screen.dart';

  class AddDoctorScreenState extends State<AddDoctorScreen> {
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    String? _error;
    bool _success = false;
    bool _loading = false;
    List<Map<String, dynamic>> _clinics = const [];
    List<MedicalCatalogEntry> _specialties = const [];
    MedicalCatalogEntry? _selectedSpecialty;
    String? _selectedClinicId;

    @override
    void initState() {
      super.initState();
      _loadClinics();
      _loadSpecialties();
    }

    Future<void> _loadSpecialties() async {
      try {
        final entries = await FirestoreMedicalCatalogRepository.instance
            .fetchEntries(kind: MedicalCatalogKind.specialty);
        if (mounted) setState(() => _specialties = entries);
      } catch (error) {
        if (mounted) setState(() => _error = error.toString());
      }
    }

    Future<void> _loadClinics() async {
      final organizationId = FirebaseAuthRepository.instance.session.organizationId;
      if (organizationId == null || organizationId.isEmpty) return;
      try {
        final clinics = await FirestoreClinicRepository.instance.fetchClinicsForOrganization(organizationId);
        if (mounted) setState(() => _clinics = clinics);
      } catch (error) {
        if (mounted) setState(() => _error = error.toString());
      }
    }

    @override
    void dispose() {
      _nameController.dispose();
      _emailController.dispose();
      super.dispose();
    }

    Future<void> _submit() async {
      final email = _emailController.text.trim();
      if (_nameController.text.trim().isEmpty || !_isEmail(email) || _selectedSpecialty == null || _selectedClinicId == null) {
        setState(() => _error = 'أدخل بيانات الطبيب واختر العيادة وبريداً إلكترونياً صحيحاً.');
        return;
      }
      final organizationId = FirebaseAuthRepository.instance.session.organizationId;
      final invitedBy = FirebaseAuth.instance.currentUser?.uid;
      if (organizationId == null || organizationId.isEmpty || invitedBy == null || invitedBy.isEmpty) {
        setState(() => _error = 'لا توجد مؤسسة نشطة مرتبطة بالجلسة الحالية.');
        return;
      }
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final clinic = _clinics.firstWhere((item) => item['id'] == _selectedClinicId);
        await FirestoreDoctorRepository.instance.inviteDoctor(organizationId: organizationId, name: _nameController.text.trim(), email: email, specialty: _selectedSpecialty!.displayName, specialtyId: _selectedSpecialty!.id, invitedBy: invitedBy, clinicId: _selectedClinicId, clinicName: clinic['name'] as String?);
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
        return Scaffold(appBar: AppBar(title: const Text('إضافة طبيب')), body: SafeArea(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 64), const SizedBox(height: AppSpacing.lg), Text('تمت إضافة الطبيب وحفظ الدعوة.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: AppSpacing.sm), Text('يمكن للطبيب تفعيل حسابه باستخدام البريد الإلكتروني المدعو.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: AppSpacing.xl), PrimaryButton(label: 'العودة إلى الأطباء', onPressed: () => Navigator.of(context).pop())]))));
      }
      return AuthScaffold(showBack: true, title: 'إضافة طبيب', subtitle: 'أضف الطبيب إلى مؤسستك وأنشئ دعوة', children: [CustomTextField(label: 'اسم الطبيب', prefixIcon: Icons.badge_outlined, controller: _nameController), const SizedBox(height: AppSpacing.md), CustomTextField(label: 'البريد الإلكتروني الشخصي', prefixIcon: Icons.email_outlined, controller: _emailController, keyboardType: TextInputType.emailAddress), const SizedBox(height: AppSpacing.md), SearchableCatalogField(label: 'التخصص الأساسي', entries: _specialties, selectedId: _selectedSpecialty?.id, onChanged: (entry) => setState(() => _selectedSpecialty = entry)), const SizedBox(height: AppSpacing.md), InputDecorator(decoration: const InputDecoration(labelText: 'العيادة', prefixIcon: Icon(Icons.local_hospital_outlined)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, value: _selectedClinicId, hint: const Text('اختر العيادة'), items: _clinics.map((clinic) => DropdownMenuItem<String>(value: clinic['id'] as String?, child: Text(clinic['name'] as String? ?? ''))).toList(), onChanged: (value) => setState(() => _selectedClinicId = value)))), if (_error != null) ...[const SizedBox(height: AppSpacing.sm), Text(_error!, style: const TextStyle(color: Color(0xFFC84C4C), fontWeight: FontWeight.w700))], const SizedBox(height: AppSpacing.xl), PrimaryButton(label: 'إضافة الطبيب', icon: Icons.person_add_alt_1_outlined, onPressed: _submit, isLoading: _loading)]);
    }
  }
