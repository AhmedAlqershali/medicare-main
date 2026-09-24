import 'package:flutter/material.dart';

class OrganizationDoctor {
  const OrganizationDoctor({required this.id, required this.name, required this.initials, required this.specialty, required this.clinic, this.clinicId, required this.phone, required this.email, required this.status, required this.avatarColor, required this.scheduleSummary, this.availability = const {}});
  final String id;
  final String name;
  final String initials;
  final String specialty;
  final String clinic;
  final String? clinicId;
  final String phone;
  final String email;
  final String status;
  final Color avatarColor;
  final String scheduleSummary;
  final Map<String, List<String>> availability;

  OrganizationDoctor copyWith({String? name, String? initials, String? specialty, String? clinic, String? clinicId, String? phone, String? email, String? status, Color? avatarColor, String? scheduleSummary, Map<String, List<String>>? availability}) => OrganizationDoctor(id: id, name: name ?? this.name, initials: initials ?? this.initials, specialty: specialty ?? this.specialty, clinic: clinic ?? this.clinic, clinicId: clinicId ?? this.clinicId, phone: phone ?? this.phone, email: email ?? this.email, status: status ?? this.status, avatarColor: avatarColor ?? this.avatarColor, scheduleSummary: scheduleSummary ?? this.scheduleSummary, availability: availability ?? this.availability);
}
