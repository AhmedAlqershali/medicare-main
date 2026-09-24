part of 'organization_home_screen.dart';

class _OrganizationDashboard extends StatefulWidget {
  const _OrganizationDashboard({required this.onTabSelected});
  final ValueChanged<int> onTabSelected;

  @override
  State<_OrganizationDashboard> createState() => _OrganizationDashboardState();
}

class _OrganizationDashboardState extends State<_OrganizationDashboard> {
  List<OrganizationClinic> _clinics = const [];
  List<OrganizationDoctor> _doctors = const [];
  int _patientsCount = 0;
  int _appointmentsCount = 0;
  bool _loading = true;
  String? _error;
  List<String> _sectionErrors = const [];
  String _organizationName = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) setState(() {
      _loading = true;
      _error = null;
    });
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (organizationId == null || organizationId.isEmpty) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'لا توجد مؤسسة نشطة مرتبطة بالجلسة الحالية.';
      });
      return;
    }
    try {
      final sectionErrors = <String>[];
      final results = await Future.wait([
        _loadSection('العيادات', const OrganizationClinicsRepositoryImpl().getOrganizationClinics(includeRelatedData: false), const <OrganizationClinic>[], sectionErrors),
        _loadSection('الأطباء', const OrganizationDoctorsRepositoryImpl().getOrganizationDoctors(), const <OrganizationDoctor>[], sectionErrors),
        _loadSection('المرضى', FirestorePatientRepository.instance.fetchPatientsForOrganization(organizationId), const [], sectionErrors),
        _loadSection('المواعيد', FirestoreAppointmentRepository.instance.fetchAppointmentsForOrganization(organizationId), const [], sectionErrors),
        _loadSection<Organization?>('المؤسسة', FirestoreOrganizationRepository.instance.currentOrganization(organizationId: organizationId), null, sectionErrors),
      ]);
      final clinics = results[0] as List<OrganizationClinic>;
      final doctors = results[1] as List<OrganizationDoctor>;
      final patients = results[2] as List;
      final appointments = results[3] as List;
      final organization = results[4] as Organization?;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _sectionErrors = sectionErrors;
        _clinics = clinics;
        _doctors = doctors;
        _patientsCount = patients.length;
        _appointmentsCount = appointments.length;
        _organizationName = organization?.name ?? '';
      });
    } catch (error) {
      if (mounted) setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<T> _loadSection<T>(String label, Future<T> request, T fallback, List<String> errors) async {
    try {
      return await request;
    } catch (error) {
      errors.add('$label: $error');
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState();
    if (_error != null) return ErrorState(message: _error!, onRetry: _loadDashboardData);
    return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
            sliver: SliverList(delegate: SliverChildListDelegate([
              Row(children: [
                AppAvatar(initials: _initials, size: 52, backgroundColor: AppColors.sky),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('مرحباً بك في Medicare', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  SizedBox(height: 3),
                  Text(_organizationName, style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.45)),
                ])),
              ]),
              if (_sectionErrors.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('تعذر تحميل بعض الأقسام:\n${_sectionErrors.join('\n')}', style: const TextStyle(color: Color(0xFFC84C4C), fontSize: 12, height: 1.4)),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text('ملخص الإدارة', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _SummaryGrid(clinics: _clinics.length, doctors: _doctors.length, patients: _patientsCount, appointments: _appointmentsCount),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: 'العيادات', actionLabel: 'عرض جميع العيادات', onAction: () => widget.onTabSelected(1)),
              const SizedBox(height: AppSpacing.sm),
              for (final clinic in _clinics.take(2)) ...[
                _ClinicPreviewCard(clinic: clinic, doctors: _doctorsForClinic(clinic), onTap: () => widget.onTabSelected(1)),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: 'الأطباء', actionLabel: 'عرض جميع الأطباء', onAction: () => widget.onTabSelected(2)),
              const SizedBox(height: AppSpacing.sm),
              for (final doctor in _doctors.take(2)) ...[
                _DoctorPreviewCard(doctor: doctor, onTap: () => widget.onTabSelected(2)),
                const SizedBox(height: AppSpacing.sm),
              ],
            ])),
          ),
        ],
      );
  }

  List<OrganizationDoctor> _doctorsForClinic(OrganizationClinic clinic) => _doctors.where((doctor) => doctor.clinicId == clinic.id || (doctor.clinicId == null && (doctor.clinic == clinic.id || doctor.clinic == clinic.name))).toList();

  String get _initials {
    final parts = _organizationName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'م';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}';
  }
}
