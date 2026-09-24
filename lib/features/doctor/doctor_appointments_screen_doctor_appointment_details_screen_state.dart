part of 'doctor_appointments_screen.dart';

class _DoctorAppointmentDetailsScreenState extends State<DoctorAppointmentDetailsScreen> {
  late DoctorAppointmentFilter _status = widget.appointment.status;
  late String _date = widget.appointment.date;
  late String _time = widget.appointment.time;
  bool _saving = false;

  Future<void> _saveStatus(DoctorAppointmentFilter status) async {
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (organizationId == null || organizationId.isEmpty || widget.appointment.id.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديد الموعد أو المؤسسة الحالية.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await FirestoreAppointmentRepository.instance.saveAppointment(
        organizationId: organizationId,
        appointment: {
          'id': widget.appointment.id,
          'status': switch (status) {
            DoctorAppointmentFilter.completed => 'completed',
            DoctorAppointmentFilter.cancelled => 'cancelled',
            _ => 'upcoming',
          },
        },
      );
      if (mounted) setState(() => _status = status);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reschedule() async {
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    final doctorId = FirebaseAuthRepository.instance.session.doctorId;
    if (organizationId == null || doctorId == null || organizationId.isEmpty || doctorId.isEmpty) return;
    try {
      final doctor = await FirestoreDoctorRepository.instance.fetchDoctorByIdForOrganization(organizationId, doctorId);
      final availableDays = doctor?.availability.entries.where((entry) => entry.value.isNotEmpty).toList() ?? const [];
      if (availableDays.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد أوقات متاحة للطبيب.')));
        return;
      }
      var selectedDay = availableDays.any((entry) => entry.key == _date) ? _date : availableDays.first.key;
      var selectedTime = (doctor!.availability[selectedDay] ?? const <String>[]).contains(_time) ? _time : doctor.availability[selectedDay]!.first;
      final selection = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('إعادة جدولة الموعد'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: selectedDay,
                decoration: const InputDecoration(labelText: 'اليوم'),
                items: availableDays.map((entry) => DropdownMenuItem<String>(value: entry.key, child: Text(entry.key))).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() {
                    selectedDay = value;
                    selectedTime = doctor.availability[value]!.first;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: selectedTime,
                decoration: const InputDecoration(labelText: 'الوقت'),
                items: (doctor.availability[selectedDay] ?? const <String>[]).map((time) => DropdownMenuItem<String>(value: time, child: Text(time))).toList(),
                onChanged: (value) => setDialogState(() => selectedTime = value ?? selectedTime),
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
              FilledButton(onPressed: () => Navigator.of(dialogContext).pop({'date': selectedDay, 'time': selectedTime}), child: const Text('حفظ')),
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
          title: const Text('تأكيد إعادة الجدولة'),
          content: Text('نقل الموعد إلى ${selection['date']} في ${selection['time']}؟'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('تأكيد')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final appointments = await FirestoreAppointmentRepository.instance.fetchAppointmentsForDoctor(organizationId: organizationId, doctorId: doctorId);
      final conflict = appointments.any((appointment) => appointment['id'] != widget.appointment.id && appointment['date'] == selection['date'] && appointment['time'] == selection['time'] && appointment['status'] != 'cancelled');
      if (conflict) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الوقت محجوز للطبيب بالفعل.')));
        return;
      }
      setState(() => _saving = true);
      await FirestoreAppointmentRepository.instance.saveAppointment(organizationId: organizationId, appointment: {'id': widget.appointment.id, 'date': selection['date'], 'time': selection['time']});
      if (mounted) setState(() {
        _date = selection['date']!;
        _time = selection['time']!;
      });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _pickDateForWeekday(String weekday) async {
    final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: DateTime.now());
    if (picked == null) return null;
    final names = {
      DateTime.saturday: 'السبت',
      DateTime.sunday: 'الأحد',
      DateTime.monday: 'الاثنين',
      DateTime.tuesday: 'الثلاثاء',
      DateTime.wednesday: 'الأربعاء',
      DateTime.thursday: 'الخميس',
      DateTime.friday: 'الجمعة',
    };
    if (names[picked.weekday] != weekday) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('اختر تاريخًا يوافق يوم $weekday.')));
      return null;
    }
    return '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment.copyWith(status: _status, date: _date, time: _time);
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الموعد')),
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
                    AppAvatar(initials: appointment.patientInitials, size: 68, backgroundColor: appointment.avatarColor),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appointment.patientName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
                          const SizedBox(height: 5),
                          Text('${appointment.age}  •  ${appointment.gender}', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _DoctorPatientPreviewScreen())),
                            child: const Text('عرض ملف المريض'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('معلومات الموعد', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  children: [
                    _DetailRow(label: 'التاريخ', value: appointment.date, icon: Icons.calendar_month_outlined),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(label: 'الوقت', value: appointment.time, icon: Icons.schedule_outlined),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(label: 'نوع الموعد', value: appointment.type, icon: Icons.medical_services_outlined),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(label: 'الحالة', value: appointment.statusLabel, icon: Icons.info_outline, valueColor: appointment.statusColor),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('ملاحظات الموعد', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(child: Text(appointment.notes, style: Theme.of(context).textTheme.bodyLarge)),
              if (_status == DoctorAppointmentFilter.today || _status == DoctorAppointmentFilter.upcoming) ...[
                const SizedBox(height: AppSpacing.xl),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _saving ? null : _reschedule, icon: const Icon(Icons.edit_calendar_outlined), label: const Text('إعادة جدولة الموعد'))),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'تأكيد الموعد',
                    icon: Icons.check_rounded,
                    onPressed: _saving ? null : () => _saveStatus(DoctorAppointmentFilter.upcoming),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => _saveStatus(DoctorAppointmentFilter.cancelled),
                        child: const Text('إلغاء الموعد'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _saveStatus(DoctorAppointmentFilter.completed),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('بدء الموعد'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}
