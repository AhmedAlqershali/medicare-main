import '../../models/organization_doctor.dart';
import '../repositories/organization_doctors_repository.dart';

class GetOrganizationDoctorsUseCase {
  const GetOrganizationDoctorsUseCase(this.repository);

  final OrganizationDoctorsRepository repository;

  Future<List<OrganizationDoctor>> call() => repository.getOrganizationDoctors();
}
