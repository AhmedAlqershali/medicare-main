part of 'doctors_screens.dart';

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  final _searchController = TextEditingController();
  String _selectedSpecialty = 'الكل';
  String _searchQuery = '';
  late List<DoctorData> _doctors = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await const DoctorsRepositoryImpl().getDoctors();
      if (!mounted) return;
      setState(() {
        _doctors = doctors.map(_toDoctorData).toList();
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  List<String> get _specialties => ['الكل', ..._doctors.map((doctor) => doctor.specialty).where((specialty) => specialty.trim().isNotEmpty).toSet()];

    DoctorData _toDoctorData(DoctorEntity entity) => DoctorData(
      id: entity.id,
        initials: entity.initials,
        name: entity.name,
        specialty: entity.specialty,
        clinic: entity.clinic,
        location: entity.location,
        rating: entity.rating,
        reviews: entity.reviews,
        experience: entity.experience,
        bio: entity.bio,
        services: List<String>.from(entity.services),
        color: Color(entity.colorValue),
        clinicId: entity.clinicId,
        availability: entity.availability,
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DoctorData> get _filteredDoctors => _doctors.where((doctor) {
        final matchesSpecialty = _selectedSpecialty == 'الكل' || doctor.specialty == _selectedSpecialty;
        final query = _searchQuery.trim();
        final matchesSearch = query.isEmpty || doctor.name.contains(query) || doctor.specialty.contains(query) || doctor.clinic.contains(query);
        return matchesSpecialty && matchesSearch;
      }).toList();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('الأطباء'),
          leading: const BackButton(),
        ),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  Text('اعثر على الطبيب المناسب لرعايتك', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    label: 'ابحث عن طبيب أو تخصص',
                    prefixIcon: Icons.search_rounded,
                    controller: _searchController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('التخصص', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 39,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('${_filteredDoctors.length} أطباء متاحون', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.sm),
                ])),
              ),
              if (_error != null)
                SliverFillRemaining(hasScrollBody: false, child: ErrorState(message: _error!, onRetry: _loadDoctors))
              else if (_filteredDoctors.isEmpty)
                const SliverFillRemaining(hasScrollBody: false, child: _DoctorsEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                  sliver: SliverLayoutBuilder(builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 600 ? 2 : 1;
                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _DoctorListCard(doctor: _filteredDoctors[index], onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DoctorDetailsScreen(doctor: _filteredDoctors[index])))),
                        childCount: _filteredDoctors.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        mainAxisExtent: 224,
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
      );
}
