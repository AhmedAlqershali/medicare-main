part of 'doctor_profile_screens.dart';

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  int _selectedDay = 0;
  static const _days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
  Map<String, List<String>> _availability = const {};
  Set<String> _bookedSlots = const {};
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final doctorId = FirebaseAuthRepository.instance.session.doctorId;
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (doctorId == null || doctorId.isEmpty || organizationId == null || organizationId.isEmpty) {
      if (mounted) setState(() => _error = 'لا توجد جلسة طبيب نشطة.');
      return;
    }
    try {
        final doctor = await FirestoreDoctorRepository.instance.fetchDoctorByIdForOrganization(organizationId, doctorId);
        final appointments = await FirestoreAppointmentRepository.instance.fetchAppointmentsForDoctor(organizationId: organizationId, doctorId: doctorId);
      if (!mounted) return;
      setState(() {
        _availability = doctor?.availability ?? const {};
        _bookedSlots = appointments.map((appointment) => '${appointment['date'] ?? ''}|${appointment['time'] ?? ''}').toSet();
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _editAvailability({String? day, String? slot}) async {
    final initialTimes = slot?.split(' - ') ?? const <String>[];
    var selectedDay = day ?? _days.first;
    var startTime = _parseTime(initialTimes.isNotEmpty ? initialTimes.first : '09:00');
    var endTime = _parseTime(initialTimes.length > 1 ? initialTimes[1] : '10:00');
    String? validationMessage;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(slot == null ? 'إضافة وقت' : 'تعديل الوقت'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDay,
                decoration: const InputDecoration(labelText: 'اليوم'),
                items: _days.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                onChanged: (value) => setDialogState(() => selectedDay = value ?? selectedDay),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('وقت البداية'),
                trailing: Text(_formatTime(startTime)),
                onTap: () async {
                  final picked = await showTimePicker(context: dialogContext, initialTime: startTime);
                  if (picked != null) setDialogState(() => startTime = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('وقت النهاية'),
                trailing: Text(_formatTime(endTime)),
                onTap: () async {
                  final picked = await showTimePicker(context: dialogContext, initialTime: endTime);
                  if (picked != null) setDialogState(() => endTime = picked);
                },
              ),
              if (validationMessage != null) Text(validationMessage!, style: const TextStyle(color: Color(0xFFC84C4C))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                final startMinutes = _minutes(startTime);
                final endMinutes = _minutes(endTime);
                final newSlot = '${_formatTime(startTime)} - ${_formatTime(endTime)}';
                if (startMinutes >= endMinutes) {
                  setDialogState(() => validationMessage = 'يجب أن يكون وقت البداية قبل النهاية.');
                  return;
                }
                if (_hasOverlap(day: selectedDay, slot: slot, startMinutes: startMinutes, endMinutes: endMinutes)) {
                  setDialogState(() => validationMessage = 'الفترة تتداخل مع فترة موجودة في اليوم نفسه.');
                  return;
                }
                Navigator.of(dialogContext).pop({'day': selectedDay, 'slot': newSlot});
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    final updatedAvailability = _copyAvailability();
    if (day != null && slot != null) {
      updatedAvailability[day]?.remove(slot);
      if (updatedAvailability[day]?.isEmpty ?? false) updatedAvailability.remove(day);
    }
    updatedAvailability.putIfAbsent(result['day']!, () => <String>[]).add(result['slot']!);
    await _saveAvailability(updatedAvailability);
  }

  Future<void> _deleteAvailability(String day, String slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الفترة'),
        content: const Text('هل تريد حذف هذه الفترة من جدول الطبيب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final updatedAvailability = _copyAvailability();
    updatedAvailability[day]?.remove(slot);
    if (updatedAvailability[day]?.isEmpty ?? false) updatedAvailability.remove(day);
    await _saveAvailability(updatedAvailability);
  }

  Future<void> _saveAvailability(Map<String, List<String>> updatedAvailability) async {
    final doctorId = FirebaseAuthRepository.instance.session.doctorId;
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (doctorId == null || organizationId == null || doctorId.isEmpty || organizationId.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await FirestoreDoctorRepository.instance.saveAvailability(organizationId: organizationId, doctorId: doctorId, availability: updatedAvailability);
      if (!mounted) return;
      setState(() {
        _availability = updatedAvailability;
        _selectedDay = _availability.isEmpty ? 0 : _selectedDay.clamp(0, _availability.length - 1);
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, List<String>> _copyAvailability() => _availability.map((key, value) => MapEntry(key, [...value]));

  bool _hasOverlap({required String day, required String? slot, required int startMinutes, required int endMinutes}) {
    for (final existingSlot in _availability[day] ?? const <String>[]) {
      if (existingSlot == slot) continue;
      final range = existingSlot.split(' - ');
      if (range.length != 2) continue;
      final existingStart = _minutes(_parseTime(range.first));
      final existingEnd = _minutes(_parseTime(range.last));
      if (startMinutes < existingEnd && endMinutes > existingStart) return true;
    }
    return false;
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.trim().split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String _formatTime(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الجدول')),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('جدول مواعيدك لهذا الأسبوع', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.lg),
                if (_error != null) ErrorState(message: _error!, onRetry: _loadSchedule)
                else if (_availability.isEmpty) const EmptyState(title: 'لا يوجد جدول متاح', message: 'لم يتم نشر جدول لهذا الطبيب بعد.') else SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availability.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final selected = _selectedDay == index;
                      return InkWell(
                        onTap: () => setState(() => _selectedDay = index),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 76,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_availability.keys.elementAt(index), style: TextStyle(color: selected ? Colors.white : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('${_availability.values.elementAt(index).length}', style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontSize: 18, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'ساعات العمل'),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.access_time_outlined, color: AppColors.primary),
                      SizedBox(width: AppSpacing.sm),
                      Text('${_availability.length} أيام عمل منشورة', style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'الفترات المتاحة'),
                const SizedBox(height: AppSpacing.sm),
                Align(alignment: AlignmentDirectional.centerEnd, child: FilledButton.icon(onPressed: _saving ? null : () => _editAvailability(), icon: const Icon(Icons.add_rounded), label: const Text('إضافة وقت'))),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [for (final slot in _selectedSlots) _ScheduleSlot(time: slot, booked: _bookedSlots.contains('${_availability.keys.elementAt(_selectedDay)}|$slot'), onEdit: _saving ? null : () => _editAvailability(day: _availability.keys.elementAt(_selectedDay), slot: slot), onDelete: _saving ? null : () => _deleteAvailability(_availability.keys.elementAt(_selectedDay), slot))],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_selectedSlots.isNotEmpty) const Row(
                  children: [
                    _Legend(color: AppColors.primary, label: 'محجوز'),
                    SizedBox(width: AppSpacing.lg),
                    _Legend(color: AppColors.mint, label: 'متاح'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      List<String> get _selectedSlots => _availability.isEmpty ? const [] : _availability.values.elementAt(_selectedDay);
}
