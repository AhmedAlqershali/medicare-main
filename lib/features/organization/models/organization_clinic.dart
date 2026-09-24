import 'package:flutter/material.dart';

class OrganizationClinic {
  const OrganizationClinic({required this.id, required this.name, required this.location, required this.phone, required this.description, required this.status, required this.doctorsCount, required this.departmentsCount, required this.patientsCount, required this.icon, required this.color, required this.departments});
  final String id;
  final String name;
  final String location;
  final String phone;
  final String description;
  final String status;
  final int doctorsCount;
  final int departmentsCount;
  final int patientsCount;
  final IconData icon;
  final Color color;
  final List<String> departments;

  OrganizationClinic copyWith({String? name, String? location, String? phone, String? description, String? status, int? doctorsCount, int? departmentsCount, int? patientsCount, IconData? icon, Color? color, List<String>? departments}) => OrganizationClinic(id: id, name: name ?? this.name, location: location ?? this.location, phone: phone ?? this.phone, description: description ?? this.description, status: status ?? this.status, doctorsCount: doctorsCount ?? this.doctorsCount, departmentsCount: departmentsCount ?? this.departmentsCount, patientsCount: patientsCount ?? this.patientsCount, icon: icon ?? this.icon, color: color ?? this.color, departments: departments ?? this.departments);
}
