part of 'clinic_model.dart';

class ClinicDoctorData {
  const ClinicDoctorData({required this.id, required this.initials, required this.name, required this.specialty, required this.rating, required this.reviews, required this.experience, required this.bio, required this.services, required this.color});
  final String id;
  final String initials;
  final String name;
  final String specialty;
  final String rating;
  final String reviews;
  final String experience;
  final String bio;
  final List<String> services;
  final Color color;
}
