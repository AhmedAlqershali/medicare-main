import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/models/account_role.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.role,
    this.organizationId,
    this.clinicId,
    this.doctorId,
    this.patientId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String email;
  final AccountRole role;
  final String? organizationId;
  final String? clinicId;
  final String? doctorId;
  final String? patientId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'role': role.name,
        'organizationId': organizationId,
        'clinicId': clinicId,
        'doctorId': doctorId,
        'patientId': patientId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  static UserProfile fromMap(Map<String, dynamic> map) {
    final roleValue = map['role'] as String?;
    final role = AccountRole.values.firstWhere(
      (candidate) => candidate.name == roleValue,
      orElse: () => throw FormatException('Unknown user profile role.'),
    );
    return UserProfile(
        uid: map['uid'] as String? ?? '',
        email: map['email'] as String? ?? '',
        role: role,
        organizationId: map['organizationId'] as String?,
        clinicId: map['clinicId'] as String?,
        doctorId: map['doctorId'] as String?,
        patientId: map['patientId'] as String?,
        createdAt: _dateFromMap(map['createdAt']) ?? DateTime.now(),
        updatedAt: _dateFromMap(map['updatedAt']) ?? DateTime.now(),
      );
  }

  static DateTime? _dateFromMap(Object? value) => switch (value) {
        String value => DateTime.tryParse(value),
        Timestamp value => value.toDate(),
        _ => null,
      };
}
