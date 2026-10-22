import 'package:flutter/material.dart';

import '../../core/auth/models/clinical_follow_up.dart';
import '../../core/auth/models/medical_case.dart';
import '../../core/firestore/appointment_date_time.dart';
import '../../core/firestore/repositories/firestore_appointment_repository.dart';
import '../../core/firestore/repositories/firestore_medical_case_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';

class MedicalCasesScreen extends StatefulWidget {
  const MedicalCasesScreen({
    super.key,
    required this.organizationId,
    required this.patientId,
    required this.patientName,
    this.allowClinicalWrites = false,
  });

  final String organizationId;
  final String patientId;
  final String patientName;
  final bool allowClinicalWrites;

  @override
  State<MedicalCasesScreen> createState() => _MedicalCasesScreenState();
}

class _MedicalCasesScreenState extends State<MedicalCasesScreen> {
  List<MedicalCase> _cases = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cases = await FirestoreMedicalCaseRepository.instance.fetchCases(
        organizationId: widget.organizationId,
        patientId: widget.patientId,
      );
      if (!mounted) return;
      setState(() => _cases = cases);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createCase() async {
    if (_saving) return;
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => const _MedicalCaseFormDialog(),
    );
    if (values == null || !mounted) return;

    setState(() => _saving = true);
    try {
      await FirestoreMedicalCaseRepository.instance.createCase(
        organizationId: widget.organizationId,
        patientId: widget.patientId,
        title: values['title']! as String,
        type: values['type']! as String,
        startedAt: values['startedAt']! as DateTime,
        diagnosis: values['diagnosis']! as String,
        assessment: values['assessment']! as String,
        notes: values['notes']! as String,
        treatmentPlan: values['treatmentPlan']! as String,
      );
      await _loadCases();
    } catch (error) {
      if (mounted) _showMessage('تعذر فتح الحالة: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openCase(MedicalCase medicalCase) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MedicalCaseDetailsScreen(
          medicalCase: medicalCase,
          patientName: widget.patientName,
          allowClinicalWrites: widget.allowClinicalWrites,
        ),
      ),
    );
    if (mounted) await _loadCases();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('الحالات الطبية - ${widget.patientName}')),
        floatingActionButton: widget.allowClinicalWrites
            ? FloatingActionButton.extended(
                onPressed: _saving ? null : _createCase,
                icon: const Icon(Icons.add),
                label: const Text('حالة جديدة'),
              )
            : null,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _loadCases)
                  : _cases.isEmpty
                      ? const Center(
                          child: EmptyState(
                            title: 'لا توجد حالات طبية',
                            message: 'ستظهر الحالات المسجلة لهذا المريض هنا.',
                            icon: Icons.medical_information_outlined,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            96,
                          ),
                          itemCount: _cases.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final medicalCase = _cases[index];
                            return AppCard(
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.mint,
                                  child: Icon(
                                    Icons.medical_services_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Text(medicalCase.title),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    '${medicalCase.type} • ${_statusLabel(medicalCase.status)} • ${_formatDate(medicalCase.startedAt)}',
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openCase(medicalCase),
                              ),
                            );
                          },
                        ),
        ),
      );
}

class MedicalCaseDetailsScreen extends StatefulWidget {
  const MedicalCaseDetailsScreen({
    super.key,
    required this.medicalCase,
    required this.patientName,
    this.allowClinicalWrites = false,
  });

  final MedicalCase medicalCase;
  final String patientName;
  final bool allowClinicalWrites;

  @override
  State<MedicalCaseDetailsScreen> createState() =>
      _MedicalCaseDetailsScreenState();
}

class _MedicalCaseDetailsScreenState extends State<MedicalCaseDetailsScreen> {
  late MedicalCase _medicalCase = widget.medicalCase;
  List<ClinicalFollowUp> _followUps = const [];
  List<Map<String, dynamic>> _completedAppointments = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final followUps = await FirestoreMedicalCaseRepository.instance
          .fetchFollowUps(medicalCase: _medicalCase);
      var appointments = <Map<String, dynamic>>[];
      if (widget.allowClinicalWrites) {
        final allAppointments = await FirestoreAppointmentRepository.instance
            .fetchAppointmentsForDoctor(
          organizationId: _medicalCase.organizationId,
          doctorId: _medicalCase.doctorId,
        );
        appointments = allAppointments.where((appointment) {
          final dateTime =
              parseAppointmentDateTime(appointment['date'], appointment['time']);
          return appointment['status'] == 'completed' &&
              dateTime != null &&
              !dateTime.isAfter(DateTime.now()) &&
              appointment['organizationId'] == _medicalCase.organizationId &&
              appointment['patientId'] == _medicalCase.patientId &&
              appointment['doctorId'] == _medicalCase.doctorId &&
              appointment['clinicId'] == _medicalCase.clinicId;
        }).toList();
      }
      if (!mounted) return;
      setState(() {
        _followUps = followUps;
        _completedAppointments = appointments;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addFollowUp() async {
    if (_saving || _medicalCase.isClosed) return;
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => _FollowUpFormDialog(
        completedAppointments: _completedAppointments,
      ),
    );
    if (values == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await FirestoreMedicalCaseRepository.instance.createFollowUp(
        medicalCase: _medicalCase,
        visitAt: values['visitAt']! as DateTime,
        assessment: values['assessment']! as String,
        notes: values['notes']! as String,
        recommendations: values['recommendations']! as String,
        nextPlan: values['nextPlan']! as String,
        appointmentId: values['appointmentId'] as String?,
      );
      await _loadDetails();
    } catch (error) {
      if (mounted) _showMessage('تعذر حفظ المتابعة: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeStatus(String status) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await FirestoreMedicalCaseRepository.instance.updateCaseStatus(
        medicalCase: _medicalCase,
        status: status,
      );
      final refreshed = await FirestoreMedicalCaseRepository.instance.fetchCase(
        organizationId: _medicalCase.organizationId,
        patientId: _medicalCase.patientId,
        caseId: _medicalCase.id,
      );
      if (refreshed != null && mounted) {
        setState(() => _medicalCase = refreshed);
      }
    } catch (error) {
      if (mounted) _showMessage('تعذر تحديث الحالة: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _field(String title, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(value.isEmpty ? 'غير مسجل' : value),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الحالة')),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _loadDetails)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      children: [
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _medicalCase.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${_medicalCase.type} • ${_statusLabel(_medicalCase.status)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _field('تاريخ البداية', _formatDate(_medicalCase.startedAt)),
                              _field('التشخيص', _medicalCase.diagnosis),
                              _field('التقييم الطبي', _medicalCase.assessment),
                              _field('الملاحظات', _medicalCase.notes),
                              _field('الخطة العلاجية', _medicalCase.treatmentPlan),
                              if (_medicalCase.completedAt != null)
                                _field('تاريخ الإكمال', _formatDate(_medicalCase.completedAt!)),
                              if (_medicalCase.archivedAt != null)
                                _field('تاريخ الأرشفة', _formatDate(_medicalCase.archivedAt!)),
                            ],
                          ),
                        ),
                        if (widget.allowClinicalWrites &&
                          _medicalCase.status != 'archived') ...[
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              if (_medicalCase.status == 'active')
                                OutlinedButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () => _changeStatus('monitoring'),
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: const Text('بدء المتابعة'),
                                ),
                              if (!_medicalCase.isClosed)
                                OutlinedButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () => _changeStatus('completed'),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('إكمال الحالة'),
                                ),
                              if (!_medicalCase.isClosed)
                                TextButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () => _changeStatus('archived'),
                                  icon: const Icon(Icons.archive_outlined),
                                  label: const Text('أرشفة'),
                                ),
                              if (_medicalCase.status == 'completed')
                                TextButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () => _changeStatus('archived'),
                                  icon: const Icon(Icons.archive_outlined),
                                  label: const Text('أرشفة'),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'سجل المتابعات',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (widget.allowClinicalWrites && !_medicalCase.isClosed)
                              IconButton(
                                tooltip: 'إضافة متابعة',
                                onPressed: _saving ? null : _addFollowUp,
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (_followUps.isEmpty)
                          const EmptyState(
                            title: 'لا توجد متابعات بعد',
                            message: 'تُسجل الزيارات السريرية التي حدثت هنا.',
                            icon: Icons.history,
                          )
                        else
                          for (final followUp in _followUps)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(followUp.visitAt),
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    if (followUp.appointmentId != null) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      Text('موعد مرتبط: ${followUp.appointmentId}'),
                                    ],
                                    const SizedBox(height: AppSpacing.md),
                                    _field('التقييم', followUp.assessment),
                                    _field('الملاحظات', followUp.notes),
                                    _field('التوصيات', followUp.recommendations),
                                    _field('الخطة القادمة', followUp.nextPlan),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
        ),
      );
}

class _MedicalCaseFormDialog extends StatefulWidget {
  const _MedicalCaseFormDialog();

  @override
  State<_MedicalCaseFormDialog> createState() => _MedicalCaseFormDialogState();
}

class _MedicalCaseFormDialogState extends State<_MedicalCaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = List.generate(6, (_) => TextEditingController());
  DateTime _startedAt = DateTime.now();

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startedAt = picked);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('فتح حالة طبية'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _input(0, 'عنوان الحالة', required: true),
                  _input(1, 'نوع الحالة', required: true),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تاريخ البداية'),
                    subtitle: Text(_formatDate(_startedAt)),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: _pickDate,
                  ),
                  _input(2, 'التشخيص'),
                  _input(3, 'التقييم الطبي', maxLines: 3),
                  _input(4, 'الملاحظات', maxLines: 3),
                  _input(5, 'الخطة العلاجية', maxLines: 3),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.of(context).pop(<String, Object?>{
                'title': _controllers[0].text,
                'type': _controllers[1].text,
                'startedAt': _startedAt,
                'diagnosis': _controllers[2].text,
                'assessment': _controllers[3].text,
                'notes': _controllers[4].text,
                'treatmentPlan': _controllers[5].text,
              });
            },
            child: const Text('حفظ الحالة'),
          ),
        ],
      );

  Widget _input(int index, String label, {bool required = false, int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: TextFormField(
          controller: _controllers[index],
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
          validator: required
              ? (value) => value == null || value.trim().isEmpty
                  ? 'هذا الحقل مطلوب'
                  : null
              : null,
        ),
      );
}

class _FollowUpFormDialog extends StatefulWidget {
  const _FollowUpFormDialog({required this.completedAppointments});

  final List<Map<String, dynamic>> completedAppointments;

  @override
  State<_FollowUpFormDialog> createState() => _FollowUpFormDialogState();
}

class _FollowUpFormDialogState extends State<_FollowUpFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = List.generate(4, (_) => TextEditingController());
  DateTime _visitAt = DateTime.now();
  String _appointmentId = '';

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitAt,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _visitAt = picked);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('تسجيل متابعة سريرية'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تاريخ الزيارة'),
                    subtitle: Text(_formatDate(_visitAt)),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: _appointmentId.isEmpty ? _pickDate : null,
                  ),
                  if (widget.completedAppointments.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _appointmentId,
                      decoration: const InputDecoration(
                        labelText: 'موعد مكتمل مرتبط (اختياري)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('بدون ربط بموعد'),
                        ),
                        ...widget.completedAppointments.map((appointment) {
                          final id = appointment['id'].toString();
                          final date = parseAppointmentDateTime(
                            appointment['date'],
                            appointment['time'],
                          );
                          return DropdownMenuItem(
                            value: id,
                            child: Text(
                              '${date == null ? '' : _formatDate(date)} • ${appointment['time'] ?? ''}',
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _appointmentId = value ?? '';
                          if (_appointmentId.isEmpty) return;
                          for (final appointment
                              in widget.completedAppointments) {
                            if (appointment['id'].toString() !=
                                _appointmentId) {
                              continue;
                            }
                            final appointmentAt = parseAppointmentDateTime(
                              appointment['date'],
                              appointment['time'],
                            );
                            if (appointmentAt != null) {
                              _visitAt = DateTime(
                                appointmentAt.year,
                                appointmentAt.month,
                                appointmentAt.day,
                              );
                            }
                            break;
                          }
                        });
                      },
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  _input(0, 'التقييم', required: true, maxLines: 3),
                  _input(1, 'الملاحظات', maxLines: 3),
                  _input(2, 'التوصيات', maxLines: 3),
                  _input(3, 'الخطة القادمة', maxLines: 3),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.of(context).pop(<String, Object?>{
                'visitAt': _visitAt,
                'assessment': _controllers[0].text,
                'notes': _controllers[1].text,
                'recommendations': _controllers[2].text,
                'nextPlan': _controllers[3].text,
                'appointmentId': _appointmentId.isEmpty ? null : _appointmentId,
              });
            },
            child: const Text('حفظ المتابعة'),
          ),
        ],
      );

  Widget _input(int index, String label,
          {bool required = false, int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: TextFormField(
          controller: _controllers[index],
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
          validator: required
              ? (value) => value == null || value.trim().isEmpty
                  ? 'هذا الحقل مطلوب'
                  : null
              : null,
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
}

String _statusLabel(String status) => switch (status) {
      'active' => 'نشطة',
      'monitoring' => 'قيد المتابعة',
      'completed' => 'مكتملة',
      'archived' => 'مؤرشفة',
      _ => 'غير محددة',
    };

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';