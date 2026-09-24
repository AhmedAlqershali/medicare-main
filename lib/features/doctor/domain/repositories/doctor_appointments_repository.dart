import '../../models/doctor_appointment.dart';

abstract class DoctorAppointmentsRepository {
  Future<List<DoctorAppointment>> getDoctorAppointments();
}
