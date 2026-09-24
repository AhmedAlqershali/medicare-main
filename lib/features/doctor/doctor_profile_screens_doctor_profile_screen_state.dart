part of 'doctor_profile_screens.dart';

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  var _profile = const DoctorProfile(name: '', specialty: '', clinic: '', email: '', phone: '');
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doctorId = FirebaseAuthRepository.instance.session.doctorId;
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (doctorId == null || doctorId.isEmpty || organizationId == null || organizationId.isEmpty) {
      if (mounted) setState(() => _error = 'لا توجد جلسة طبيب نشطة.');
      return;
    }
    try {
      final doctor = await FirestoreDoctorRepository.instance.fetchDoctorByIdForOrganization(organizationId, doctorId);
      if (!mounted) return;
      if (doctor == null) {
        setState(() => _error = 'لم يتم العثور على ملف الطبيب.');
        return;
      }
      setState(() => _profile = DoctorProfile(name: doctor.name, specialty: doctor.specialty, clinic: doctor.clinic, email: doctor.email, phone: doctor.phone));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFC84C4C), fontWeight: FontWeight.w700)),
                AppCard(
                  child: Row(
                    children: [
                      const AppAvatar(initials: 'أ ح', size: 72, backgroundColor: AppColors.sky),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_profile.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(_profile.specialty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(_profile.clinic, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      IconButton(onPressed: _editProfile, icon: const Icon(Icons.edit_outlined), tooltip: 'تعديل الملف الشخصي'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'معلومات التواصل'),
                const SizedBox(height: AppSpacing.sm),
                _InfoTile(icon: Icons.badge_outlined, label: 'التخصص', value: _profile.specialty),
                _InfoTile(icon: Icons.local_hospital_outlined, label: 'العيادة', value: _profile.clinic),
                _InfoTile(icon: Icons.email_outlined, label: 'البريد الإلكتروني', value: _profile.email),
                _InfoTile(icon: Icons.phone_outlined, label: 'رقم الهاتف', value: _profile.phone),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'الإعدادات'),
                const SizedBox(height: AppSpacing.sm),
                _SettingTile(icon: Icons.calendar_month_outlined, title: 'جدول الطبيب', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DoctorScheduleScreen()))),
                _SettingTile(icon: Icons.edit_outlined, title: 'تعديل الملف الشخصي', onTap: _editProfile),
                _SettingTile(icon: Icons.notifications_none_rounded, title: 'الإشعارات', onTap: () => _showMessage(context, 'لا توجد إشعارات جديدة.')),
                _SettingTile(icon: Icons.brightness_6_outlined, title: 'المظهر', onTap: () => _showMessage(context, 'المظهر مضبوط على الوضع الفاتح')),
                _SettingTile(icon: Icons.support_agent_outlined, title: 'المساعدة', onTap: () => _showMessage(context, 'يسعدنا مساعدتك')),
                _SettingTile(icon: Icons.info_outline, title: 'عن Medicare', onTap: () => _showMessage(context, 'Medicare للرعاية الصحية')),
                _SettingTile(icon: Icons.logout_rounded, title: 'تسجيل الخروج', color: const Color(0xFFC84C4C), onTap: () => _showLogoutDialog(context)),
              ],
            ),
          ),
        ),
      );

  Future<void> _editProfile() async {
    final updated = await Navigator.of(context).push<DoctorProfile>(MaterialPageRoute(builder: (_) => DoctorEditProfileScreen(profile: _profile)));
    if (updated == null || !mounted) return;
    final doctorId = FirebaseAuthRepository.instance.session.doctorId;
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (doctorId == null || doctorId.isEmpty || organizationId == null || organizationId.isEmpty) return;
    try {
      final doctor = await FirestoreDoctorRepository.instance.fetchDoctorByIdForOrganization(organizationId, doctorId);
      if (doctor == null) throw StateError('لم يتم العثور على ملف الطبيب.');
      if (updated.email.trim().toLowerCase() != doctor.email.trim().toLowerCase()) {
        throw StateError('لا يمكن تغيير البريد الإلكتروني المرتبط بحساب الطبيب.');
      }
      await FirestoreDoctorRepository.instance.saveDoctor(Doctor(
        id: doctor.id,
        name: updated.name,
        email: updated.email,
        organizationId: doctor.organizationId,
        specialty: updated.specialty,
        status: doctor.status,
        initials: doctor.initials,
        clinic: updated.clinic,
        clinicId: doctor.clinicId,
        phone: doctor.phone,
        location: doctor.location,
        rating: doctor.rating,
        reviews: doctor.reviews,
        experience: doctor.experience,
        bio: doctor.bio,
        services: doctor.services,
        firebaseUid: doctor.firebaseUid,
        createdAt: doctor.createdAt,
        updatedAt: DateTime.now(),
      ));
      if (mounted) setState(() => _profile = updated);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  static void _showMessage(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  static Future<void> _showLogoutDialog(BuildContext context) async => showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('تسجيل الخروج'), content: const Text('هل أنت متأكد من تسجيل الخروج؟'), actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')), FilledButton(onPressed: () { Navigator.of(dialogContext).pop(); AuthNavigation.openSignedOutFlow(context); }, child: const Text('تسجيل الخروج'))]));
}
