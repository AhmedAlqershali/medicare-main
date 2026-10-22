import 'package:cloud_firestore/cloud_firestore.dart';

import 'pregnancy_details.dart';

class MedicalCase {
  const MedicalCase({
    required this.id,
    required this.patientId,
    required this.organizationId,
    required this.doctorId,
    required this.clinicId,
    required this.title,
    required this.type,
    required this.startedAt,
    required this.diagnosis,
    required this.assessment,
    required this.notes,
    required this.treatmentPlan,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.archivedAt,
    this.archiveReason,
    this.pregnancyDetails,
  });

  final String id;
  final String patientId;
  final String organizationId;
  final String doctorId;
  final String clinicId;
  final String title;
  final String type;
  final DateTime startedAt;
  final String diagnosis;
  final String assessment;
  final String notes;
  final String treatmentPlan;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? archivedAt;
  final String? archiveReason;
  final PregnancyDetails? pregnancyDetails;

  bool get isClosed => status == 'completed' || status == 'archived';

  factory MedicalCase.fromMap(String id, Map<String, dynamic> map) =>
      MedicalCase(
        id: id,
        patientId: map['patientId'] as String? ?? '',
        organizationId: map['organizationId'] as String? ?? '',
        doctorId: map['doctorId'] as String? ?? '',
        clinicId: map['clinicId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        type: map['type'] as String? ?? '',
        startedAt: _date(map['startedAt']),
        diagnosis: map['diagnosis'] as String? ?? '',
        assessment: map['assessment'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        treatmentPlan: map['treatmentPlan'] as String? ?? '',
        status: map['status'] as String? ?? 'active',
        createdAt: _date(map['createdAt']),
        completedAt: _optionalDate(map['completedAt']),
        archivedAt: _optionalDate(map['archivedAt']),
        archiveReason: map['archiveReason'] as String?,
        pregnancyDetails: map['pregnancy'] is Map
            ? PregnancyDetails.fromMap(
                Map<String, dynamic>.from(map['pregnancy'] as Map),
              )
            : null,
      );

  static DateTime _date(Object? value) =>
      _optionalDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);

  static DateTime? _optionalDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}