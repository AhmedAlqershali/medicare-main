import '../../models/organization_clinic.dart';
import '../repositories/organization_clinics_repository.dart';

class GetOrganizationClinicsUseCase {
  const GetOrganizationClinicsUseCase(this.repository);

  final OrganizationClinicsRepository repository;

  Future<List<OrganizationClinic>> call() => repository.getOrganizationClinics();
}
