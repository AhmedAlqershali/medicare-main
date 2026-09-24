import 'package:flutter/material.dart';

part 'clinic_model_clinic_doctor_data.dart';

class ClinicData {
  const ClinicData({
    required this.name,
    required this.category,
    required this.location,
    required this.description,
    required this.hours,
    required this.specialties,
    required this.doctors,
    required this.status,
    required this.icon,
    required this.color,
    this.id = '',
    this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String category;
  final String location;
  final String description;
  final String hours;
  final List<String> specialties;
  final List<ClinicDoctorData> doctors;
  final String status;
  final IconData icon;
  final Color color;
  final String? organizationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'location': location,
        'description': description,
        'hours': hours,
        'specialties': specialties,
        'status': status,
        'organizationId': organizationId,
        'createdAt': createdAt?.toUtc().toIso8601String(),
        'updatedAt': updatedAt?.toUtc().toIso8601String(),
      };

  static ClinicData fromMap(Map<String, dynamic> map) => ClinicData(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        category: map['category'] as String? ?? '',
        location: map['location'] as String? ?? '',
        description: map['description'] as String? ?? '',
        hours: map['hours'] as String? ?? '',
        specialties: (map['specialties'] as List<dynamic>? ?? const <dynamic>[]).map((item) => item.toString()).toList(),
        doctors: const [],
        status: map['status'] as String? ?? 'open',
        icon: Icons.local_hospital_outlined,
        color: const Color(0xFF4AB3A9),
        organizationId: map['organizationId'] as String?,
        createdAt: map['createdAt'] is String ? DateTime.tryParse(map['createdAt'] as String) : null,
        updatedAt: map['updatedAt'] is String ? DateTime.tryParse(map['updatedAt'] as String) : null,
      );
}
