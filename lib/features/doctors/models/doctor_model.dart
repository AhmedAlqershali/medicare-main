import 'package:flutter/material.dart';

class DoctorData {
  const DoctorData({required this.id, required this.initials, required this.name, required this.specialty, required this.clinic, required this.location, required this.rating, required this.reviews, required this.experience, required this.bio, required this.services, required this.color, this.clinicId, this.availability = const {}});
  final String id;
  final String initials;
  final String name;
  final String specialty;
  final String clinic;
  final String location;
  final String rating;
  final String reviews;
  final String experience;
  final String bio;
  final List<String> services;
  final Color color;
  final String? clinicId;
  final Map<String, List<String>> availability;
}
