import '../../models/organization_doctor.dart';

abstract class OrganizationDoctorsRepository {
  Future<List<OrganizationDoctor>> getOrganizationDoctors();
}
