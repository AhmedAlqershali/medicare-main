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
  List<MedicalNote> _medicalNotes = const [];
  List<Map<String, dynamic>> _patientAppointments = const [];
  bool _loadingNotes = true;
  bool _loadingReferences = true;
  bool _savingNote = false;
  bool _savingAppointment = false;
  String? _referenceError;
  String? _clinicId;

  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  Future<void> _loadReferences() async {
    if (!mounted) return;
    setState(() {
      _loadingReferences = true;
      _loadingNotes = true;
      _referenceError = null;
    });
    try {
      final doctor = await FirestoreDoctorRepository.instance.fetchDoctorByIdForOrganization(_patient.organizationId, _patient.doctorId);
        final patientClinicId = _patient.clinicId?.trim();
        final clinicId = patientClinicId != null && patientClinicId.isNotEmpty
          ? patientClinicId
          : doctor?.clinicId;
      final clinic = clinicId == null || clinicId.isEmpty
          ? null
          : await FirestoreClinicRepository.instance.fetchClinicById(_patient.organizationId, clinicId);
      final organization = clinic == null
          ? await FirestoreOrganizationRepository.instance.fetchOrganizationById(_patient.organizationId)
          : null;
      final appointments = await FirestoreAppointmentRepository.instance.fetchAppointmentsForDoctor(organizationId: _patient.organizationId, doctorId: _patient.doctorId);
      final patientAppointments = appointments.where((appointment) =>
          appointment['patientId'] == _patient.id &&
          appointment['doctorId'] == _patient.doctorId &&
          appointment['organizationId'] == _patient.organizationId).toList()
        ..sort((first, second) {
          final firstDate = _appointmentDateTime(first);
          final secondDate = _appointmentDateTime(second);
          if (firstDate == null) return secondDate == null ? 0 : 1;
          if (secondDate == null) return -1;
          return firstDate.compareTo(secondDate);
        });
      final medicalNotes = await FirestorePatientRepository.instance.getMedicalNotes(
        patientId: _patient.id,
        organizationId: _patient.organizationId,
      );
      if (!mounted) return;
        final previousAppointments = patientAppointments
          .where((appointment) =>
            _isPreviousAppointment(appointment) &&
            _appointmentDateTime(appointment) != null)
          .toList();
      final latestPrevious = previousAppointments.isEmpty ? null : previousAppointments.last;
      final clinicName = (clinic?['name'] as String? ?? '').trim();
      final doctorClinicName = (doctor?.clinic ?? '').trim();
      final organizationName = (organization?.name ?? '').trim();
      setState(() {
        _doctorName = doctor?.name ?? '';
        _clinicId = clinicId;
        _clinicName = clinicName.isNotEmpty
            ? clinicName
            : doctorClinicName.isNotEmpty
                ? doctorClinicName
                : organizationName;
        _availability = doctor?.availability ?? const {};
        _medicalNotes = medicalNotes;
        _loadingNotes = false;
        _patientAppointments = patientAppointments;
        _patient = _patient.copyWith(lastAppointment: latestPrevious == null ? '' : _appointmentLabel(latestPrevious));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _referenceError = error.toString();
        _loadingNotes = false;
      });
    } finally {
      if (mounted) setState(() => _loadingReferences = false);
    }
  }

  Future<void> _addMedicalNote() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة ملاحظة طبية'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'الملاحظة'),
            maxLines: 4,
            autofocus: true,
            onChanged: (_) => setDialogState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty || _savingNote
                  ? null
                  : () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (result == null || !mounted) return;
    setState(() => _savingNote = true);
    try {
      final session = FirebaseAuthRepository.instance.session;
      final note = await FirestorePatientRepository.instance.addMedicalNote(
        patientId: _patient.id,
        organizationId: _patient.organizationId,
        text: result,
        doctorUid: session.currentUser?.id ?? '',
        doctorName: session.currentUser?.name ?? '',
      );
      if (!mounted) return;
      setState(() => _medicalNotes = [note, ..._medicalNotes]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الملاحظة الطبية.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ الملاحظة الطبية: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  Future<void> _scheduleNextVisit() async {
    if (_savingAppointment) return;
    setState(() => _savingAppointment = true);
    try {
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
      if (_clinicId == null || _clinicId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد عيادة مرتبطة بهذا المريض.')));
        return;
      }
      final appointments = await FirestoreAppointmentRepository.instance.fetchAppointmentsForDoctor(organizationId: _patient.organizationId, doctorId: _patient.doctorId);
      final selectedDateTime = _appointmentDateTime({'date': selection['date'], 'time': selection['time']});
      if (selectedDateTime == null || !selectedDateTime.isAfter(DateTime.now())) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر تاريخًا ووقتًا قادمين.')));
        return;
      }
      final conflict = appointments.any((appointment) {
        if (appointment['status'] == 'cancelled') return false;
        final existingDateTime = _appointmentDateTime(appointment);
        return existingDateTime != null && existingDateTime == selectedDateTime;
      });
      if (conflict) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الوقت محجوز للطبيب بالفعل.')));
        return;
      }
      final appointment = <String, dynamic>{
        'patientId': _patient.id,
        'doctorId': _patient.doctorId,
        'clinicId': _clinicId,
        'date': selection['date'],
        'time': selection['time'],
        'type': 'زيارة في العيادة',
        'status': 'upcoming',
        'patientName': _patient.name,
        'patientInitials': _patient.initials,
        'age': _patient.age,
        'gender': _patient.gender,
        'doctorName': _doctorName,
        'clinicName': _clinicName,
        'notes': '',
      };
      if (_patient.firebaseUid != null && _patient.firebaseUid!.isNotEmpty) appointment['patientUid'] = _patient.firebaseUid;
      await FirestoreAppointmentRepository.instance.createAppointment(organizationId: _patient.organizationId, appointment: appointment);
      await _loadReferences();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديد موعد الزيارة بنجاح.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحديد الموعد: $error')));
    } finally {
      if (mounted) setState(() => _savingAppointment = false);
    }
  }

  DateTime? _appointmentDateTime(Map<String, dynamic> appointment) =>
      parseAppointmentDateTime(appointment['date'], appointment['time']);

  bool _isPreviousAppointment(Map<String, dynamic> appointment) {
    final status = appointment['status']?.toString().toLowerCase();
    final dateTime = _appointmentDateTime(appointment);
    return status == 'completed' || status == 'cancelled' || (dateTime != null && dateTime.isBefore(DateTime.now()));
  }

  String _appointmentLabel(Map<String, dynamic> appointment) {
    final dateTime = _appointmentDateTime(appointment);
    if (dateTime == null) return (appointment['date'] ?? '').toString();
    final date = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final time = (appointment['time'] ?? '').toString().trim();
    return time.isEmpty ? date : '$date • $time';
  }

  String _appointmentStatus(Map<String, dynamic> appointment) {
    final status = appointment['status']?.toString().toLowerCase();
    if (status == 'completed') return 'مكتمل';
    if (status == 'cancelled') return 'ملغي';
    final dateTime = _appointmentDateTime(appointment);
    if (dateTime != null && dateTime.isBefore(DateTime.now())) return 'سابق';
    if (dateTime != null && dateTime.year == DateTime.now().year && dateTime.month == DateTime.now().month && dateTime.day == DateTime.now().day) return 'اليوم';
    return 'قادم';
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
                      AppAvatar(initials: _patient.initials, name: _patient.name, size: 72, backgroundColor: _patient.avatarColor),
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
                      _InfoRow(label: 'مكان المشكلة / Condition', value: _patient.notes.trim().isEmpty ? 'غير محدد' : _patient.notes.trim(), icon: Icons.sticky_note_2_outlined),
                      const Divider(height: AppSpacing.lg),
                      _InfoRow(label: 'البريد الإلكتروني', value: _patient.email, icon: Icons.email_outlined),
                      const Divider(height: AppSpacing.lg),
                      _InfoRow(label: 'رقم الهاتف', value: _patient.phone, icon: Icons.phone_outlined),
                      const Divider(height: AppSpacing.lg),
                      _InfoRow(label: 'الطبيب', value: _doctorName.isEmpty ? 'غير متوفر' : _doctorName, icon: Icons.medical_information_outlined),
                      const Divider(height: AppSpacing.lg),
                      _InfoRow(label: 'العيادة / المؤسسة', value: _clinicName.isEmpty ? 'غير متوفر' : _clinicName, icon: Icons.local_hospital_outlined),
                      const Divider(height: AppSpacing.lg),
                      _InfoRow(label: 'آخر موعد', value: _patient.lastAppointment, icon: Icons.calendar_month_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_referenceError != null) ...[
                  Text('تعذر تحميل بعض بيانات الملف: $_referenceError', style: const TextStyle(color: Color(0xFFC84C4C), fontWeight: FontWeight.w700)),
                  TextButton.icon(onPressed: _loadReferences, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
                ],
                SizedBox(width: double.infinity, child: PrimaryButton(label: 'تحديد موعد زيارة قادمة', icon: Icons.calendar_month_outlined, onPressed: _savingAppointment ? null : _scheduleNextVisit, isLoading: _savingAppointment)),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'المواعيد القادمة'),
                const SizedBox(height: AppSpacing.sm),
                if (_loadingReferences)
                  const Center(child: CircularProgressIndicator())
                else if (_referenceError != null)
                  Text('تعذر تحميل المواعيد: $_referenceError', style: const TextStyle(color: Color(0xFFC84C4C)))
                else if (_patientAppointments.where((appointment) => !_isPreviousAppointment(appointment)).isEmpty)
                  const EmptyState(title: 'لا توجد مواعيد قادمة', message: 'ستظهر هنا المواعيد التي لم يحن موعدها بعد.', icon: Icons.event_available_outlined)
                else
                  for (final appointment in _patientAppointments.where((appointment) => !_isPreviousAppointment(appointment))) ...[
                    AppCard(child: _HistoryRow(date: _appointmentLabel(appointment), title: _patient.name, status: _appointmentStatus(appointment))),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'المواعيد السابقة'),
                const SizedBox(height: AppSpacing.sm),
                if (_loadingReferences)
                  const Center(child: CircularProgressIndicator())
                else if (_referenceError != null)
                  Text('تعذر تحميل المواعيد: $_referenceError', style: const TextStyle(color: Color(0xFFC84C4C)))
                else if (_patientAppointments.where(_isPreviousAppointment).isEmpty)
                  const EmptyState(title: 'لا توجد مواعيد سابقة', message: 'ستظهر المواعيد هنا بعد تسجيلها.', icon: Icons.event_busy_outlined)
                else
                  for (final appointment in _patientAppointments.where(_isPreviousAppointment).toList().reversed) ...[
                    AppCard(child: _HistoryRow(date: _appointmentLabel(appointment), title: _patient.name, status: _appointmentStatus(appointment))),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'الملاحظات طبية'),
                const SizedBox(height: AppSpacing.sm),
                if (_loadingNotes)
                  const Center(child: CircularProgressIndicator())
                else if (_referenceError != null)
                  Text('تعذر تحميل الملاحظات الطبية: $_referenceError', style: const TextStyle(color: Color(0xFFC84C4C)))
                else if (_medicalNotes.isEmpty)
                  const EmptyState(title: 'لا توجد ملاحظات', message: 'لا توجد ملاحظات طبية محفوظة لهذا المريض.', icon: Icons.sticky_note_2_outlined)
                else
                  for (final note in _medicalNotes) ...[
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event_outlined, size: 17),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(child: Text(
                                  '${note.createdAt.day.toString().padLeft(2, '0')}/${note.createdAt.month.toString().padLeft(2, '0')}/${note.createdAt.year.toString()} ${note.createdAt.hour.toString().padLeft(2, '0')}:${note.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                                )),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(note.text, style: Theme.of(context).textTheme.bodyLarge),
                            if (note.doctorName?.isNotEmpty ?? false) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text('بواسطة ${note.doctorName}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.muted)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                const SizedBox(height: AppSpacing.sm),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _loadingNotes || _savingNote || _referenceError != null ? null : _addMedicalNote, icon: const Icon(Icons.add_outlined), label: const Text('إضافة ملاحظة طبية'))),
              ],
            ),
          ),
        ),
      );
}
