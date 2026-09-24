import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_status.dart';

class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.status,
    this.firebaseUid,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final AccountStatus status;
  final String? firebaseUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'status': status.name,
    };
    if (firebaseUid != null) map['firebaseUid'] = firebaseUid;
    if (createdAt != null) map['createdAt'] = createdAt!.toUtc().toIso8601String();
    if (updatedAt != null) map['updatedAt'] = updatedAt!.toUtc().toIso8601String();
    return map;
  }

  static Organization fromMap(Map<String, dynamic> map, String documentId) => Organization(
        id: documentId,
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        location: map['location'] as String? ?? '',
        status: _status(map['status']),
        firebaseUid: map['firebaseUid'] as String?,
        createdAt: _dateFromMap(map['createdAt']),
        updatedAt: _dateFromMap(map['updatedAt']),
      );

  static DateTime? _dateFromMap(Object? value) => switch (value) {
        String value => DateTime.tryParse(value),
        Timestamp value => value.toDate(),
        _ => null,
      };

  static AccountStatus _status(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    return switch (normalized) {
      'active' || 'نشط' => AccountStatus.active,
      'inactive' || 'غير متاح' => AccountStatus.inactive,
      'pending' || 'قيد الانتظار' => AccountStatus.pending,
      _ => AccountStatus.active,
    };
  }
}
