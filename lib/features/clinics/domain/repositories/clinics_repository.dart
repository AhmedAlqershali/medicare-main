import '../entities/clinic_entity.dart';

abstract class ClinicsRepository {
  Future<List<ClinicEntity>> getClinics();
}
