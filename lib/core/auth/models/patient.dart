import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_status.dart';

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
    this.notes,
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
  final String? notes;
  final String? problemLocation;
  final String? medicalNotes;
  final List<String> medicalNotesHistory;
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
      'firebaseUid': firebaseUid,
      'medicalNotesHistory': medicalNotesHistory,
    };

    if (phone != null) map['phone'] = phone;
    if (birthDate != null) map['birthDate'] = birthDate;
    if (gender != null) map['gender'] = gender;
    if (notes != null) map['notes'] = notes;
    if (problemLocation != null) {
      map['problemLocation'] = problemLocation;
    }
    if (medicalNotes != null) {
      map['medicalNotes'] = medicalNotes;
    }
    if (createdAt != null) {
      map['createdAt'] = createdAt!.toUtc().toIso8601String();
    }
    if (updatedAt != null) {
      map['updatedAt'] = updatedAt!.toUtc().toIso8601String();
    }

    return map;
  }

  static Patient fromMap(Map<String, dynamic> map) => Patient(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    email: map['email'] as String? ?? '',
    doctorId: map['doctorId'] as String? ?? '',
    organizationId: map['organizationId'] as String? ?? '',
    clinicId: map['clinicId'] as String?,
    status: AccountStatus.values.firstWhere(
          (item) =>
      item.name ==
          (map['status'] as String? ?? AccountStatus.active.name),
      orElse: () => AccountStatus.active,
    ),
    accountActivated: map['accountActivated'] as bool? ?? false,
    initials: map['initials'] as String? ?? '',
    phone: map['phone'] as String?,
    birthDate: map['birthDate'] as String?,
    gender: map['gender'] as String?,
    notes: map['notes'] as String?,
    problemLocation: map['problemLocation'] as String?,
    medicalNotes: map['medicalNotes'] as String?,
    medicalNotesHistory:
    (map['medicalNotesHistory'] as List<dynamic>?)
        ?.whereType<String>()
        .toList() ??
        const [],
    firebaseUid: map['firebaseUid'] as String?,
    createdAt: _dateFromMap(map['createdAt']),
    updatedAt: _dateFromMap(map['updatedAt']),
  );

  static DateTime? _dateFromMap(Object? value) => switch (value) {
        String value => DateTime.tryParse(value),
        Timestamp value => value.toDate(),
        _ => null,
      };
}
