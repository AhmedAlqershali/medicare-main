part of 'organization_clinics_screen.dart';

class _OrganizationClinicDetailsScreenState extends State<OrganizationClinicDetailsScreen> {
  late OrganizationClinic _clinic = widget.clinic;
  bool _loadingAppointments = true;
  int _appointmentsCount = 0;
  String? _appointmentsError;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final organizationId = FirebaseAuthRepository.instance.session.organizationId;
    if (organizationId == null || organizationId.isEmpty) {
      if (mounted) setState(() {
        _loadingAppointments = false;
        _appointmentsError = 'لا توجد مؤسسة نشطة مرتبطة بالجلسة الحالية.';
      });
      return;
    }
    try {
      final appointments = await FirestoreAppointmentRepository.instance.fetchAppointmentsForOrganization(organizationId);
      if (mounted) setState(() {
        _loadingAppointments = false;
        _appointmentsCount = appointments.where((appointment) => appointment['clinicId'] == _clinic.id || appointment['clinicName'] == _clinic.name).length;
      });
    } catch (error) {
      if (mounted) setState(() {
        _loadingAppointments = false;
        _appointmentsError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل العيادة'),
          leading: BackButton(onPressed: () => Navigator.of(context).pop(_clinic)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppCard(
                child: Row(children: [
                  Container(width: 68, height: 68, decoration: BoxDecoration(color: _clinic.color, borderRadius: BorderRadius.circular(19)), child: Icon(_clinic.icon, color: AppColors.primaryDark, size: 30)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_clinic.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(_clinic.location, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    StatusBadge(label: _clinic.status, color: _clinic.status == 'نشطة' ? AppColors.success : AppColors.muted),
                  ])),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'المعلومات الأساسية'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(children: [
                  InfoRow(icon: Icons.location_on_outlined, label: 'الموقع', value: _clinic.location),
                  const Divider(height: AppSpacing.lg),
                  InfoRow(icon: Icons.phone_outlined, label: 'رقم الهاتف', value: _clinic.phone),
                  const Divider(height: AppSpacing.lg),
                  InfoRow(icon: Icons.info_outline, label: 'الحالة', value: _clinic.status),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'الإحصاءات'),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                Expanded(child: _MiniStat(label: 'الأطباء', value: '${_clinic.doctorsCount}', icon: Icons.medical_information_outlined)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _MiniStat(label: 'الأقسام', value: '${_clinic.departmentsCount}', icon: Icons.category_outlined)),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                Expanded(child: _MiniStat(label: 'المرضى', value: '${_clinic.patientsCount}', icon: Icons.people_outline)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _MiniStat(label: 'المواعيد', value: _loadingAppointments ? '...' : _appointmentsError == null ? '$_appointmentsCount' : 'خطأ', icon: Icons.calendar_month_outlined)),
              ]),
              if (_appointmentsError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_appointmentsError!, style: const TextStyle(color: Color(0xFFC84C4C), fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'الأقسام'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                  for (final department in _clinic.departments) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(10)), child: Text(department, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700))),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(width: double.infinity, child: PrimaryButton(label: 'تعديل بيانات العيادة', icon: Icons.edit_outlined, onPressed: () async {
                if (!mounted) return;
                final navigator = Navigator.of(context);
                final updated = await navigator.push<OrganizationClinic>(MaterialPageRoute<OrganizationClinic>(builder: (_) => OrganizationClinicFormScreen(clinic: _clinic)));
                if (!mounted) return;
                if (updated != null) {
                  setState(() => _clinic = updated);
                  navigator.pop(updated);
                }
              })),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => setState(() => _clinic = _clinic.copyWith(status: _clinic.status == 'نشطة' ? 'غير متاحة' : 'نشطة')), icon: const Icon(Icons.swap_horiz_rounded), label: const Text('تغيير الحالة'))),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _addDepartment, icon: const Icon(Icons.add_rounded), label: const Text('إدارة الأقسام'))),
            ]),
          ),
        ),
      );

  Future<void> _addDepartment() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('إضافة قسم'),
      content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'اسم القسم')),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()), child: const Text('إضافة')),
      ],
    ));
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      final updated = _clinic.copyWith(departments: [..._clinic.departments, result]);
      setState(() => _clinic = updated);
      if (mounted) Navigator.of(context).pop(updated);
    }
  }
}
