part of 'organization_profile_screens.dart';

class _OrganizationProfileScreenState extends State<OrganizationProfileScreen> {
  var _profile = const OrganizationProfile(name: '', email: '', phone: '', location: '', clinicsCount: 0);
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (organizationId == null || organizationId.isEmpty) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'لا توجد مؤسسة نشطة مرتبطة بالجلسة الحالية.';
      });
      return;
    }
    try {
      final organization = await FirestoreOrganizationRepository.instance.fetchOrganizationById(organizationId);
      if (!mounted) return;
      if (organization == null) {
        setState(() {
          _loading = false;
          _error = 'لم يتم العثور على ملف المؤسسة.';
        });
        return;
      }
      final clinics = await FirestoreClinicRepository.instance.fetchClinicsForOrganization(organizationId);
      setState(() {
        _loading = false;
        _profile = OrganizationProfile(name: organization.name, email: organization.email, phone: organization.phone, location: organization.location, clinicsCount: clinics.length);
      });
    } catch (error) {
      if (mounted) setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: SafeArea(child: LoadingState()));
    if (_error != null) return Scaffold(body: SafeArea(child: ErrorState(message: _error!, onRetry: _loadProfile)));
    return Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFC84C4C), fontWeight: FontWeight.w700)),
              AppCard(
                child: Row(children: [
                  const AppAvatar(initials: 'م م', size: 72, backgroundColor: AppColors.sky),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_profile.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text('إدارة الشبكة الطبية', style: Theme.of(context).textTheme.bodyMedium),
                  ])),
                  IconButton(onPressed: _saving ? null : _editProfile, icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.edit_outlined), tooltip: 'تعديل الملف'),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'معلومات المؤسسة'),
              const SizedBox(height: AppSpacing.sm),
              _InfoTile(icon: Icons.email_outlined, label: 'البريد الإلكتروني', value: _profile.email),
              _InfoTile(icon: Icons.phone_outlined, label: 'رقم الهاتف', value: _profile.phone),
              _InfoTile(icon: Icons.location_on_outlined, label: 'الموقع', value: _profile.location),
              _InfoTile(icon: Icons.local_hospital_outlined, label: 'عدد العيادات', value: '${_profile.clinicsCount} عيادة'),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'الإعدادات'),
              const SizedBox(height: AppSpacing.sm),
              _SettingTile(icon: Icons.edit_outlined, title: 'تعديل الملف', onTap: () {
                if (!_saving) _editProfile();
              }),
              _SettingTile(icon: Icons.notifications_none_rounded, title: 'الإشعارات', onTap: () => _showMessage(context: context, message: 'لا توجد إشعارات جديدة.')),
              _SettingTile(icon: Icons.brightness_6_outlined, title: 'المظهر', onTap: () => _showMessage(context: context, message: 'تم ضبط المظهر على الوضع الفاتح')),
              _SettingTile(icon: Icons.support_agent_outlined, title: 'المساعدة', onTap: () => _showMessage(context: context, message: 'سيتم التواصل معك في أقرب وقت')),
              _SettingTile(icon: Icons.info_outline, title: 'عن Medicare', onTap: () => _showMessage(context: context, message: 'Medicare منصة رعاية صحية حديثة')),
              _SettingTile(icon: Icons.logout_rounded, title: 'تسجيل الخروج', color: const Color(0xFFC84C4C), onTap: () => _showLogoutDialog(context)),
            ]),
          ),
        ),
        );
      }

  Future<void> _editProfile() async {
    if (_saving) return;
    final updated = await Navigator.of(context).push<OrganizationProfile>(MaterialPageRoute(builder: (_) => OrganizationProfileFormScreen(profile: _profile)));
    if (updated == null || !mounted) return;
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (organizationId == null || organizationId.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final organization = await FirestoreOrganizationRepository.instance.fetchOrganizationById(organizationId);
      if (organization == null) throw StateError('لم يتم العثور على ملف المؤسسة.');
      await FirestoreOrganizationRepository.instance.saveOrganization(Organization(
        id: organization.id,
        name: updated.name,
        email: updated.email,
        phone: updated.phone,
        location: updated.location,
        status: organization.status,
        firebaseUid: organization.firebaseUid,
        createdAt: organization.createdAt,
        updatedAt: DateTime.now(),
      ));
      final savedOrganization = await FirestoreOrganizationRepository.instance.fetchOrganizationById(organizationId);
      if (savedOrganization == null) throw StateError('تعذر إعادة قراءة بيانات المؤسسة بعد الحفظ.');
      if (mounted) {
        setState(() {
          _profile = OrganizationProfile(
            name: savedOrganization.name,
            email: savedOrganization.email,
            phone: savedOrganization.phone,
            location: savedOrganization.location,
            clinicsCount: _profile.clinicsCount,
          );
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ بيانات المؤسسة بنجاح.')));
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  static void _showMessage({required BuildContext context, required String message}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  static Future<void> _showLogoutDialog(BuildContext context) async => showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('تسجيل الخروج'), content: const Text('هل أنت متأكد من تسجيل الخروج؟'), actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')), FilledButton(onPressed: () { Navigator.of(dialogContext).pop(); AuthNavigation.openSignedOutFlow(context); }, child: const Text('تسجيل الخروج'))]));
}
