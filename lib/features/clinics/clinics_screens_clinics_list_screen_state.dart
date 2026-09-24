part of 'clinics_screens.dart';

class _ClinicsListScreenState extends State<ClinicsListScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  late List<ClinicData> _clinics = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    try {
      final clinics = await const ClinicsRepositoryImpl().getClinics();
      if (!mounted) return;
      setState(() {
        _clinics = clinics.map(_toClinicData).toList();
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  List<String> get _categories => ['الكل', ..._clinics.map((clinic) => clinic.category).where((category) => category.trim().isNotEmpty).toSet()];

  ClinicData _toClinicData(ClinicEntity entity) => ClinicData(
        name: entity.name,
        category: entity.category,
        location: entity.location,
        description: entity.description,
        hours: entity.hours,
        specialties: List<String>.from(entity.specialties),
        status: entity.status,
        icon: entity.icon,
        color: Color(entity.colorValue),
        doctors: entity.doctors.map((doctor) => ClinicDoctorData(
            id: doctor.id,
          initials: doctor.initials,
          name: doctor.name,
          specialty: doctor.specialty,
          rating: doctor.rating,
          reviews: doctor.reviews,
          experience: doctor.experience,
          bio: doctor.bio,
          services: List<String>.from(doctor.services),
          color: Color(doctor.colorValue),
        )).toList(),
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClinicData> get _filteredClinics => _clinics.where((clinic) {
        final matchesCategory = _selectedCategory == 'الكل' || clinic.category == _selectedCategory;
        final query = _searchQuery.trim();
        final matchesSearch = query.isEmpty || clinic.name.contains(query) || clinic.category.contains(query) || clinic.location.contains(query);
        return matchesCategory && matchesSearch;
      }).toList();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('العيادات'),
          leading: const BackButton(),
        ),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text('اختر العيادة المناسبة لك', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.md),
                    CustomTextField(
                      label: 'ابحث عن عيادة...',
                      prefixIcon: Icons.search_rounded,
                      controller: _searchController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('التصنيف', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 39,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final selected = category == _selectedCategory;
                          return ChoiceChip(
                            label: Text(category),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedCategory = category),
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
                    Text('${_filteredClinics.length} عيادات متاحة', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.sm),
                  ]),
                ),
              ),
              if (_error != null)
                SliverFillRemaining(hasScrollBody: false, child: ErrorState(message: _error!, onRetry: _loadClinics))
              else if (_filteredClinics.isEmpty)
                const SliverFillRemaining(hasScrollBody: false, child: _ClinicsEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.crossAxisExtent >= 650 ? 2 : 1;
                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final clinic = _filteredClinics[index];
                            return _ClinicListCard(clinic: clinic, onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ClinicDetailsScreen(clinic: clinic))));
                          },
                          childCount: _filteredClinics.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, mainAxisExtent: 274),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
}
