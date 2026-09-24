part of 'organization_doctors_screen.dart';

class _OrganizationDoctorsScreenState extends State<OrganizationDoctorsScreen> {
  final _searchController = TextEditingController();
  List<String> _specialties = const ['الكل'];
  List<String> _clinics = const ['الكل'];
  String _selectedSpecialty = 'الكل';
  String _selectedClinic = 'الكل';
  String _query = '';
  List<OrganizationDoctor> _doctors = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doctors = await const OrganizationDoctorsRepositoryImpl().getOrganizationDoctors();
      final organizationId = FirebaseAuthRepository.instance.session.organizationId;
      final clinics = organizationId == null || organizationId.isEmpty ? const <Map<String, dynamic>>[] : await FirestoreClinicRepository.instance.fetchClinicsForOrganization(organizationId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _doctors = doctors;
        _specialties = ['الكل', ...doctors.map((doctor) => doctor.specialty).where((specialty) => specialty.trim().isNotEmpty).toSet()];
        _clinics = ['الكل', ...clinics.map((clinic) => clinic['name'] as String? ?? '').where((clinic) => clinic.trim().isNotEmpty).toSet()];
        if (!_clinics.contains(_selectedClinic)) _selectedClinic = 'الكل';
      });
    } catch (error) {
      if (mounted) setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<OrganizationDoctor> get _filteredDoctors => _doctors.where((doctor) {
    final query = _query.trim();
    final matchesSpecialty = _selectedSpecialty == 'الكل' || doctor.specialty == _selectedSpecialty;
    final matchesClinic = _selectedClinic == 'الكل' || doctor.clinic == _selectedClinic;
    final matchesSearch = query.isEmpty || doctor.name.contains(query) || doctor.specialty.contains(query) || doctor.clinic.contains(query);
    return matchesSpecialty && matchesClinic && matchesSearch;
  }).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: SafeArea(child: LoadingState()));
    if (_error != null) return Scaffold(body: SafeArea(child: ErrorState(message: _error!, onRetry: _loadDoctors)));
    return Scaffold(
        appBar: AppBar(title: const Text('الأطباء'), actions: [IconButton(onPressed: _openAddDoctor, icon: const Icon(Icons.person_add_alt_1_outlined), tooltip: 'إضافة طبيب')]),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('إدارة الفريق الطبي', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.md),
                    CustomTextField(label: 'ابحث عن طبيب', prefixIcon: Icons.search_rounded, controller: _searchController, onChanged: (value) => setState(() => _query = value)),
                    const SizedBox(height: AppSpacing.lg),
                    Text('التخصص', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 39,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _specialties.length,
                        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final specialty = _specialties[index];
                          final selected = specialty == _selectedSpecialty;
                          return ChoiceChip(
                            label: Text(specialty),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedSpecialty = specialty),
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surface,
                            side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                            labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontSize: 12, fontWeight: FontWeight.w600),
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('العيادة', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedClinic,
                          items: _clinics.map((clinic) => DropdownMenuItem(value: clinic, child: Text(clinic))).toList(),
                          onChanged: (value) => setState(() => _selectedClinic = value ?? 'الكل'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('${_filteredDoctors.length} طبيب', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
              if (_filteredDoctors.isEmpty)
                const SliverFillRemaining(hasScrollBody: false, child: EmptyState(title: 'لا توجد نتائج', message: 'لا توجد أطباء متطابقة مع الفلاتر الحالية.', icon: Icons.person_search_outlined))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                  sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                    final doctor = _filteredDoctors[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _DoctorCard(doctor: doctor, onTap: () => _openDetails(doctor)),
                    );
                  }, childCount: _filteredDoctors.length)),
                ),
            ],
          ),
        ),
        );
      }

  Future<void> _openDetails(OrganizationDoctor doctor) async {
    final updated = await Navigator.of(context).push<OrganizationDoctor>(MaterialPageRoute<OrganizationDoctor>(builder: (_) => OrganizationDoctorDetailsScreen(doctor: doctor)));
    if (updated != null && mounted) {
      setState(() {
        final index = _doctors.indexWhere((item) => item.id == doctor.id);
        if (index != -1) _doctors[index] = updated;
      });
    }
  }

  Future<void> _openAddDoctor() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AddDoctorScreen()));
    if (mounted) await _loadDoctors();
  }
}
