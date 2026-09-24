part of 'appointment_booking_screens.dart';

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  int? _selectedDate;
  String? _selectedTime;
  Map<String, List<String>> _availableAvailability = const {};

  @override
  void initState() {
    super.initState();
    _availableAvailability = widget.bookingData.availability;
  }

  List<AppointmentDate> get _dates => _availableAvailability.keys.map(AppointmentDate.fromFirebase).toList();
  List<String> get _times => _dates.isEmpty ? const [] : _availableAvailability[_dates[_selectedDate ?? 0].label] ?? const [];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الأوقات المتاحة'), leading: const BackButton()),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _DoctorSummary(data: widget.bookingData),
              const SizedBox(height: AppSpacing.xl),
              Text('اختر التاريخ', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (_dates.isEmpty) const EmptyState(title: 'لا توجد مواعيد متاحة', message: 'لم يتم نشر أوقات توافر لهذا الطبيب بعد.') else SizedBox(
                height: 86,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dates.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) => _DateOption(
                    date: _dates[index],
                    selected: index == _selectedDate,
                    onTap: () => setState(() {
                      _selectedDate = index;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('اختر الوقت', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final time in _times)
                    _TimeOption(
                      label: time,
                      selected: time == _selectedTime,
                      unavailable: false,
                      onTap: () => setState(() {
                        _selectedTime = time;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const EmptyState(title: 'الموعد يحدده الطبيب', message: 'يمكنك عرض الأوقات المتاحة، وسيقوم الطبيب بتحديد موعد الزيارة من ملفك.'),
            ]),
          ),
        ),
      );

}
