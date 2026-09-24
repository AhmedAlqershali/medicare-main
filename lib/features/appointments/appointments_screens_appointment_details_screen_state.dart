part of 'appointments_screens.dart';
({String label, Color color}) _statusDetails(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.upcoming:
      return (label: 'قادم', color: AppColors.primary);
    case AppointmentStatus.completed:
      return (label: 'مكتمل', color: AppColors.success);
    case AppointmentStatus.cancelled:
      return (label: 'ملغي', color: AppColors.warning);
  }

}
class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  late AppointmentStatus _status = widget.appointment.status;

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment.copyWith(status: _status);
    final status = _statusDetails(_status);
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الموعد'), leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Row(
                  children: [
                    AppAvatar(initials: appointment.doctorInitials, size: 66, backgroundColor: appointment.avatarColor),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appointment.doctorName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(appointment.specialty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(onPressed: () => _openDoctor(appointment), child: const Text('عرض الملف')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('العيادة', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.local_hospital_outlined, color: AppColors.primary, size: 25),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appointment.clinicName, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 3),
                          Text(appointment.location, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => _openClinic(appointment), icon: const Icon(Icons.chevron_left_rounded), color: AppColors.primary, tooltip: 'عرض العيادة'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('معلومات الموعد', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  children: [
                    _DetailRow(label: 'التاريخ', value: appointment.date, icon: Icons.calendar_month_outlined),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(label: 'الوقت', value: appointment.time, icon: Icons.schedule_outlined),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(label: 'نوع الموعد', value: appointment.type, icon: Icons.medical_services_outlined),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(label: 'الحالة', value: status.label, icon: Icons.info_outline, valueColor: status.color),
                  ],
                ),
              ),
              if (appointment.notes != null) ...[
                const SizedBox(height: AppSpacing.xl),
                Text('ملاحظات الموعد', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                AppCard(child: Text(appointment.notes!, style: Theme.of(context).textTheme.bodyLarge)),
              ],
            ],
          ),
        ),
      ),
    );
  }
  void _openDoctor(AppointmentData appointment) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DoctorsListScreen()));

  void _openClinic(AppointmentData appointment) async {
    final clinics = await const ClinicsRepositoryImpl().getClinics();
    final clinic = clinics.where((item) => item.name == appointment.clinicName).firstOrNull;
    if (clinic == null || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ClinicDetailsScreen(clinic: ClinicData(
      name: clinic.name,
      category: clinic.category,
      location: clinic.location,
      description: clinic.description,
      hours: clinic.hours,
      specialties: List<String>.from(clinic.specialties),
      status: clinic.status,
      icon: clinic.icon,
      color: Color(clinic.colorValue),
      doctors: clinic.doctors.map((doctor) => ClinicDoctorData(
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
    ))));
  }
}

const _patientAppointmentDetailsReadOnly = true;