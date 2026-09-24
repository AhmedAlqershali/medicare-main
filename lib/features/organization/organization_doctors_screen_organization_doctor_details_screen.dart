part of 'organization_doctors_screen.dart';

class OrganizationDoctorDetailsScreen extends StatefulWidget {
  const OrganizationDoctorDetailsScreen({super.key, required this.doctor});
  final OrganizationDoctor doctor;

  @override
  State<OrganizationDoctorDetailsScreen> createState() => _OrganizationDoctorDetailsScreenState();
}
