import '../../../../core/auth/models/account_role.dart';

class UserAccount {
  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.organizationId,
    this.clinicId,
    this.doctorId,
    this.patientId,
  });

  final String id;
  final String name;
  final String email;
  final AccountRole role;
  final String? organizationId;
  final String? clinicId;
  final String? doctorId;
  final String? patientId;

  bool get isAuthenticated => id.isNotEmpty;
}
