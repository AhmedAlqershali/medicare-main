enum MedicalCatalogKind { specialty, condition, service }

class MedicalCatalogEntry {
  const MedicalCatalogEntry({
    required this.id,
    required this.kind,
    required this.nameAr,
    this.nameEn = '',
    this.specialtyIds = const [],
    this.parentId,
    this.repeatIntervalMonths,
    this.active = true,
    this.archived = false,
  });

  final String id;
  final MedicalCatalogKind kind;
  final String nameAr;
  final String nameEn;
  final List<String> specialtyIds;
  final String? parentId;
  final int? repeatIntervalMonths;
  final bool active;
  final bool archived;

  String get displayName => nameAr.isNotEmpty ? nameAr : nameEn;

  factory MedicalCatalogEntry.fromMap(String id, Map<String, dynamic> map) {
    final kindName = map['kind'] as String?;
    return MedicalCatalogEntry(
      id: id,
      kind: MedicalCatalogKind.values.firstWhere(
        (kind) => kind.name == kindName,
        orElse: () => throw FormatException('نوع عنصر الدليل غير معروف.'),
      ),
      nameAr: map['nameAr'] as String? ?? '',
      nameEn: map['nameEn'] as String? ?? '',
      specialtyIds: (map['specialtyIds'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      parentId: map['parentId'] as String?,
      repeatIntervalMonths: (map['repeatIntervalMonths'] as num?)?.toInt(),
      active: map['active'] as bool? ?? true,
      archived: map['archived'] as bool? ?? false,
    );
  }
}
