part of 'appointments_screens.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  const AppointmentDetailsScreen({super.key, required this.appointment});
  final AppointmentData appointment;

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}
