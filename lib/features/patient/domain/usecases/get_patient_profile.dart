import '../entities/patient_profile.dart';
import '../repositories/patient_profile_repository.dart';

class GetPatientProfileUseCase {
  const GetPatientProfileUseCase(this.repository);

  final PatientProfileRepository repository;

  Future<PatientProfileEntity> call() => repository.getPatientProfile();
}
