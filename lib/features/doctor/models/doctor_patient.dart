import 'package:flutter/material.dart';

class DoctorPatient {
  const DoctorPatient({required this.id, required this.organizationId, required this.doctorId, required this.clinicId, required this.firebaseUid, required this.name, required this.initials, required this.age, required this.gender, required this.birthDate, required this.email, required this.phone, required this.lastAppointment, required this.status, required this.avatarColor, required this.notes});
  final String id;
  final String organizationId;
  final String doctorId;
  final String? clinicId;
  final String? firebaseUid;
  final String name;
  final String initials;
  final String age;
  final String gender;
  final String birthDate;
  final String email;
  final String phone;
  final String lastAppointment;
  final String status;
  final Color avatarColor;
  final String notes;

  DoctorPatient copyWith({String? name, String? age, String? gender, String? birthDate, String? phone, String? lastAppointment}) => DoctorPatient(id: id, organizationId: organizationId, doctorId: doctorId, clinicId: clinicId, firebaseUid: firebaseUid, name: name ?? this.name, initials: initials, age: age ?? this.age, gender: gender ?? this.gender, birthDate: birthDate ?? this.birthDate, email: email, phone: phone ?? this.phone, lastAppointment: lastAppointment ?? this.lastAppointment, status: status, avatarColor: avatarColor, notes: notes);
}
