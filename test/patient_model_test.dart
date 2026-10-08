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
}
