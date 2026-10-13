part of 'doctor_patients_screen.dart';

class DoctorPatientDetailsScreen extends StatefulWidget {
  const DoctorPatientDetailsScreen({super.key, required this.patient});
  final DoctorPatient patient;

  @override
  State<DoctorPatientDetailsScreen> createState() => _DoctorPatientDetailsScreenState();
}

class _DoctorPatientDetailsScreenState extends State<DoctorPatientDetailsScreen> {
  late DoctorPatient _patient = widget.patient;
  String _doctorName = '';
  String _clinicName = '';
  Map<String, List<String>> _availability = const {};

  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  Future<void> _loadReferences() async {
    try {
      final doctor = await FirestoreDoctorRepository.instance.fetchDoctorByIdForOrganization(_patient.organizationId, _patient.doctorId);
      final clinic = _patient.clinicId == null ? null : await FirestoreClinicRepository.instance.fetchClinicById(_patient.organizationId, _patient.clinicId!);
      final appointments = await FirestoreAppointmentRepository.instance.fetchAppointmentsForDoctor(organizationId: _patient.organizationId, doctorId: _patient.doctorId);
      final patientAppointments = appointments.where((appointment) => appointment['patientId'] == _patient.id).toList();
      if (!mounted) return;
      setState(() {
        _doctorName = doctor?.name ?? '';
        _clinicName = clinic?['name'] as String? ?? '';
        _availability = doctor?.availability ?? const {};
        _patient = _patient.copyWith(lastAppointment: patientAppointments.isEmpty ? '' : patientAppointments.last['date'] as String?);
      });
    } catch (_) {}
  }

  Future<void> _scheduleNextVisit() async {
    final availableDays = _availability.entries.where((entry) => entry.value.isNotEmpty).toList();
    if (availableDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد أوقات متاحة للطبيب.')));
      return;
    }
    var selectedDay = availableDays.first.key;
    var selectedTime = availableDays.first.value.first;
    final selection = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تحديد موعد زيارة قادمة'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: selectedDay,
              decoration: const InputDecoration(labelText: 'اليوم'),
              items: availableDays.map((entry) => DropdownMenuItem<String>(value: entry.key, child: Text(entry.key))).toList(),
              onChanged: (value) {
                if (value == null) return;
                setDialogState(() {
                  selectedDay = value;
                  selectedTime = _availability[value]!.first;
                });
              },
            ),
            DropdownButtonFormField<String>(
              value: selectedTime,
              decoration: const InputDecoration(labelText: 'الوقت'),
              items: (_availability[selectedDay] ?? const <String>[]).map((time) => DropdownMenuItem<String>(value: time, child: Text(time))).toList(),
              onChanged: (value) => setDialogState(() => selectedTime = value ?? selectedTime),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop({'date': selectedDay, 'time': selectedTime}), child: const Text('متابعة')),
          ],
        ),
      ),
    );
    if (selection == null || !mounted) return;
    final selectedDate = await _pickDateForWeekday(selection['date']!);
    if (selectedDate == null || !mounted) return;
    selection['date'] = selectedDate;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الموعد'),
        content: Text('تحديد موعد للمريض يوم ${selection['date']} في ${selection['time']}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final session = FirebaseAuthRepository.instance.session;
    if (session.doctorId != _patient.doctorId || session.organizationId != _patient.organizationId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن للطبيب تحديد موعد لمريض خارج نطاقه.')));
      return;
    }
    if (_patient.clinicId == null || _patient.clinicId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد عيادة مرتبطة بهذا المريض.')));
      return;
    }
    try {
      final appointments = await FirestoreAppointmentRepository.instance.fetchAppointmentsForDoctor(organizationId: _patient.organizationId, doctorId: _patient.doctorId);
      final conflict = appointments.any((appointment) => appointment['date'] == selection['date'] && appointment['time'] == selection['time'] && appointment['status'] != 'cancelled');
      if (conflict) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الوقت محجوز للطبيب بالفعل.')));
        return;
      }
      final appointment = <String, dynamic>{
        'patientId': _patient.id,
        'doctorId': _patient.doctorId,
        'clinicId': _patient.clinicId,
        'date': selection['date'],
        'time': selection['time'],
        'type': 'زيارة في العيادة',
        'status': 'upcoming',
        'doctorName': _doctorName,
        'clinicName': _clinicName,
      };
      if (_patient.firebaseUid != null && _patient.firebaseUid!.isNotEmpty) appointment['patientUid'] = _patient.firebaseUid;
      await FirestoreAppointmentRepository.instance.createAppointment(organizationId: _patient.organizationId, appointment: appointment);
      await _loadReferences();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديد موعد الزيارة بنجاح.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<String?> _pickDateForWeekday(String weekday) async {
    final initialDate = _nextDateForWeekday(weekday);
    final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: initialDate);
    if (picked == null) return null;
    if (_weekdayName(picked.weekday) != weekday) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('اختر تاريخًا يوافق يوم $weekday.')));
      return null;
    }
    return '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  DateTime _nextDateForWeekday(String weekday) {
    final today = DateTime.now();
    final target = _days.indexOf(weekday);
    if (target == -1) return today;
    final current = _days.indexOf(_weekdayName(today.weekday));
    final difference = (target - current) % 7;
    return DateTime(today.year, today.month, today.day).add(Duration(days: difference));
  }

  String _weekdayName(int weekday) => switch (weekday) {
        DateTime.saturday => 'السبت',
        DateTime.sunday => 'الأحد',
        DateTime.monday => 'الاثنين',
        DateTime.tuesday => 'الثلاثاء',
        DateTime.wednesday => 'الأربعاء',
        DateTime.thursday => 'الخميس',
        _ => 'الجمعة',
      };

  static const _days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

  Future<void> _editPatient() async {
    final nameController = TextEditingController(text: _patient.name);
    final phoneController = TextEditingController(text: _patient.phone);
    final birthDateController = TextEditingController(text: _patient.birthDate);
    final genderController = TextEditingController(text: _patient.gender);
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل بيانات المريض'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم')),
          TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'الهاتف')),
          TextField(controller: birthDateController, decoration: const InputDecoration(labelText: 'تاريخ الميلاد')),
          TextField(controller: genderController, decoration: const InputDecoration(labelText: 'الجنس')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop({'name': nameController.text.trim(), 'phone': phoneController.text.trim(), 'birthDate': birthDateController.text.trim(), 'gender': genderController.text.trim()}), child: const Text('حفظ')),
        ],
      ),
    );
    nameController.dispose();
    phoneController.dispose();
    birthDateController.dispose();
    genderController.dispose();
    if (result == null || !mounted) return;
    try {
      await FirestorePatientRepository.instance.updatePatientProfile(patientId: _patient.id, organizationId: _patient.organizationId, name: result['name']!, phone: result['phone']!, birthDate: result['birthDate']!, gender: result['gender']!);
      if (!mounted) return;
      setState(() => _patient = _patient.copyWith(name: result['name'], phone: result['phone'], gender: result['gender'], birthDate: result['birthDate'], age: _ageFromBirthDate(result['birthDate'])));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  String _ageFromBirthDate(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return '';
    final parsed = DateTime.tryParse(birthDate);
    if (parsed == null) return '';
    final today = DateTime.now();
    var age = today.year - parsed.year;
    if (today.month < parsed.month || (today.month == parsed.month && today.day < parsed.day)) age--;
    return age >= 0 ? '$age سنة' : '';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ملف المريض'), actions: [IconButton(onPressed: _editPatient, icon: const Icon(Icons.edit_outlined), tooltip: 'تعديل بيانات المريض')]),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Row(
                    children: [
                      AppAvatar(initials: _patient.initials, size: 72, backgroundColor: _patient.avatarColor),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_patient.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
                            const SizedBox(height: 5),
                            Text('${_patient.age}  •  ${_patient.gender}', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: AppSpacing.sm),
                            StatusBadge(label: _patient.status, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'المعلومات الأساسية'),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Column(
                    children: [
                      _InfoRow(label: 'العمر', value: _patient.age, icon: Icons.cake_outlined),
                      const Divider(height: AppSpacing.lg),
                      _InfoRow(label: 'تاريخ الميلاد', value: _patient.birthDate, icon: Icons.calendar_month_outlined),
                      const Divider(height: AppSpacing.lg),
                      _InfoRow(label: 'الجنس', value: _patient.gender, icon: Icons.person_outline),
                      const Divider(height: AppSpacing.lg),
                      _InfoRow(label: 'البريد الإلكتروني', value: _patient.email, icon: Icons.email_outlined),
                      const Divider(height: AppSpacing.lg),
                      _InfoRow(label: 'رقم الهاتف', value: _patient.phone, icon: Icons.phone_outlined),
                      const Divider(height: AppSpacing.lg),
                      _InfoRow(label: 'الطبيب', value: _doctorName.isEmpty ? 'غير متوفر' : _doctorName, icon: Icons.medical_information_outlined),
                      const Divider(height: AppSpacing.lg),
                      _InfoRow(label: 'العيادة', value: _clinicName.isEmpty ? 'غير متوفر' : _clinicName, icon: Icons.local_hospital_outlined),
                      const Divider(height: AppSpacing.lg),
                      _InfoRow(label: 'آخر موعد', value: _patient.lastAppointment, icon: Icons.calendar_month_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(width: double.infinity, child: PrimaryButton(label: 'تحديد موعد زيارة قادمة', icon: Icons.calendar_month_outlined, onPressed: _scheduleNextVisit)),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'المواعيد السابقة'),
                const SizedBox(height: AppSpacing.sm),
                if (_patient.lastAppointment.isEmpty)
                  const EmptyState(title: 'لا توجد مواعيد سابقة', message: 'ستظهر المواعيد هنا بعد تسجيلها.', icon: Icons.event_busy_outlined)
                else
                  AppCard(child: _HistoryRow(date: _patient.lastAppointment, title: 'موعد سابق', status: 'مكتمل')),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'الملاحظات'),
                const SizedBox(height: AppSpacing.sm),
                AppCard(child: Text(_patient.notes.isEmpty ? 'غير متوفر' : _patient.notes, style: Theme.of(context).textTheme.bodyLarge)),
              ],
            ),
          ),
        ),
      );
}
