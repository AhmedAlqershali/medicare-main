import 'account_status.dart';
import 'medical_note.dart';

class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.email,
    required this.doctorId,
    required this.organizationId,
    required this.clinicId,
    required this.status,
    required this.accountActivated,
    required this.initials,
    this.firebaseUid,
    this.phone,
    this.birthDate,
    this.gender,
    this.problemLocation,
    this.medicalNotes,
    this.medicalNotesHistory = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String doctorId;
  final String organizationId;
  final String? clinicId;
  final AccountStatus status;
  final bool accountActivated;
  final String initials;
  final String? firebaseUid;
  final String? phone;
  final String? birthDate;
  final String? gender;

  /// الملاحظة القديمة الموجودة في السجلات الحالية.
  ///
  /// لا نحذفها للحفاظ على التوافق مع البيانات الموجودة مسبقًا.
  final String? medicalNotes;

  /// سجل جميع الملاحظات الطبية.
  ///
  /// الملاحظات الجديدة تضاف إلى هذا السجل ولا تستبدل
  /// الملاحظات السابقة.
  final List<MedicalNote> medicalNotesHistory;

  /// Stable key for the body/problem location.
  final String? problemLocation;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'doctorId': doctorId,
      'organizationId': organizationId,
      'clinicId': clinicId,
      'status': status.name,
      'accountActivated': accountActivated,
      'initials': initials,
    };

    if (phone != null) {
    map['phone'] = phone;
    }

    if (birthDate != null) {
    map['birthDate'] = birthDate;
    }

    if (gender != null) {
    map['gender'] = gender;
    }

    if (problemLocation != null &&
    problemLocation!.trim().isNotEmpty) {
    map['problemLocation'] = problemLocation;
    }

    /// نحافظ على الحقل القديم كما هو.
    if (medicalNotes != null &&
    medicalNotes!.trim().isNotEmpty) {
    map['medicalNotes'] = medicalNotes!.trim();
    }

    /// السجل الجديد للملاحظات.
    if (medicalNotesHistory.isNotEmpty) {
    map['medicalNotesHistory'] = medicalNotesHistory
        .map((note) => note.toMap())
        .toList();
    }

    map['firebaseUid'] = firebaseUid;

    if (createdAt != null) {
    map['createdAt'] =
    createdAt!.toUtc().toIso8601String();
    }

    if (updatedAt != null) {
    map['updatedAt'] =
    updatedAt!.toUtc().toIso8601String();
    }

    return map;

  }

  static Patient fromMap(Map<String, dynamic> map) {
    final history = <MedicalNote>[];

    final rawHistory = map['medicalNotesHistory'];

    if (rawHistory is List) {
    for (final item in rawHistory) {
    if (item is Map) {
    history.add(
    MedicalNote.fromMap(
    Map<String, dynamic>.from(item),
    ),
    );
    }
    }
    }

    /// توافق مع البيانات القديمة:
    ///
    /// إذا كان هناك medicalNotes قديم وليس موجودًا
    /// في history، نضيفه للقراءة فقط كأول ملاحظة.
    final legacyNotes =
    map['medicalNotes'] as String?;

    if (legacyNotes != null &&
    legacyNotes.trim().isNotEmpty &&
    !history.any(
    (note) => note.text.trim() == legacyNotes.trim(),
    )) {
    history.insert(
    0,
    MedicalNote(
    id: 'legacy-medical-note',
    text: legacyNotes.trim(),
    createdAt:
    map['createdAt'] is String
    ? DateTime.tryParse(
    map['createdAt'] as String,
    )
        : null,
    ),
    );
    }

    return Patient(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    email: map['email'] as String? ?? '',
    doctorId: map['doctorId'] as String? ?? '',
    organizationId:
    map['organizationId'] as String? ?? '',
    clinicId: map['clinicId'] as String?,
    status: AccountStatus.values.firstWhere(
    (item) =>
    item.name ==
    (map['status'] as String? ??
    AccountStatus.active.name),
    orElse: () => AccountStatus.active,
    ),
    accountActivated:
    map['accountActivated'] as bool? ?? false,
    initials: map['initials'] as String? ?? '',
    phone: map['phone'] as String?,
    birthDate: map['birthDate'] as String?,
    gender: map['gender'] as String?,
    problemLocation:
    map['problemLocation'] as String?,
    medicalNotes:
    legacyNotes,
    medicalNotesHistory:
    List<MedicalNote>.unmodifiable(history),
    firebaseUid:
    map['firebaseUid'] as String?,
    createdAt: map['createdAt'] is String
    ? DateTime.tryParse(
    map['createdAt'] as String,
    )
        : null,
    updatedAt: map['updatedAt'] is String
    ? DateTime.tryParse(
    map['updatedAt'] as String,
    )
        : null,
    );
  }
}
