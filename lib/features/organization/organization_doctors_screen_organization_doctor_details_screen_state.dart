part of 'organization_doctors_screen.dart';

class _OrganizationDoctorDetailsScreenState extends State<OrganizationDoctorDetailsScreen> {
  late OrganizationDoctor _doctor = widget.doctor;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الطبيب'), leading: BackButton(onPressed: () => Navigator.of(context).pop(_doctor))),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppCard(
                child: Row(children: [
                  AppAvatar(initials: _doctor.initials, size: 72, backgroundColor: _doctor.avatarColor),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_doctor.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(_doctor.specialty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    StatusBadge(label: _doctor.status, color: _doctor.status == 'نشط' ? AppColors.success : AppColors.muted),
                  ])),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'معلومات الطبيب'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(children: [
                  InfoRow(icon: Icons.local_hospital_outlined, label: 'العيادة', value: _doctor.clinic),
                  const Divider(height: AppSpacing.lg),
                  InfoRow(icon: Icons.phone_outlined, label: 'رقم الهاتف', value: _doctor.phone),
                  const Divider(height: AppSpacing.lg),
                  InfoRow(icon: Icons.email_outlined, label: 'البريد الإلكتروني', value: _doctor.email),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'الجدول'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Row(children: [
                  const Icon(Icons.access_time_outlined, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(_doctor.scheduleSummary, style: Theme.of(context).textTheme.bodyLarge)),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(width: double.infinity, child: PrimaryButton(label: 'تعديل بيانات الطبيب', icon: Icons.edit_outlined, onPressed: () async {
                final updated = await Navigator.of(context).push<OrganizationDoctor>(MaterialPageRoute<OrganizationDoctor>(builder: (_) => OrganizationDoctorFormScreen(doctor: _doctor)));
                if (updated == null || !mounted) return;
                try {
                  final organizationId = FirebaseAuthRepository.instance.session.organizationId;
                  if (organizationId == null || organizationId.isEmpty) throw StateError('لا توجد مؤسسة مرتبطة بالجلسة الحالية.');
                  final doctor = await FirestoreDoctorRepository.instance.fetchDoctorByIdForOrganization(organizationId, updated.id);
                  if (doctor == null) throw StateError('تعذر العثور على الطبيب داخل المؤسسة الحالية.');
                  await FirestoreDoctorRepository.instance.saveDoctor(Doctor(
                    id: doctor.id,
                    name: updated.name,
                    email: updated.email,
                    organizationId: doctor.organizationId,
                    specialty: updated.specialty,
                    status: _accountStatus(updated.status),
                    initials: updated.initials,
                    availability: doctor.availability,
                    clinic: updated.clinic,
                    clinicId: updated.clinicId,
                    phone: updated.phone,
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
                  if (mounted) setState(() => _doctor = updated.copyWith(availability: doctor.availability));
                } catch (error) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              })),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _toggleStatus, icon: const Icon(Icons.swap_horiz_rounded), label: const Text('تغيير الحالة'))),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _showSchedule(), icon: const Icon(Icons.calendar_month_outlined), label: const Text('عرض الجدول'))),
            ]),
          ),
        ),
      );

  AccountStatus _accountStatus(String status) => switch (status) {
        'نشط' || 'active' => AccountStatus.active,
        'غير متاح' || 'inactive' => AccountStatus.inactive,
        _ => AccountStatus.pending,
      };

  Future<void> _toggleStatus() async {
    try {
      final organizationId = FirebaseAuthRepository.instance.session.organizationId;
      if (organizationId == null || organizationId.isEmpty) throw StateError('لا توجد مؤسسة مرتبطة بالجلسة الحالية.');
      final doctor = await FirestoreDoctorRepository.instance.fetchDoctorByIdForOrganization(organizationId, _doctor.id);
      if (doctor == null) throw StateError('تعذر العثور على الطبيب داخل المؤسسة الحالية.');
      final nextStatus = _doctor.status == 'نشط' ? AccountStatus.inactive : AccountStatus.active;
      await FirestoreDoctorRepository.instance.saveDoctor(Doctor(
        id: doctor.id,
        name: doctor.name,
        email: doctor.email,
        organizationId: doctor.organizationId,
        specialty: doctor.specialty,
        status: nextStatus,
        initials: doctor.initials,
        availability: doctor.availability,
        clinic: doctor.clinic,
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
      if (mounted) setState(() => _doctor = _doctor.copyWith(status: nextStatus == AccountStatus.active ? 'نشط' : 'غير متاح'));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _showSchedule() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('جدول الطبيب'),
        content: _doctor.availability.isEmpty
            ? const Text('لا يوجد جدول متاح لهذا الطبيب.')
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: _doctor.availability.entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Text('${entry.key}: ${entry.value.join('، ')}'),
                          ))
                      .toList(),
                ),
              ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق'))],
      ),
    );
  }
}
