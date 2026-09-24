enum AppointmentEntityStatus { upcoming, completed, cancelled }

class AppointmentEntity {
  const AppointmentEntity({
    required this.id,
    required this.doctorId,
    this.clinicId,
    required this.doctorName,
    required this.doctorInitials,
    required this.specialty,
    required this.clinicName,
    required this.location,
    required this.date,
    required this.time,
    required this.type,
    required this.status,
    required this.avatarColorValue,
    this.notes,
  });

  final String id;
  final String doctorId;
  final String? clinicId;
  final String doctorName;
  final String doctorInitials;
  final String specialty;
  final String clinicName;
  final String location;
  final String date;
  final String time;
  final String type;
  final AppointmentEntityStatus status;
  final int avatarColorValue;
  final String? notes;
}
