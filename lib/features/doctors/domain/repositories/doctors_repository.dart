import '../entities/doctor_entity.dart';

abstract class DoctorsRepository {
  Future<List<DoctorEntity>> getDoctors();
}
