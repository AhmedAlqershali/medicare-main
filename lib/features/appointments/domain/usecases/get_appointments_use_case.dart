import '../entities/appointment_entity.dart';
import '../repositories/appointments_repository.dart';

class GetAppointmentsUseCase {
  const GetAppointmentsUseCase(this.repository);

  final AppointmentsRepository repository;

  Future<List<AppointmentEntity>> call() => repository.getAppointments();
}
