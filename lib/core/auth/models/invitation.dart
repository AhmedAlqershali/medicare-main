import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_role.dart';
import 'invitation_status.dart';

class Invitation {
  const Invitation({
    required this.id,
    required this.email,
    required this.role,
    required this.invitedBy,
    required this.organizationId,
    required this.status,
    this.doctorId,
    this.patientId,
    this.clinicId,
    this.expiresAt,
    this.userId,
    this.acceptedAt,
  });

  final String id;
  final String email;
  final AccountRole role;
  final String invitedBy;
  final String organizationId;
  final InvitationStatus status;
  final String? doctorId;
  final String? patientId;
  final String? clinicId;
  final DateTime? expiresAt;
  final String? userId;
  final DateTime? acceptedAt;

  String get recipientEmail => email;

  bool get isCurrentlyValid => status == InvitationStatus.pending && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  Invitation copyWith({InvitationStatus? status, String? userId, DateTime? acceptedAt}) => Invitation(
        id: id,
        email: email,
        role: role,
        invitedBy: invitedBy,
        organizationId: organizationId,
        status: status ?? this.status,
        doctorId: doctorId,
        patientId: patientId,
        clinicId: clinicId,
        expiresAt: expiresAt,
        userId: userId ?? this.userId,
        acceptedAt: acceptedAt ?? this.acceptedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'recipientEmail': email,
        'role': role.name,
        'invitedBy': invitedBy,
        'organizationId': organizationId,
        'status': status.name,
        'doctorId': doctorId,
        'patientId': patientId,
        'clinicId': clinicId,
        'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!.toUtc()),
        'userId': userId,
        'acceptedAt': acceptedAt?.toUtc().toIso8601String(),
      };

  static Invitation fromMap(Map<String, dynamic> map) => Invitation(
        id: map['id'] as String? ?? '',
        email: map['recipientEmail'] as String? ?? map['email'] as String? ?? '',
        role: AccountRole.values.firstWhere(
          (item) => item.name == (map['role'] as String? ?? AccountRole.patient.name),
          orElse: () => AccountRole.patient,
        ),
        invitedBy: map['invitedBy'] as String? ?? '',
        organizationId: map['organizationId'] as String? ?? '',
        status: InvitationStatus.values.firstWhere(
          (item) => item.name == (map['status'] as String? ?? InvitationStatus.pending.name),
          orElse: () => InvitationStatus.pending,
        ),
        doctorId: map['doctorId'] as String?,
        patientId: map['patientId'] as String?,
        clinicId: map['clinicId'] as String?,
        expiresAt: _dateFromMap(map['expiresAt']),
        userId: map['userId'] as String?,
        acceptedAt: _dateFromMap(map['acceptedAt']),
      );

  static DateTime? _dateFromMap(Object? value) => switch (value) {
        String value => DateTime.tryParse(value),
        Timestamp value => value.toDate(),
        _ => null,
      };
}
