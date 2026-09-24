import '../models/patient.dart';

abstract class PatientRepository {
  Future<List<Patient>> patientsForDoctor(String doctorId, {String? organizationId});
  Future<Patient?> patientForId(String patientId, {String? organizationId});
  Future<Patient> createPatient({required String doctorId, required String name, required String email, required String invitedBy, String? organizationId});
}
