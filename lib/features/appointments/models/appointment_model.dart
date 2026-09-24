import 'package:flutter/material.dart';

import 'appointment_status.dart';

class AppointmentData {
  const AppointmentData({required this.id, required this.doctorId, required this.doctorName, required this.doctorInitials, required this.specialty, required this.clinicName, required this.location, required this.date, required this.time, required this.type, required this.status, required this.avatarColor, this.clinicId, this.notes});

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
  final AppointmentStatus status;
  final Color avatarColor;
  final String? notes;

  AppointmentData copyWith({AppointmentStatus? status}) => AppointmentData(id: id, doctorId: doctorId, doctorName: doctorName, doctorInitials: doctorInitials, specialty: specialty, clinicName: clinicName, location: location, date: date, time: time, type: type, status: status ?? this.status, avatarColor: avatarColor, clinicId: clinicId, notes: notes);
}
