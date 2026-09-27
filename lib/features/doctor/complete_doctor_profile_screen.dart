import 'package:flutter/material.dart';

import '../../core/auth/services/firebase_auth_repository.dart';
import '../../core/firestore/repositories/firestore_doctor_repository.dart';
import '../../core/theme/app_theme.dart';

class CompleteDoctorProfileScreen extends StatefulWidget {
  const CompleteDoctorProfileScreen({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<CompleteDoctorProfileScreen> createState() =>
      _CompleteDoctorProfileScreenState();
}

class _CompleteDoctorProfileScreenState
    extends State<CompleteDoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();

  String? _gender;

  bool _loading = true;
  bool _saving = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final session = FirebaseAuthRepository.instance.session;

      final organizationId = session.organizationId;

      final doctorId = session.doctorId;

      if (organizationId == null || organizationId.isEmpty) {
        throw StateError('لا توجد مؤسسة مرتبطة بحساب الطبيب.');
      }

      if (doctorId == null || doctorId.isEmpty) {
        throw StateError('لا توجد هوية طبيب مرتبطة بالحساب.');
      }

      final doctor = await FirestoreDoctorRepository.instance.fetchDoctorById(
        doctorId,
        organizationId: organizationId,
      );

      if (doctor == null) {
        throw StateError('لم يتم العثور على سجل الطبيب.');
      }

      if (!mounted) return;

      setState(() {
        _phoneController.text = doctor.phone;
        _birthDateController.text = doctor.birthDate;

        final gender = doctor.gender.trim().toLowerCase();

        if (gender == 'male' || gender == 'ذكر') {
          _gender = 'male';
        } else if (gender == 'female' || gender == 'أنثى') {
          _gender = 'female';
        } else {
          _gender = null;
        }

        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    DateTime initialDate = DateTime(now.year - 30, now.month, now.day);

    final existingDate = DateTime.tryParse(_birthDateController.text.trim());

    if (existingDate != null) {
      initialDate = existingDate;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'اختر تاريخ الميلاد',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (selected == null) return;

    final formatted =
        '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';

    setState(() {
      _birthDateController.text = formatted;
      _error = null;
    });
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_gender == null || _gender!.isEmpty) {
      setState(() {
        _error = 'يرجى اختيار الجنس.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final session = FirebaseAuthRepository.instance.session;

      final organizationId = session.organizationId;

      final doctorId = session.doctorId;

      if (organizationId == null || organizationId.isEmpty) {
        throw StateError('لا توجد مؤسسة مرتبطة بحساب الطبيب.');
      }

      if (doctorId == null || doctorId.isEmpty) {
        throw StateError('لا توجد هوية طبيب مرتبطة بالحساب.');
      }

      await FirestoreDoctorRepository.instance.updateDoctorProfile(
        doctorId: doctorId,
        organizationId: organizationId,
        phone: _phoneController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        gender: _gender!,
      );

      if (!mounted) return;

      widget.onCompleted();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('استكمال بيانات الطبيب'),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.lg),

                        Icon(
                          Icons.medical_services_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        Text(
                          'أكمل بياناتك',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        Text(
                          'أكمل البيانات المطلوبة قبل المتابعة إلى حساب الطبيب.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف',
                            hintText: 'مثال: 059xxxxxxx',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'رقم الهاتف مطلوب';
                            }

                            if (value.trim().length < 7) {
                              return 'أدخل رقم هاتف صحيح';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.md),

                        TextFormField(
                          controller: _birthDateController,
                          readOnly: true,
                          onTap: _saving ? null : _selectBirthDate,
                          decoration: const InputDecoration(
                            labelText: 'تاريخ الميلاد',
                            hintText: 'اختر تاريخ الميلاد',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'تاريخ الميلاد مطلوب';
                            }

                            if (DateTime.tryParse(value.trim()) == null) {
                              return 'تاريخ الميلاد غير صحيح';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.md),

                        DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration: const InputDecoration(
                            labelText: 'الجنس',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'male', child: Text('ذكر')),
                            DropdownMenuItem(
                              value: 'female',
                              child: Text('أنثى'),
                            ),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) {
                                  setState(() {
                                    _gender = value;
                                    _error = null;
                                  });
                                },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الجنس مطلوب';
                            }

                            return null;
                          },
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xl),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _saveProfile,
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('حفظ والمتابعة'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
