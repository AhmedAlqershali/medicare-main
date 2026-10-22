import 'package:flutter/material.dart';

import '../../core/auth/models/medical_catalog_entry.dart';
import '../../core/firestore/repositories/firestore_medical_catalog_repository.dart';
import '../../core/localization/doctor_specialty_display.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';

class MedicalCatalogScreen extends StatefulWidget {
  const MedicalCatalogScreen({super.key});

  @override
  State<MedicalCatalogScreen> createState() => _MedicalCatalogScreenState();
}

class _MedicalCatalogScreenState extends State<MedicalCatalogScreen> {
  final _searchController = TextEditingController();
  List<MedicalCatalogEntry> _entries = const [];
  MedicalCatalogKind _kind = MedicalCatalogKind.specialty;
  bool _loading = true;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repository = FirestoreMedicalCatalogRepository.instance;
      final isAdmin = await repository.isCurrentAdmin();
      if (!isAdmin) {
        if (mounted) setState(() {
          _isAdmin = false;
          _loading = false;
        });
        return;
      }
      var entries = await repository.fetchEntries(includeInactive: true);
      for (var index = 0; index < doctorSpecialties.length; index++) {
        final specialtyName = doctorSpecialties[index];
        if (!entries.any((entry) =>
            entry.kind == MedicalCatalogKind.specialty &&
            entry.nameAr == specialtyName)) {
          await repository.saveEntry(MedicalCatalogEntry(
            id: 'specialty_legacy_$index',
            kind: MedicalCatalogKind.specialty,
            nameAr: specialtyName,
          ));
        }
      }
      entries = await repository.fetchEntries(includeInactive: true);
      final specialties = entries
          .where((entry) => entry.kind == MedicalCatalogKind.specialty)
          .toList();
      final womenHealth = specialties
          .where((entry) => entry.nameAr == 'النساء والتوليد')
          .firstOrNull;
      final eyeCare = specialties
          .where((entry) => entry.nameAr == 'طب العيون')
          .firstOrNull;
      final dentalCare = specialties
          .where((entry) => entry.nameAr == 'طب الأسنان')
          .firstOrNull;
      if (!entries.any((entry) => entry.kind == MedicalCatalogKind.condition)) {
        for (final item in [
          if (womenHealth != null)
            ('condition_pregnancy', 'الحمل', womenHealth.id),
          if (eyeCare != null)
            ('condition_eye_care', 'حالات العيون', eyeCare.id),
          if (dentalCare != null)
            ('condition_dental_care', 'حالات الأسنان', dentalCare.id),
        ]) {
          await repository.saveEntry(MedicalCatalogEntry(
            id: item.$1,
            kind: MedicalCatalogKind.condition,
            nameAr: item.$2,
            specialtyIds: [item.$3],
          ));
        }
      }
      if (!entries.any((entry) => entry.kind == MedicalCatalogKind.service)) {
        for (final item in [
          if (womenHealth != null)
            ('service_pregnancy_follow_up', 'متابعة الحمل', womenHealth.id),
          if (eyeCare != null)
            ('service_eye_assessment', 'تقييم النظر', eyeCare.id),
          if (dentalCare != null)
            ('service_dental_assessment', 'تقييم صحة الفم والأسنان', dentalCare.id),
        ]) {
          await repository.saveEntry(MedicalCatalogEntry(
            id: item.$1,
            kind: MedicalCatalogKind.service,
            nameAr: item.$2,
            specialtyIds: [item.$3],
          ));
        }
      }
      entries = await repository.fetchEntries(includeInactive: true);
      if (!mounted) return;
      setState(() {
        _isAdmin = true;
        _entries = entries;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MedicalCatalogEntry> get _filteredEntries {
    final query = _searchController.text.trim().toLowerCase();
    return _entries.where((entry) {
      if (entry.kind != _kind) return false;
      return query.isEmpty ||
          entry.nameAr.toLowerCase().contains(query) ||
          entry.nameEn.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _edit([MedicalCatalogEntry? entry]) async {
    final saved = await showDialog<MedicalCatalogEntry>(
      context: context,
      builder: (_) => _CatalogEntryDialog(
        initial: entry,
        defaultKind: _kind,
        specialties: _entries
            .where((item) =>
                item.kind == MedicalCatalogKind.specialty &&
                item.active &&
            !item.archived &&
            (entry?.kind != MedicalCatalogKind.specialty ||
              item.parentId == null || item.id == entry?.parentId))
            .toList(),
      ),
    );
    if (saved == null || !mounted) return;
    try {
      await FirestoreMedicalCatalogRepository.instance.saveEntry(saved);
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ عنصر الدليل: $error')),
      );
    }
  }

  Future<void> _changeEntry(
    MedicalCatalogEntry entry, {
    bool? active,
    bool? archived,
  }) async {
    try {
      await FirestoreMedicalCatalogRepository.instance.saveEntry(
        MedicalCatalogEntry(
          id: entry.id,
          kind: entry.kind,
          nameAr: entry.nameAr,
          nameEn: entry.nameEn,
          specialtyIds: entry.specialtyIds,
          parentId: entry.parentId,
          active: active ?? entry.active,
          archived: archived ?? entry.archived,
        ),
      );
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث عنصر الدليل: $error')),
      );
    }
  }

  String _kindLabel(MedicalCatalogKind kind) => switch (kind) {
        MedicalCatalogKind.specialty => 'التخصصات',
        MedicalCatalogKind.condition => 'الأمراض والحالات',
        MedicalCatalogKind.service => 'الخدمات والإجراءات',
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الدليل الطبي المركزي')),
        floatingActionButton: _isAdmin
            ? FloatingActionButton.extended(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('إضافة عنصر'),
              )
            : null,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : !_isAdmin
                  ? const Center(
                      child: Text('هذه الصفحة متاحة للمسؤول المخوّل فقط.'),
                    )
                  : _error != null
                      ? ErrorState(message: _error!, onRetry: _load)
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(children: [
                                DropdownButtonFormField<MedicalCatalogKind>(
                                  value: _kind,
                                  decoration: const InputDecoration(
                                    labelText: 'نوع الدليل',
                                  ),
                                  items: MedicalCatalogKind.values
                                      .map((kind) => DropdownMenuItem(
                                            value: kind,
                                            child: Text(_kindLabel(kind)),
                                          ))
                                      .toList(),
                                  onChanged: (value) => setState(() {
                                    if (value != null) _kind = value;
                                  }),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: 'بحث في الدليل',
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                              ]),
                            ),
                            Expanded(
                              child: _filteredEntries.isEmpty
                                  ? const Center(child: Text('لا توجد عناصر مطابقة.'))
                                  : ListView.builder(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.xl,
                                      ),
                                      itemCount: _filteredEntries.length,
                                      itemBuilder: (context, index) {
                                        final entry = _filteredEntries[index];
                                        final inactive = !entry.active || entry.archived;
                                        final linked = _entries
                                            .where((item) => entry.specialtyIds.contains(item.id))
                                            .map((item) => item.displayName)
                                            .join('، ');
                                        return ListTile(
                                          title: Text(entry.displayName),
                                          subtitle: Text([
                                            if (entry.nameEn.isNotEmpty && entry.nameAr.isNotEmpty)
                                              entry.nameEn,
                                            if (entry.parentId != null)
                                              'فرعي من ${_entries.where((item) => item.id == entry.parentId).firstOrNull?.displayName ?? ''}',
                                            if (linked.isNotEmpty) linked,
                                            if (inactive) 'معطل أو مؤرشف',
                                          ].join(' • ')),
                                          trailing: PopupMenuButton<String>(
                                            onSelected: (action) {
                                              if (action == 'edit') _edit(entry);
                                              if (action == 'disable') {
                                                _changeEntry(entry, active: false);
                                              }
                                              if (action == 'enable') {
                                                _changeEntry(entry, active: true);
                                              }
                                              if (action == 'archive') {
                                                _changeEntry(entry, active: false, archived: true);
                                              }
                                            },
                                            itemBuilder: (_) => [
                                              const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                              if (entry.active && !entry.archived)
                                                const PopupMenuItem(value: 'disable', child: Text('تعطيل')),
                                              if (!entry.active && !entry.archived)
                                                const PopupMenuItem(value: 'enable', child: Text('تفعيل')),
                                              if (!entry.archived)
                                                const PopupMenuItem(value: 'archive', child: Text('أرشفة')),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
        ),
      );
}

class _CatalogEntryDialog extends StatefulWidget {
  const _CatalogEntryDialog({
    required this.initial,
    required this.defaultKind,
    required this.specialties,
  });

  final MedicalCatalogEntry? initial;
  final MedicalCatalogKind defaultKind;
  final List<MedicalCatalogEntry> specialties;

  @override
  State<_CatalogEntryDialog> createState() => _CatalogEntryDialogState();
}

class _CatalogEntryDialogState extends State<_CatalogEntryDialog> {
  late final _arabic = TextEditingController(text: widget.initial?.nameAr ?? '');
  late final _english = TextEditingController(text: widget.initial?.nameEn ?? '');
  late MedicalCatalogKind _kind = widget.initial?.kind ?? widget.defaultKind;
  late String? _parentId = widget.initial?.parentId;
  late Set<String> _specialtyIds = widget.initial?.specialtyIds.toSet() ?? {};

  @override
  void dispose() {
    _arabic.dispose();
    _english.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial == null ? 'إضافة إلى الدليل' : 'تعديل عنصر الدليل'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (widget.initial == null)
                DropdownButtonFormField<MedicalCatalogKind>(
                  value: _kind,
                  decoration: const InputDecoration(labelText: 'نوع العنصر'),
                  items: MedicalCatalogKind.values
                      .map((kind) => DropdownMenuItem(
                            value: kind,
                            child: Text(switch (kind) {
                              MedicalCatalogKind.specialty => 'تخصص',
                              MedicalCatalogKind.condition => 'مرض أو حالة',
                              MedicalCatalogKind.service => 'خدمة أو إجراء',
                            }),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    if (value != null) _kind = value;
                  }),
                ),
              TextField(controller: _arabic, decoration: const InputDecoration(labelText: 'الاسم بالعربية')),
              TextField(controller: _english, decoration: const InputDecoration(labelText: 'الاسم بالإنجليزية (اختياري)'), textDirection: TextDirection.ltr),
              if (_kind == MedicalCatalogKind.specialty)
                DropdownButtonFormField<String?>(
                  value: _parentId,
                  decoration: const InputDecoration(labelText: 'التخصص الأب (اختياري)'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('تخصص رئيسي')),
                    ...widget.specialties
                        .where((entry) => entry.id != widget.initial?.id)
                        .map((entry) => DropdownMenuItem<String?>(
                              value: entry.id,
                              child: Text(entry.displayName),
                            )),
                  ],
                  onChanged: (value) => setState(() => _parentId = value),
                ),
              if (_kind != MedicalCatalogKind.specialty) ...[
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('التخصصات المرتبطة', style: Theme.of(context).textTheme.titleSmall),
                ),
                for (final specialty in widget.specialties)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _specialtyIds.contains(specialty.id),
                    title: Text(specialty.displayName),
                    onChanged: (selected) => setState(() {
                      if (selected == true) {
                        _specialtyIds.add(specialty.id);
                      } else {
                        _specialtyIds.remove(specialty.id);
                      }
                    }),
                  ),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (_arabic.text.trim().isEmpty && _english.text.trim().isEmpty) return;
              if (_kind != MedicalCatalogKind.specialty && _specialtyIds.isEmpty) return;
              final id = widget.initial?.id ??
                  FirestoreMedicalCatalogRepository.instance.newId();
              Navigator.pop(
                context,
                MedicalCatalogEntry(
                  id: id,
                  kind: _kind,
                  nameAr: _arabic.text.trim(),
                  nameEn: _english.text.trim(),
                  specialtyIds: _specialtyIds.toList(),
                  parentId: _parentId,
                  active: widget.initial?.active ?? true,
                  archived: widget.initial?.archived ?? false,
                ),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      );
}
