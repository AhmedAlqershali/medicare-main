import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/core/auth/models/account_status.dart';
import 'package:medicare/core/auth/models/patient.dart';

void main() {
  test('patient notes round-trip through Firestore map', () {
    const note = 'أبحاث متطلبات الفحوصات.';
    final patient = Patient(
      id: 'patient-1',
      name: 'سارة أحمد',
      email: 'sara@example.com',
      doctorId: 'doctor-1',
      organizationId: 'organization-1',
      clinicId: 'clinic-1',
      status: AccountStatus.active,
      accountActivated: true,
      initials: 'SA',
      notes: note,
    );

    final decoded = Patient.fromMap(patient.toMap());

    expect(decoded.notes, note);
    expect(decoded.toMap()['notes'], note);
  });

  test('patient reads Firestore timestamps and legacy ISO dates', () {
    final createdAt = DateTime.utc(2026, 10, 24, 9);
    final updatedAt = DateTime.utc(2026, 10, 24, 10);
    final patient = Patient(
      id: 'patient-1',
      name: 'سارة أحمد',
      email: 'sara@example.com',
      doctorId: 'doctor-1',
      organizationId: 'organization-1',
      clinicId: 'clinic-1',
      status: AccountStatus.active,
      accountActivated: true,
      initials: 'SA',
    );
    final data = patient.toMap()
      ..['createdAt'] = Timestamp.fromDate(createdAt)
      ..['updatedAt'] = updatedAt.toIso8601String();

    final decoded = Patient.fromMap(data);

    expect(decoded.createdAt, createdAt);
    expect(decoded.updatedAt, updatedAt);
  });
}
