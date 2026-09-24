part of 'doctor_appointments_screen.dart';

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  DoctorAppointmentFilter _selectedFilter = DoctorAppointmentFilter.today;
  late List<DoctorAppointment> _appointments = const [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    List<DoctorAppointment> appointments;
    try {
      appointments = await const DoctorAppointmentsRepositoryImpl().getDoctorAppointments();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    if (!mounted) return;
    setState(() {
      _appointments = appointments;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _appointments.where((item) => item.status == _selectedFilter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('مواعيدي')),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('نظّم جدولك وتابع مرضاك بسهولة', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.lg),
                    _FilterTabs(
                      selected: _selectedFilter,
                      onChanged: (filter) => setState(() => _selectedFilter = filter),
                    ),
                  ],
                ),
              ),
            ),
            if (visible.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: 'لا توجد مواعيد',
                  message: 'ستظهر المواعيد هنا عند توفرها.',
                  icon: Icons.event_available_outlined,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final appointment = visible[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _DoctorAppointmentCard(
                          appointment: appointment,
                          onDetails: () => _openDetails(appointment),
                        ),
                      );
                    },
                    childCount: visible.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openDetails(DoctorAppointment appointment) async {
    final updated = await Navigator.of(context).push<DoctorAppointment>(MaterialPageRoute(builder: (_) => DoctorAppointmentDetailsScreen(appointment: appointment)));
    if (updated != null && mounted) setState(() { final index = _appointments.indexOf(appointment); if (index != -1) _appointments[index] = updated; });
  }
}
