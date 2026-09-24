import '../../models/doctor_appointment.dart';
import '../repositories/doctor_appointments_repository.dart';

class GetDoctorAppointmentsUseCase {
  const GetDoctorAppointmentsUseCase(this.repository);

  final DoctorAppointmentsRepository repository;

  Future<List<DoctorAppointment>> call() => repository.getDoctorAppointments();
}
