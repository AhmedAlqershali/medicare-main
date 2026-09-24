part of 'patient_home_screen.dart';

class _HomeContent extends StatefulWidget {
  const _HomeContent({required this.onBook});
  final VoidCallback onBook;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  List<DoctorEntity> _doctors = const [];
  List<ClinicEntity> _clinics = const [];
  List<AppointmentEntity> _appointments = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        const DoctorsRepositoryImpl().getDoctors(),
        const ClinicsRepositoryImpl().getClinics(),
        const AppointmentsRepositoryImpl().getAppointments(),
      ]);
      if (!mounted) return;
      setState(() {
        _doctors = results[0] as List<DoctorEntity>;
        _clinics = results[1] as List<ClinicEntity>;
        _appointments = results[2] as List<AppointmentEntity>;
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _HomeHeader(),
                if (_loading) const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.xl), child: Center(child: CircularProgressIndicator()))
                else ...[
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: 'موعدك القادم', actionLabel: 'عرض الكل', onAction: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AppointmentsScreen()))),
                const SizedBox(height: AppSpacing.sm),
                if (_error != null) ErrorState(message: _error!, onRetry: _loadData)
                else if (_appointments.isEmpty) const EmptyState(title: 'لا توجد مواعيد', message: 'ستظهر مواعيدك هنا بعد أن يحدد الطبيب موعد الزيارة.')
                else PatientAppointmentCard(appointment: _appointments.first, onView: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AppointmentsScreen()))),
                const SizedBox(height: AppSpacing.xl),
                Text('كيف نساعدك اليوم؟', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17)),
                const SizedBox(height: AppSpacing.md),
                _QuickActions(onBook: widget.onBook, onClinics: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ClinicsListScreen()))),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: 'أطباء مقترحون', actionLabel: 'عرض الكل', onAction: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DoctorsListScreen()))),
                const SizedBox(height: AppSpacing.sm),
                _DoctorsSection(doctors: _doctors),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: 'اكتشف العيادات', actionLabel: 'عرض الكل', onAction: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ClinicsListScreen()))),
                const SizedBox(height: AppSpacing.sm),
                _ClinicsSection(clinics: _clinics),
                const SizedBox(height: AppSpacing.lg),
                ],
              ]),
            ),
          ),
        ],
      );

}
