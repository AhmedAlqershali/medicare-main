import 'account_status.dart';

class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.email,
    required this.doctorId,
    required this.organizationId,
    required this.clinicId,
    required this.status,
    required this.accountActivated,
    required this.initials,
    this.firebaseUid,
    this.phone,
    this.birthDate,
    this.gender,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String doctorId;
  final String organizationId;
  final String? clinicId;
  final AccountStatus status;
  final bool accountActivated;
  final String initials;
  final String? firebaseUid;
  final String? phone;
  final String? birthDate;
  final String? gender;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'doctorId': doctorId,
      'organizationId': organizationId,
      'clinicId': clinicId,
      'status': status.name,
      'accountActivated': accountActivated,
      'initials': initials,
    };
    if (phone != null) map['phone'] = phone;
    if (birthDate != null) map['birthDate'] = birthDate;
    if (gender != null) map['gender'] = gender;
    map['firebaseUid'] = firebaseUid;
    if (createdAt != null) map['createdAt'] = createdAt!.toUtc().toIso8601String();
    if (updatedAt != null) map['updatedAt'] = updatedAt!.toUtc().toIso8601String();
    return map;
  }

  static Patient fromMap(Map<String, dynamic> map) => Patient(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        doctorId: map['doctorId'] as String? ?? '',
        organizationId: map['organizationId'] as String? ?? '',
        clinicId: map['clinicId'] as String?,
        status: AccountStatus.values.firstWhere(
          (item) => item.name == (map['status'] as String? ?? AccountStatus.active.name),
          orElse: () => AccountStatus.active,
        ),
        accountActivated: map['accountActivated'] as bool? ?? false,
        initials: map['initials'] as String? ?? '',
        phone: map['phone'] as String?,
        birthDate: map['birthDate'] as String?,
        gender: map['gender'] as String?,
        firebaseUid: map['firebaseUid'] as String?,
        createdAt: map['createdAt'] is String ? DateTime.tryParse(map['createdAt'] as String) : null,
        updatedAt: map['updatedAt'] is String ? DateTime.tryParse(map['updatedAt'] as String) : null,
      );
}
