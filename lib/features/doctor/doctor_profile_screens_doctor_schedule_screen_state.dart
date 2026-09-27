part of 'doctor_profile_screens.dart';

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  int _selectedDay = 0;

  static const _days = [
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  Map<String, List<String>> _availability = const {};
  Set<String> _bookedSlots = const {};

  String? _error;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final doctorId = FirebaseAuthRepository.instance.session.doctorId;
    final organizationId =
        FirebaseAuthRepository.instance.session.organizationId;

    if (doctorId == null ||
        doctorId.isEmpty ||
        organizationId == null ||
        organizationId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'لا توجد جلسة طبيب نشطة.';
      });

      return;
    }

    try {
      final doctor = await FirestoreDoctorRepository.instance
          .fetchDoctorByIdForOrganization(organizationId, doctorId);

      final appointments = await FirestoreAppointmentRepository.instance
          .fetchAppointmentsForDoctor(
            organizationId: organizationId,
            doctorId: doctorId,
          );

      if (!mounted) return;

      final loadedAvailability = <String, List<String>>{};

      for (final day in _days) {
        loadedAvailability[day] = [
          ...(doctor?.availability[day] ?? const <String>[]),
        ];
      }

      setState(() {
        _loading = false;
        _error = null;
        _availability = loadedAvailability;

        _bookedSlots = appointments
            .map(
              (appointment) =>
                  '${appointment['date'] ?? ''}|${appointment['time'] ?? ''}',
            )
            .toSet();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _editAvailability({String? day, String? slot}) async {
    final selectedDayIndex = day == null ? _selectedDay : _days.indexOf(day);

    final safeDayIndex = selectedDayIndex >= 0 ? selectedDayIndex : 0;

    var selectedDay = day ?? _days[safeDayIndex];

    final initialTimes = slot?.split(' - ') ?? const <String>[];

    var startTime = _parseTime(
      initialTimes.isNotEmpty ? initialTimes.first : '09:00',
    );

    var endTime = _parseTime(
      initialTimes.length > 1 ? initialTimes[1] : '10:00',
    );

    String? validationMessage;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(slot == null ? 'إضافة فترة' : 'تعديل الفترة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedDay,
                    decoration: const InputDecoration(labelText: 'اليوم'),
                    items: _days
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedDay = value;
                        validationMessage = null;
                      });
                    },
                  ),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('وقت البداية'),
                    trailing: Text(_formatTime(startTime)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: startTime,
                      );

                      if (picked == null) return;

                      setDialogState(() {
                        startTime = picked;
                        validationMessage = null;
                      });
                    },
                  ),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('وقت النهاية'),
                    trailing: Text(_formatTime(endTime)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: endTime,
                      );

                      if (picked == null) return;

                      setDialogState(() {
                        endTime = picked;
                        validationMessage = null;
                      });
                    },
                  ),

                  if (validationMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      validationMessage!,
                      style: const TextStyle(
                        color: Color(0xFFC84C4C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
                    final startMinutes = _minutes(startTime);

                    final endMinutes = _minutes(endTime);

                    final newSlot =
                        '${_formatTime(startTime)} - '
                        '${_formatTime(endTime)}';

                    if (startMinutes >= endMinutes) {
                      setDialogState(() {
                        validationMessage =
                            'يجب أن يكون وقت البداية قبل النهاية.';
                      });
                      return;
                    }

                    if (_hasOverlap(
                      day: selectedDay,
                      slot: slot,
                      startMinutes: startMinutes,
                      endMinutes: endMinutes,
                    )) {
                      setDialogState(() {
                        validationMessage =
                            'الفترة تتداخل مع فترة موجودة في اليوم نفسه.';
                      });
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop({'day': selectedDay, 'slot': newSlot});
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    final updatedAvailability = _copyAvailability();

    if (day != null && slot != null) {
      updatedAvailability[day]?.remove(slot);
    }

    updatedAvailability[result['day']!]!.add(result['slot']!);

    _sortAvailability(updatedAvailability);

    await _saveAvailability(updatedAvailability);
  }

  Future<void> _deleteAvailability(String day, String slot) async {
    if (_isBooked(day, slot)) {
      _showMessage('لا يمكن حذف فترة عليها موعد محجوز.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف الفترة'),
          content: Text('هل تريد حذف الفترة $slot من يوم $day؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final updatedAvailability = _copyAvailability();

    updatedAvailability[day]?.remove(slot);

    await _saveAvailability(updatedAvailability);
  }

  Future<void> _saveAvailability(
    Map<String, List<String>> updatedAvailability,
  ) async {
    final doctorId = FirebaseAuthRepository.instance.session.doctorId;

    final organizationId =
        FirebaseAuthRepository.instance.session.organizationId;

    if (doctorId == null ||
        doctorId.isEmpty ||
        organizationId == null ||
        organizationId.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await FirestoreDoctorRepository.instance.saveAvailability(
        organizationId: organizationId,
        doctorId: doctorId,
        availability: updatedAvailability,
      );

      if (!mounted) return;

      setState(() {
        _availability = updatedAvailability;
      });

      _showMessage('تم تحديث جدول الطبيب.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Map<String, List<String>> _copyAvailability() {
    return {
      for (final day in _days)
        day: [...(_availability[day] ?? const <String>[])],
    };
  }

  void _sortAvailability(Map<String, List<String>> availability) {
    for (final slots in availability.values) {
      slots.sort((a, b) {
        final aRange = a.split(' - ');
        final bRange = b.split(' - ');

        if (aRange.isEmpty || bRange.isEmpty) {
          return 0;
        }

        return _minutes(
          _parseTime(aRange.first),
        ).compareTo(_minutes(_parseTime(bRange.first)));
      });
    }
  }

  bool _hasOverlap({
    required String day,
    required String? slot,
    required int startMinutes,
    required int endMinutes,
  }) {
    for (final existingSlot in _availability[day] ?? const <String>[]) {
      if (existingSlot == slot) continue;

      final range = existingSlot.split(' - ');

      if (range.length != 2) continue;

      final existingStart = _minutes(_parseTime(range.first));

      final existingEnd = _minutes(_parseTime(range.last));

      if (startMinutes < existingEnd && endMinutes > existingStart) {
        return true;
      }
    }

    return false;
  }

  bool _isBooked(String day, String slot) {
    return _bookedSlots.contains('$day|$slot');
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.trim().split(':');

    final hour = int.tryParse(parts.first) ?? 9;

    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  int _minutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> get _selectedSlots {
    if (_selectedDay < 0 || _selectedDay >= _days.length) {
      return const [];
    }

    return _availability[_days[_selectedDay]] ?? const [];
  }

  String get _selectedDayName {
    return _days[_selectedDay];
  }

  int get _workingDays {
    return _days.where((day) => (_availability[day] ?? []).isNotEmpty).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جدول الطبيب')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة أيام وساعات عملك',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    if (_error != null) ...[
                      ErrorState(message: _error!, onRetry: _loadSchedule),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    SizedBox(
                      height: 82,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _days.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final day = _days[index];

                          final selected = _selectedDay == index;

                          final count = _availability[day]?.length ?? 0;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDay = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 82,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    day,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppColors.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$count',
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppColors.ink,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
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
                          Icon(
                            Icons.access_time_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '$_workingDays أيام عمل منشورة من أصل 7 أيام',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SectionHeader(title: 'الفترات المتاحة'),
                        FilledButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _editAvailability(day: _selectedDayName),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('إضافة'),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    if (_selectedSlots.isEmpty)
                      AppCard(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.event_available_outlined,
                              size: 40,
                              color: AppColors.muted,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'لا توجد فترات في $_selectedDayName',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'أضف فترة جديدة ليتمكن المرضى من حجز المواعيد.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final slot in _selectedSlots)
                            _ScheduleSlot(
                              time: slot,
                              booked: _isBooked(_selectedDayName, slot),
                              onEdit: _saving
                                  ? null
                                  : _isBooked(_selectedDayName, slot)
                                  ? null
                                  : () => _editAvailability(
                                      day: _selectedDayName,
                                      slot: slot,
                                    ),
                              onDelete: _saving
                                  ? null
                                  : () => _deleteAvailability(
                                      _selectedDayName,
                                      slot,
                                    ),
                            ),
                        ],
                      ),

                    const SizedBox(height: AppSpacing.lg),

                    if (_selectedSlots.isNotEmpty)
                      const Row(
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
  }
}
