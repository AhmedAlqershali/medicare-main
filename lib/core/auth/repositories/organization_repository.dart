import '../models/organization.dart';

abstract class OrganizationRepository {
  Future<Organization?> currentOrganization({String? organizationId});
  Future<List<Organization>> visibleOrganizations();
}
