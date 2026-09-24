part of 'doctor_appointment.dart';

class DoctorAppointment {
  const DoctorAppointment({required this.id, required this.organizationId, required this.doctorId, required this.patientId, required this.clinicId, required this.patientName, required this.patientInitials, required this.age, required this.gender, required this.date, required this.time, required this.type, required this.status, required this.notes, required this.avatarColor});
  final String id;
  final String organizationId;
  final String doctorId;
  final String patientId;
  final String? clinicId;
  final String patientName;
  final String patientInitials;
  final String age;
  final String gender;
  final String date;
  final String time;
  final String type;
  final DoctorAppointmentFilter status;
  final String notes;
  final Color avatarColor;

  String get statusLabel => switch (status) { DoctorAppointmentFilter.today => 'اليوم', DoctorAppointmentFilter.upcoming => 'قادم', DoctorAppointmentFilter.completed => 'مكتمل', DoctorAppointmentFilter.cancelled => 'ملغي' };
  Color get statusColor => switch (status) { DoctorAppointmentFilter.today => AppColors.primary, DoctorAppointmentFilter.upcoming => AppColors.primary, DoctorAppointmentFilter.completed => AppColors.success, DoctorAppointmentFilter.cancelled => AppColors.muted };
  DoctorAppointment copyWith({DoctorAppointmentFilter? status, String? date, String? time}) => DoctorAppointment(id: id, organizationId: organizationId, doctorId: doctorId, patientId: patientId, clinicId: clinicId, patientName: patientName, patientInitials: patientInitials, age: age, gender: gender, date: date ?? this.date, time: time ?? this.time, type: type, status: status ?? this.status, notes: notes, avatarColor: avatarColor);
}
