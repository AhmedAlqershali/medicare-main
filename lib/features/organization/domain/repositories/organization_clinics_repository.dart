import '../../models/organization_clinic.dart';

abstract class OrganizationClinicsRepository {
  Future<List<OrganizationClinic>> getOrganizationClinics({bool includeRelatedData = true});
}
