part of 'patient_profile_screens.dart';

class EditPatientProfileScreen extends StatefulWidget {
  const EditPatientProfileScreen({super.key, required this.patient});
  final PatientProfile patient;

  @override
  State<EditPatientProfileScreen> createState() => _EditPatientProfileScreenState();
}
