part of 'organization_clinics_screen.dart';

class _OrganizationClinicsScreenState extends State<OrganizationClinicsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  late List<OrganizationClinic> _clinics = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clinics = await const OrganizationClinicsRepositoryImpl().getOrganizationClinics();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _clinics = clinics;
      });
    } catch (error) {
      if (mounted) setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<OrganizationClinic> get _filteredClinics => _clinics.where((clinic) {
    final query = _query.trim();
    return query.isEmpty || clinic.name.contains(query) || clinic.location.contains(query) || clinic.departments.any((department) => department.contains(query));
  }).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: SafeArea(child: LoadingState()));
    if (_error != null) return Scaffold(body: SafeArea(child: ErrorState(message: _error!, onRetry: _loadClinics)));
    return Scaffold(
        appBar: AppBar(
          title: const Text('العيادات'),
          actions: [IconButton(onPressed: _openAddClinic, icon: const Icon(Icons.add_rounded), tooltip: 'إضافة عيادة')],
        ),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('إدارة العيادات والفرع', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.md),
                    CustomTextField(
                      label: 'ابحث عن عيادة',
                      prefixIcon: Icons.search_rounded,
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('${_filteredClinics.length} عيادة', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
              if (_filteredClinics.isEmpty)
                const SliverFillRemaining(hasScrollBody: false, child: EmptyState(title: 'لا توجد نتائج', message: 'لا توجد عيادات مطابقة لبحثك.', icon: Icons.search_off_outlined))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                  sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                    final clinic = _filteredClinics[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ClinicCard(
                        clinic: clinic,
                        onTap: () => _openClinicDetails(clinic),
                      ),
                    );
                  }, childCount: _filteredClinics.length)),
                ),
            ],
          ),
        ),
        );
      }

  Future<void> _openClinicDetails(OrganizationClinic clinic) async {
    final updated = await Navigator.of(context).push<OrganizationClinic>(MaterialPageRoute<OrganizationClinic>(builder: (_) => OrganizationClinicDetailsScreen(clinic: clinic)));
    if (updated != null && mounted) {
      final organizationId = FirebaseAuthRepository.instance.session.organizationId;
      if (organizationId == null || organizationId.isEmpty) return;
      try {
        await FirestoreClinicRepository.instance.saveClinic(organizationId: organizationId, clinic: _clinicMap(updated));
      } catch (error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
        return;
      }
      setState(() {
        final index = _clinics.indexWhere((item) => item.id == clinic.id);
        if (index != -1) _clinics[index] = updated;
      });
    }
  }

  Future<void> _openAddClinic() async {
    final created = await Navigator.of(context).push<OrganizationClinic>(MaterialPageRoute<OrganizationClinic>(builder: (_) => const OrganizationClinicFormScreen()));
    if (created != null && mounted) {
      final organizationId = FirebaseAuthRepository.instance.session.organizationId;
      if (organizationId == null || organizationId.isEmpty) return;
      try {
        await FirestoreClinicRepository.instance.createClinic(organizationId: organizationId, clinic: _clinicMap(created));
      } catch (error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
        return;
      }
      setState(() => _clinics.insert(0, created));
    }
  }

  Map<String, dynamic> _clinicMap(OrganizationClinic clinic) => {
        'id': clinic.id,
        'name': clinic.name,
        'location': clinic.location,
        'phone': clinic.phone,
        'description': clinic.description,
        'status': clinic.status,
        'doctorsCount': clinic.doctorsCount,
        'departmentsCount': clinic.departmentsCount,
        'patientsCount': clinic.patientsCount,
        'departments': clinic.departments,
      };
}
