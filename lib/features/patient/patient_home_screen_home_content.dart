part of 'patient_home_screen.dart';

class _HomeContent extends StatefulWidget {
  const _HomeContent({
    required this.onBook,
  });

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
      final session = FirebaseAuthRepository.instance.session;

      final organizationId = session.organizationId;
      final patientId = session.patientId;

      if (organizationId == null || organizationId.isEmpty) {
        throw StateError(
          'لا توجد مؤسسة مرتبطة بحساب المريض.',
        );
      }

      if (patientId == null || patientId.isEmpty) {
        throw StateError(
          'لا توجد هوية مريض مرتبطة بالحساب.',
        );
      }

      // قراءة سجل المريض لمعرفة العيادة المرتبط بها.
      final patient =
      await FirestorePatientRepository.instance.fetchPatientById(
        patientId,
        organizationId: organizationId,
      );

      if (patient == null) {
        throw StateError(
          'لم يتم العثور على سجل المريض المرتبط بالحساب.',
        );
      }

      final patientClinicId = patient.clinicId;

      if (patientClinicId == null || patientClinicId.isEmpty) {
        throw StateError(
          'لا توجد عيادة مرتبطة بسجل المريض.',
        );
      }

      final results = await Future.wait([
        const DoctorsRepositoryImpl().getDoctors(),
        const ClinicsRepositoryImpl().getClinics(),
        const AppointmentsRepositoryImpl().getAppointments(),
      ]);

      if (!mounted) return;

      final allDoctors = results[0] as List<DoctorEntity>;
      final allClinics = results[1] as List<ClinicEntity>;
      final appointments = results[2] as List<AppointmentEntity>;

      // الأطباء التابعون لعيادة المريض فقط.
      final clinicDoctors = allDoctors
          .where(
            (doctor) =>
        doctor.clinicId != null &&
            doctor.clinicId == patientClinicId,
      )
          .toList();

      setState(() {
        _doctors = clinicDoctors;
        _clinics = allClinics;
        _appointments = appointments;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            const _HomeHeader(),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: AppSpacing.xl,
                ),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              const SizedBox(
                height: AppSpacing.xl,
              ),

              // =========================
              // الموعد القادم
              // =========================

              SectionHeader(
                title: 'موعدك القادم',
                actionLabel: 'عرض الكل',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                      const AppointmentsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: AppSpacing.sm,
              ),

              if (_error != null)
                ErrorState(
                  message: _error!,
                  onRetry: _loadData,
                )
              else if (_appointments.isEmpty)
                const EmptyState(
                  title: 'لا توجد مواعيد',
                  message:
                  'ستظهر مواعيدك هنا بعد أن يحدد الطبيب موعد الزيارة.',
                )
              else
                PatientAppointmentCard(
                  appointment: _appointments.first,
                  onView: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                        const AppointmentsScreen(),
                      ),
                    );
                  },
                ),

              const SizedBox(
                height: AppSpacing.xl,
              ),

              // =========================
              // الإجراءات السريعة
              // =========================

              Text(
                'كيف نساعدك اليوم؟',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  fontSize: 17,
                ),
              ),

              const SizedBox(
                height: AppSpacing.md,
              ),

              _QuickActions(
                onBook: widget.onBook,
                onDoctors: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                      const DoctorsListScreen(),
                    ),
                  );
                },
                onClinics: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                      const ClinicsListScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: AppSpacing.xl,
              ),

              // =========================
              // أطباء عيادة المريض
              // =========================

              SectionHeader(
                title: 'أطباء مقترحون',
                actionLabel: 'عرض الكل',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                      const DoctorsListScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: AppSpacing.sm,
              ),

              _DoctorsSection(
                doctors: _doctors,
              ),

              const SizedBox(
                height: AppSpacing.xl,
              ),

              // =========================
              // عيادات المؤسسة
              // =========================

              SectionHeader(
                title: 'اكتشف العيادات',
                actionLabel: 'عرض الكل',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                      const ClinicsListScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: AppSpacing.sm,
              ),

              _ClinicsSection(
                clinics: _clinics,
              ),

              const SizedBox(
                height: AppSpacing.lg,
              ),
            ],
          ]),
        ),
      ),
    ],
  );
}