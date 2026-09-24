import 'package:flutter/material.dart';

class ClinicEntity {
  const ClinicEntity({
    required this.name,
    required this.category,
    required this.location,
    required this.description,
    required this.hours,
    required this.specialties,
    required this.status,
    required this.icon,
    required this.colorValue,
    required this.doctors,
  });

  final String name;
  final String category;
  final String location;
  final String description;
  final String hours;
  final List<String> specialties;
  final String status;
  final IconData icon;
  final int colorValue;
  final List<ClinicDoctorEntity> doctors;
}

class ClinicDoctorEntity {
  const ClinicDoctorEntity({
    required this.id,
    required this.initials,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviews,
    required this.experience,
    required this.bio,
    required this.services,
    required this.colorValue,
  });

  final String id;
  final String initials;
  final String name;
  final String specialty;
  final String rating;
  final String reviews;
  final String experience;
  final String bio;
  final List<String> services;
  final int colorValue;
}
