part of 'doctors_screens.dart';

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  int _selectedDate = 0;
  String? _selectedTime;

  List<String> get _dates => widget.doctor.availability.keys.toList();
  List<String> get _times => _dates.isEmpty ? const [] : widget.doctor.availability[_dates[_selectedDate]] ?? const [];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('ملف الطبيب'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppCard(
                child: Row(children: [
                  AppAvatar(initials: widget.doctor.initials, size: 70, backgroundColor: widget.doctor.color),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.doctor.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(widget.doctor.specialty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 7),
                    Row(children: [
                      const Icon(Icons.star_rounded, color: AppColors.warning, size: 17),
                      const SizedBox(width: 4),
                      Text('${widget.doctor.rating}  •  ${widget.doctor.reviews} تقييم', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ]),
                  ])),
                ]),
              ),
              const SizedBox(height: AppSpacing.lg),
              _InfoLine(icon: Icons.local_hospital_outlined, title: 'العيادة', value: widget.doctor.clinic),
              const SizedBox(height: AppSpacing.sm),
              _InfoLine(icon: Icons.location_on_outlined, title: 'الموقع', value: widget.doctor.location),
              const SizedBox(height: AppSpacing.sm),
              _InfoLine(icon: Icons.workspace_premium_outlined, title: 'الخبرة', value: '${widget.doctor.experience} سنوات من الخبرة'),
              const SizedBox(height: AppSpacing.xl),
              Text('نبذة عن الطبيب', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(widget.doctor.bio, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.xl),
              Text('الخدمات والتخصصات', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final service in widget.doctor.services) _ServiceChip(label: service)]),
              const SizedBox(height: AppSpacing.xl),
              Text('المواعيد المتاحة', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (_dates.isEmpty) const EmptyState(title: 'لا توجد مواعيد متاحة', message: 'لم يتم نشر أوقات توافر لهذا الطبيب بعد.') else SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dates.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final selected = index == _selectedDate;
                    return InkWell(
                      onTap: () => setState(() {
                        _selectedDate = index;
                        _selectedTime = null;
                      }),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 90,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? AppColors.primary : AppColors.border)),
                        child: Text(_dates[index], textAlign: TextAlign.center, style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontSize: 12, fontWeight: FontWeight.w700, height: 1.45)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_times.isNotEmpty) Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final time in _times) _TimeChip(label: time, selected: time == _selectedTime, onTap: () => setState(() => _selectedTime = time))]),
            ]),
          ),
        ),
      );

}
