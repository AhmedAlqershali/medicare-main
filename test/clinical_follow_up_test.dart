import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/core/auth/models/clinical_follow_up.dart';

void main() {
  test('parses extensible case data and next appointment independently', () {
    final visit = DateTime.utc(2026, 10, 20);
    final nextAppointment = DateTime.utc(2026, 10, 27);
    final followUp = ClinicalFollowUp.fromMap('follow-up-a', {
      'id': 'follow-up-a',
      'caseId': 'case-a',
      'patientId': 'patient-a',
      'organizationId': 'org-a',
      'doctorId': 'doctor-a',
      'clinicId': 'clinic-a',
      'visitAt': Timestamp.fromDate(visit),
      'createdAt': Timestamp.fromDate(visit),
      'assessment': 'Stable',
      'notes': 'Review measurements',
      'recommendations': '',
      'nextPlan': 'Return next week',
      'caseData': {'bloodPressure': '120/80', 'weightKg': 72},
      'nextAppointmentAt': Timestamp.fromDate(nextAppointment),
    });

    expect(followUp.visitAt, visit);
    expect(followUp.caseData, {'bloodPressure': '120/80', 'weightKg': 72});
    expect(followUp.nextAppointmentAt, nextAppointment);
    expect(followUp.patientId, 'patient-a');
    expect(followUp.organizationId, 'org-a');
    expect(followUp.doctorId, 'doctor-a');
    expect(followUp.clinicId, 'clinic-a');
    expect(followUp.caseId, 'case-a');
  });

  test('older follow-ups remain readable without optional extension fields', () {
    final followUp = ClinicalFollowUp.fromMap('legacy-follow-up', {
      'caseId': 'case-a',
      'patientId': 'patient-a',
      'organizationId': 'org-a',
      'doctorId': 'doctor-a',
      'clinicId': 'clinic-a',
      'visitAt': Timestamp.fromDate(DateTime.utc(2026, 10, 20)),
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, 20)),
    });

    expect(followUp.caseData, isEmpty);
    expect(followUp.nextAppointmentAt, isNull);
  });
}
