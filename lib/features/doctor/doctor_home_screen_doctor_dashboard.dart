part of 'doctor_home_screen.dart';

class _DoctorDashboard extends StatefulWidget {
  const _DoctorDashboard({super.key, required this.onTabSelected});
  final ValueChanged<int> onTabSelected;

  @override
  State<_DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<_DoctorDashboard> {
  List<DoctorAppointment> _appointments = const [];
  int _patientsCount = 0;
  bool _loading = true;
  String? _error;
  String _doctorName = '';
  String _clinicName = '';
  String _organizationName = '';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> reload() => _loadAppointments();

  Future<void> _loadAppointments() async {
    if (mounted) setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await DoctorAppointmentsRepositoryImpl().getDoctorAppointments();
      final session = FirebaseAuthRepository.instance.session;
      final doctorId = session.doctorId;
      final organizationId = session.organizationId;
      if (doctorId == null || organizationId == null || doctorId.isEmpty || organizationId.isEmpty) throw StateError('لا توجد هوية طبيب ومؤسسة مرتبطة بجلسة المستخدم.');
      final patients = await FirestorePatientRepository.instance.fetchPatientsForDoctor(doctorId, organizationId: organizationId);
      final doctor = await FirestoreDoctorRepository.instance.fetchDoctorByIdForOrganization(organizationId, doctorId);
      final organization = await FirestoreOrganizationRepository.instance.fetchOrganizationById(organizationId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _appointments = items;
        _patientsCount = patients.length;
        _doctorName = doctor?.name ?? session.currentUser?.name ?? '';
        _clinicName = doctor?.clinic ?? '';
        _organizationName = organization?.name ?? '';
      });
    } catch (error) {
      if (mounted) setState(() {
        _loading = false;
        _error = error.toString();
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState();
    final todayAppointments = _appointments.where((item) => item.status == DoctorAppointmentFilter.today).toList();
    final upcomingAppointments = _appointments.where((item) => item.status == DoctorAppointmentFilter.upcoming).toList();
    return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
            sliver: SliverList(delegate: SliverChildListDelegate([
              Row(children: [
                AppAvatar(initials: _initials, size: 52, backgroundColor: AppColors.sky),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('مرحباً، ${_doctorName.isEmpty ? 'الطبيب' : _doctorName}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text([_clinicName, _organizationName].where((value) => value.isNotEmpty).join(' • '), style: Theme.of(context).textTheme.bodyMedium),
                ])),
                IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد إشعارات جديدة.'))), icon: const Icon(Icons.notifications_none_rounded), tooltip: 'الإشعارات'),
              ]),
              const SizedBox(height: AppSpacing.xl),
              Text('نظرة اليوم', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (_error != null) ErrorState(message: _error!, onRetry: _loadAppointments),
              _OverviewGrid(appointments: _appointments.length, patients: _patientsCount),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: 'مواعيد اليوم', actionLabel: 'عرض الكل', onAction: () => widget.onTabSelected(1)),
              const SizedBox(height: AppSpacing.sm),
              for (final appointment in todayAppointments.take(3)) ...[
                _DashboardAppointmentCard(appointment: appointment, onDetails: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DoctorAppointmentDetailsScreen(appointment: appointment)))),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (todayAppointments.isEmpty) const EmptyState(title: 'لا توجد مواعيد اليوم', message: 'ستظهر مواعيد اليوم هنا عند توفرها.', icon: Icons.event_available_outlined),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'المواعيد القادمة'),
              const SizedBox(height: AppSpacing.sm),
              for (final appointment in upcomingAppointments.take(3)) ...[
                _DashboardAppointmentCard(appointment: appointment, onDetails: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DoctorAppointmentDetailsScreen(appointment: appointment)))),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (upcomingAppointments.isEmpty) const EmptyState(title: 'لا توجد مواعيد قادمة', message: 'ستظهر المواعيد القادمة هنا عند حجزها.', icon: Icons.event_note_outlined),
              const SizedBox(height: AppSpacing.md),
              Text('إجراءات سريعة', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _QuickActions(onTabSelected: widget.onTabSelected),
            ])),
          ),
        ],
        );
      }

  String get _initials {
    final name = FirebaseAuthRepository.instance.session.currentUser?.name ?? 'ط';
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    return parts.length > 1 ? '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}' : parts.first.substring(0, 1);
  }
}
