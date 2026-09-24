part of 'doctor_appointments_screen.dart';

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  DoctorAppointmentFilter _selectedFilter = DoctorAppointmentFilter.today;

  List<DoctorAppointment> _appointments = const [];

  StreamSubscription<List<DoctorAppointment>>? _appointmentsSubscription;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToAppointments();
  }

  void _listenToAppointments() {
    _appointmentsSubscription?.cancel();

    _appointmentsSubscription = const DoctorAppointmentsRepositoryImpl()
        .watchDoctorAppointments()
        .listen(
          (appointments) {
        if (!mounted) return;

        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      },
      onError: (Object error) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _appointments
        .where((item) => item.status == _selectedFilter)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('مواعيدي'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نظّم جدولك وتابع مرضاك بسهولة',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FilterTabs(
                      selected: _selectedFilter,
                      onChanged: (filter) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (visible.isEmpty)
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final appointment = visible[index];

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.md,
                        ),
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

  Future<void> _openDetails(DoctorAppointment appointment) async {
    final updated = await Navigator.of(context).push<DoctorAppointment>(
      MaterialPageRoute(
        builder: (_) => DoctorAppointmentDetailsScreen(
          appointment: appointment,
        ),
      ),
    );

    if (updated != null && mounted) {
      final index = _appointments.indexOf(appointment);

      if (index != -1) {
        setState(() {
          _appointments[index] = updated;
        });
      }
    }
  }
}