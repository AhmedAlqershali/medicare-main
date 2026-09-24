import '../entities/clinic_entity.dart';
import '../repositories/clinics_repository.dart';

class GetClinicsUseCase {
  const GetClinicsUseCase(this.repository);

  final ClinicsRepository repository;

  Future<List<ClinicEntity>> call() => repository.getClinics();
}
