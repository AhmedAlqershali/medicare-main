part of 'doctor_patients_screen.dart';

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  String _query = '';
  List<DoctorPatient> _patients = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _query = _searchController.text.trim();
      });
    });

    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = FirebaseAuthRepository.instance.session;

      final doctorId = session.doctorId;
      final organizationId = session.organizationId;

      if (doctorId == null || doctorId.isEmpty) {
        throw Exception('لم يتم العثور على رقم الطبيب في الجلسة الحالية.');
      }

      if (organizationId == null || organizationId.isEmpty) {
        throw Exception('لم يتم العثور على المؤسسة المرتبطة بالطبيب.');
      }

      final patients = await FirestorePatientRepository.instance
          .fetchPatientsForDoctor(doctorId);

      final scopedPatients = patients.where((patient) {
        return patient.organizationId == organizationId &&
            patient.doctorId == doctorId;
      }).toList();

      final mappedPatients = scopedPatients.map((patient) {
        return DoctorPatient(
          id: patient.id,
          organizationId: patient.organizationId,
          doctorId: patient.doctorId,
          clinicId: patient.clinicId,
          firebaseUid: patient.firebaseUid,
          name: patient.name,
          initials: patient.initials,
          age: _calculateAge(patient.birthDate),
          gender: patient.gender ?? 'غير محدد',
          birthDate: patient.birthDate ?? '',
          email: patient.email,
          phone: patient.phone ?? '',
          lastAppointment: '',
          status: patient.status.name,
          avatarColor: _avatarColorForPatient(patient.id),
          notes: patient.medicalNotes ?? '',
          problemLocation: patient.problemLocation,
          medicalNotesHistory: patient.medicalNotesHistory,
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _patients = mappedPatients;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  String _calculateAge(String? birthDate) {
    if (birthDate == null || birthDate.trim().isEmpty) {
      return 'غير محدد';
    }

    final parsedDate = DateTime.tryParse(birthDate);

    if (parsedDate == null) {
      return 'غير محدد';
    }

    final now = DateTime.now();

    int age = now.year - parsedDate.year;

    if (now.month < parsedDate.month ||
        (now.month == parsedDate.month &&
            now.day < parsedDate.day)) {
      age--;
    }

    return age >= 0 ? age.toString() : 'غير محدد';
  }

  Color _avatarColorForPatient(String patientId) {
    const colors = [
      Color(0xFFE8EAF6),
      Color(0xFFE0F2F1),
      Color(0xFFFFF3E0),
      Color(0xFFFCE4EC),
      Color(0xFFE3F2FD),
      Color(0xFFF3E5F5),
    ];

    if (patientId.isEmpty) {
      return colors.first;
    }

    final index = patientId.codeUnits.fold<int>(
      0,
          (sum, value) => sum + value,
    ) %
        colors.length;

    return colors[index];
  }

  List<DoctorPatient> get _filteredPatients {
    if (_query.isEmpty) {
      return _patients;
    }

    final query = _query.toLowerCase();

    return _patients.where((patient) {
      return patient.name.toLowerCase().contains(query) ||
          patient.email.toLowerCase().contains(query) ||
          patient.phone.toLowerCase().contains(query);
    }).toList();
  }

  void _openAddPatient() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => const AddPatientScreen(),
      ),
    )
        .then((_) {
      if (mounted) {
        _loadPatients();
      }
    });
  }

  Future<void> _openPatientDetails(
      DoctorPatient patient,
      ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorPatientDetailsScreen(
          patient: patient,
        ),
      ),
    );

    if (mounted) {
      _loadPatients();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patients = _filteredPatients;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchField(),
            Expanded(
              child: _buildPatientsContent(patients),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPatient,
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المرضى',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_patients.length} مريض',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadPatients,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'ابحث عن مريض...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
            onPressed: _searchController.clear,
            icon: const Icon(Icons.clear),
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPatientsContent(
      List<DoctorPatient> patients,
      ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'تعذر تحميل المرضى',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPatients,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people_outline,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                _query.isEmpty
                    ? 'لا يوجد مرضى حتى الآن'
                    : 'لا يوجد مريض مطابق للبحث',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_query.isEmpty) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _openAddPatient,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('إضافة مريض'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPatients,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: patients.length,
        separatorBuilder: (_, __) =>
        const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final patient = patients[index];

          return _PatientCard(
            patient: patient,
            onTap: () => _openPatientDetails(patient),
          );
        },
      ),
    );
  }
}