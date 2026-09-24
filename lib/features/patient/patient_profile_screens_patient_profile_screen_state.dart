part of 'patient_profile_screens.dart';

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  var _patient = const PatientProfile(name: '', phone: '', email: '', birthDate: '', gender: '');

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await const PatientProfileRepositoryImpl().getPatientProfile();
    if (!mounted) return;
    setState(() {
      _patient = PatientProfile(
        name: profile.name,
        phone: profile.phone,
        email: profile.email,
        birthDate: profile.birthDate,
        gender: profile.gender,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ProfileHeader(
                patient: _patient,
                onEdit: () async {
                  final updated = await Navigator.of(context).push<PatientProfile>(MaterialPageRoute(builder: (_) => EditPatientProfileScreen(patient: _patient)));
                  if (updated == null || !mounted) return;
                  try {
                    final repository = const PatientProfileRepositoryImpl();
                    await repository.updatePatientProfile(PatientProfileEntity(name: updated.name, phone: updated.phone, email: updated.email, birthDate: updated.birthDate, gender: updated.gender));
                    await _loadProfile();
                  } catch (error) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'المعلومات الشخصية'),
              const SizedBox(height: AppSpacing.sm),
              _InfoCard(icon: Icons.badge_outlined, label: 'الاسم الكامل', value: _patient.name),
              _InfoCard(icon: Icons.phone_outlined, label: 'رقم الهاتف', value: _patient.phone),
              _InfoCard(icon: Icons.email_outlined, label: 'البريد الإلكتروني', value: _patient.email),
              _InfoCard(icon: Icons.cake_outlined, label: 'تاريخ الميلاد', value: _patient.birthDate),
              _InfoCard(icon: Icons.person_outline, label: 'الجنس', value: _patient.gender),
              const SizedBox(height: AppSpacing.md),
              _NavigationTile(icon: Icons.settings_outlined, title: 'الإعدادات', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PatientSettingsScreen()))),
            ]),
          ),
        ),
      );
}
