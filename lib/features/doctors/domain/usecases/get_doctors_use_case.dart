import '../entities/doctor_entity.dart';
import '../repositories/doctors_repository.dart';

class GetDoctorsUseCase {
  const GetDoctorsUseCase(this.repository);

  final DoctorsRepository repository;

  Future<List<DoctorEntity>> call() => repository.getDoctors();
}
