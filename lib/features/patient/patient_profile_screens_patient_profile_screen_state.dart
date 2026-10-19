
part of 'patient_profile_screens.dart';

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  var _patient = const PatientProfile(
    name: '',
    phone: '',
    email: '',
    birthDate: '',
    gender: '',
    problemLocation: null,
    medicalNotes: null,
    medicalNotesHistory: [],
  );

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final profile =
      await const PatientProfileRepositoryImpl().getPatientProfile();

      if (!mounted) return;

      setState(() {
        _patient = PatientProfile(
          name: profile.name,
          phone: profile.phone,
          email: profile.email,
          birthDate: profile.birthDate,
          gender: profile.gender,
          problemLocation: profile.problemLocation,
          // Medical notes are intentionally hidden from patients.
          medicalNotes: null,
          medicalNotesHistory: const [],
        );
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[PatientProfile] ERROR: $error');
      debugPrint('[PatientProfile] STACK TRACE: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = 'تعذر تحميل بيانات الملف الشخصي.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : _loadError != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: _loadProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeader(
                  patient: _patient,
                  onEdit: _editProfile,
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(
                  title: 'المعلومات الشخصية',
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoCard(
                  icon: Icons.badge_outlined,
                  label: 'الاسم الكامل',
                  value: _displayValue(_patient.name),
                ),
                _InfoCard(
                  icon: Icons.phone_outlined,
                  label: 'رقم الهاتف',
                  value: _displayValue(_patient.phone),
                ),
                _InfoCard(
                  icon: Icons.email_outlined,
                  label: 'البريد الإلكتروني',
                  value: _displayValue(_patient.email),
                ),
                _InfoCard(
                  icon: Icons.cake_outlined,
                  label: 'تاريخ الميلاد',
                  value: _displayValue(_patient.birthDate),
                ),
                _InfoCard(
                  icon: Icons.person_outline,
                  label: 'الجنس',
                  value: _genderLabel(_patient.gender),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(
                  title: 'المعلومات الطبية',
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoCard(
                  icon: Icons.accessibility_new_outlined,
                  label: 'مكان المشكلة',
                  value: _problemLocationLabel(
                    _patient.problemLocation,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _NavigationTile(
                  icon: Icons.settings_outlined,
                  title: 'الإعدادات',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                        const PatientSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayValue(String value) {
    return value.trim().isEmpty ? 'غير محدد' : value.trim();
  }

  String _genderLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'male':
        return 'ذكر';
      case 'female':
        return 'أنثى';
      default:
        return _displayValue(value);
    }
  }

  String _problemLocationLabel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'غير محدد';
    }

    switch (value.trim().toLowerCase()) {
      case 'ear':
        return 'الأذن';
      case 'eye':
        return 'العين';
      case 'eyes':
        return 'العينان';
      default:
        return value.trim();
    }
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.of(context).push<PatientProfile>(
      MaterialPageRoute(
        builder: (_) => EditPatientProfileScreen(patient: _patient),
      ),
    );

    if (updated == null || !mounted) return;

    try {
      await const PatientProfileRepositoryImpl().updatePatientProfile(
        PatientProfileEntity(
          name: updated.name,
          phone: updated.phone,
          email: updated.email,
          birthDate: updated.birthDate,
          gender: updated.gender,
        ),
      );

      await _loadProfile();

      if (mounted && _loadError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث البيانات بنجاح.'),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[PatientProfile] UPDATE ERROR: $error');
      debugPrint('[PatientProfile] UPDATE STACK TRACE: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تحديث البيانات. حاول مرة أخرى.'),
        ),
      );
    }
  }
}
