class PatientProfileEntity {
  const PatientProfileEntity({
    required this.name,
    required this.phone,
    required this.email,
    required this.birthDate,
    required this.gender,
  });

  final String name;
  final String phone;
  final String email;
  final String birthDate;
  final String gender;

  bool get isValid => name.trim().isNotEmpty && email.contains('@');
}
