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
  final _medicalNotesController = TextEditingController();

  DateTime? _appointmentDate;
  TimeOfDay? _appointmentTime;

  String? _selectedProblemLocation;

  String? _error;
  bool _success = false;
  bool _loading = false;

  static const List<Map<String, String>> _problemLocations = [
    {
      'value': 'head',
      'label': 'الرأس',
    },
    {
      'value': 'eye',
      'label': 'العين',
    },
    {
      'value': 'ear',
      'label': 'الأذن',
    },
    {
      'value': 'nose',
      'label': 'الأنف',
    },
    {
      'value': 'mouth_teeth',
      'label': 'الفم والأسنان',
    },
    {
      'value': 'neck',
      'label': 'الرقبة',
    },
    {
      'value': 'shoulder',
      'label': 'الكتف',
    },
    {
      'value': 'arm',
      'label': 'الذراع',
    },
    {
      'value': 'hand',
      'label': 'اليد',
    },
    {
      'value': 'chest',
      'label': 'الصدر',
    },
    {
      'value': 'abdomen',
      'label': 'البطن',
    },
    {
      'value': 'back',
      'label': 'الظهر',
    },
    {
      'value': 'pelvis',
      'label': 'الحوض',
    },
    {
      'value': 'thigh',
      'label': 'الفخذ',
    },
    {
      'value': 'knee',
      'label': 'الركبة',
    },
    {
      'value': 'leg',
      'label': 'الساق',
    },
    {
      'value': 'foot',
      'label': 'القدم',
    },
    {
      'value': 'sole_of_foot',
      'label': 'كف القدم',
    },
    {
      'value': 'other',
      'label': 'أخرى',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickAppointmentDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _appointmentDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('ar'),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _appointmentDate = selected;
      _error = null;
    });
  }

  Future<void> _pickAppointmentTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _appointmentTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _appointmentTime = selected;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final medicalNotes = _medicalNotesController.text.trim();

    final session = FirebaseAuthRepository.instance.session;

    final doctorId = session.doctorId;
    final organizationId = session.organizationId;

    if (name.isEmpty || !_isEmail(email)) {
      setState(() {
        _error = 'أدخل اسم المريض وبريداً إلكترونياً صحيحاً.';
      });
      return;
    }

    if (_appointmentDate == null) {
      setState(() {
        _error = 'حدد تاريخ الموعد القادم.';
      });
      return;
    }

    if (_appointmentTime == null) {
      setState(() {
        _error = 'حدد وقت الموعد القادم.';
      });
      return;
    }

    if (doctorId == null || doctorId.isEmpty) {
      setState(() {
        _error = 'لا يوجد طبيب نشط مرتبط بالجلسة الحالية.';
      });
      return;
    }

    if (organizationId == null || organizationId.isEmpty) {
      setState(() {
        _error = 'لا توجد مؤسسة مرتبطة بالجلسة الحالية.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirestorePatientRepository.instance.createPatient(
        doctorId: doctorId,
        organizationId: organizationId,
        name: name,
        email: email,
        invitedBy: session.currentUser?.id ?? '',
        appointmentDate: _appointmentDate!,
        appointmentTime: _appointmentTime!,
        problemLocation: _selectedProblemLocation,
        medicalNotes: medicalNotes.isEmpty ? null : medicalNotes,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _success = true;
      });
    } on StateError catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  bool _isEmail(String value) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(value);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.period == DayPeriod.am ? 'ص' : 'م';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إضافة مريض'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 64,
                ),
                const SizedBox(
                  height: AppSpacing.lg,
                ),
                Text(
                  'تمت إضافة المريض والموعد القادم بنجاح.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(
                  height: AppSpacing.sm,
                ),
                Text(
                  'يمكن للمريض تفعيل الحساب لاحقاً باستخدام نفس البريد الإلكتروني.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(
                  height: AppSpacing.xl,
                ),
                PrimaryButton(
                  label: 'العودة إلى المرضى',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AuthScaffold(
      showBack: true,
      title: 'إضافة مريض',
      subtitle: 'أضف المريض وحدد له موعد الزيارة القادمة',
      children: [
        CustomTextField(
          label: 'اسم المريض',
          prefixIcon: Icons.badge_outlined,
          controller: _nameController,
        ),

        const SizedBox(
          height: AppSpacing.md,
        ),

        CustomTextField(
          label: 'البريد الإلكتروني الشخصي',
          prefixIcon: Icons.email_outlined,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(
          height: AppSpacing.md,
        ),

        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'مكان المشكلة',
            prefixIcon: Icon(
              Icons.accessibility_new_outlined,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedProblemLocation,
              hint: const Text(
                'اختر مكان المشكلة',
              ),
              items: _problemLocations
                  .map(
                    (location) => DropdownMenuItem<String>(
                  value: location['value'],
                  child: Text(
                    location['label'] ?? '',
                  ),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProblemLocation = value;
                  _error = null;
                });
              },
            ),
          ),
        ),

        const SizedBox(
          height: AppSpacing.md,
        ),

        TextFormField(
          controller: _medicalNotesController,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            labelText: 'الملاحظات الطبية',
            prefixIcon: Icon(
              Icons.note_alt_outlined,
            ),
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(
          height: AppSpacing.lg,
        ),

        Text(
          'الموعد القادم',
          style: Theme.of(context).textTheme.titleSmall,
        ),

        const SizedBox(
          height: AppSpacing.sm,
        ),

        _AppointmentPickerButton(
          icon: Icons.calendar_today_outlined,
          label: _appointmentDate == null
              ? 'اختر تاريخ الموعد'
              : _formatDate(_appointmentDate!),
          onPressed: _pickAppointmentDate,
        ),

        const SizedBox(
          height: AppSpacing.md,
        ),

        _AppointmentPickerButton(
          icon: Icons.access_time_outlined,
          label: _appointmentTime == null
              ? 'اختر وقت الموعد'
              : _formatTime(_appointmentTime!),
          onPressed: _pickAppointmentTime,
        ),

        if (_error != null) ...[
          const SizedBox(
            height: AppSpacing.md,
          ),
          Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFFC84C4C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],

        const SizedBox(
          height: AppSpacing.xl,
        ),

        PrimaryButton(
          label: 'إضافة المريض وتحديد الموعد',
          icon: Icons.person_add_alt_1_outlined,
          onPressed: _submit,
          isLoading: _loading,
        ),
      ],
    );
  }
}

class _AppointmentPickerButton extends StatelessWidget {
  const _AppointmentPickerButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(
              width: AppSpacing.md,
            ),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
            ),
          ],
        ),
      ),
    );
  }
}