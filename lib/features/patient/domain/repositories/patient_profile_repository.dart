import '../entities/patient_profile.dart';

abstract class PatientProfileRepository {
  Future<PatientProfileEntity> getPatientProfile();
  Future<void> updatePatientProfile(PatientProfileEntity profile);
}
