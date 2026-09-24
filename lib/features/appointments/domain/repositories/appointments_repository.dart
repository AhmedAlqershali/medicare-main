import '../entities/appointment_entity.dart';

abstract class AppointmentsRepository {
  Future<List<AppointmentEntity>> getAppointments();
}
