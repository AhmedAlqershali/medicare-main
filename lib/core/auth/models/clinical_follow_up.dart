import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicalFollowUp {
  const ClinicalFollowUp({
    required this.id,
    required this.caseId,
    required this.patientId,
    required this.organizationId,
    required this.doctorId,
    required this.clinicId,
    required this.visitAt,
    required this.assessment,
    required this.notes,
    required this.recommendations,
    required this.nextPlan,
    required this.createdAt,
    this.appointmentId,
    this.caseData = const {},
    this.nextAppointmentAt,
  });

  final String id;
  final String caseId;
  final String patientId;
  final String organizationId;
  final String doctorId;
  final String clinicId;
  final DateTime visitAt;
  final String assessment;
  final String notes;
  final String recommendations;
  final String nextPlan;
  final DateTime createdAt;
  final String? appointmentId;
  final Map<String, dynamic> caseData;
  final DateTime? nextAppointmentAt;

  static bool isNextAppointmentAfterVisit({
    required DateTime visitAt,
    required DateTime nextAppointmentAt,
  }) =>
      nextAppointmentAt.isAfter(visitAt);

  factory ClinicalFollowUp.fromMap(String id, Map<String, dynamic> map) =>
      ClinicalFollowUp(
        id: id,
        caseId: map['caseId'] as String? ?? '',
        patientId: map['patientId'] as String? ?? '',
        organizationId: map['organizationId'] as String? ?? '',
        doctorId: map['doctorId'] as String? ?? '',
        clinicId: map['clinicId'] as String? ?? '',
        visitAt: _date(map['visitAt']),
        assessment: map['assessment'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        recommendations: map['recommendations'] as String? ?? '',
        nextPlan: map['nextPlan'] as String? ?? '',
        createdAt: _date(map['createdAt']),
        appointmentId: map['appointmentId'] as String?,
        caseData: map['caseData'] is Map
          ? Map<String, dynamic>.from(map['caseData'] as Map)
          : const {},
        nextAppointmentAt: map['nextAppointmentAt'] == null
          ? null
          : _date(map['nextAppointmentAt']),
      );

  static DateTime _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}