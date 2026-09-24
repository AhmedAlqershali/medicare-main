part of 'doctor_appointments_screen.dart';

class DoctorAppointmentDetailsScreen extends StatefulWidget {
  const DoctorAppointmentDetailsScreen({super.key, required this.appointment});
  final DoctorAppointment appointment;

  @override
  State<DoctorAppointmentDetailsScreen> createState() => _DoctorAppointmentDetailsScreenState();
}
