import '../models/doctor.dart';

abstract class DoctorRepository {
  Future<List<Doctor>> doctorsForOrganization(String organizationId);
  Future<Doctor?> doctorForId(String doctorId, {String? organizationId});
  Future<Doctor> inviteDoctor({required String organizationId, required String name, required String email, required String specialty, required String invitedBy, String? clinicId, String? clinicName});
}
